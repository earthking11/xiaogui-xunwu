import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mimo_results.dart';
import 'mimo_prompts.dart';

class MimoApiException implements Exception {
  MimoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MimoApiClient {
  MimoApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static final Uri _endpoint = Uri.parse(
    'https://api.xiaomimimo.com/v1/chat/completions',
  );

  final http.Client _httpClient;

  static String cleanApiKey(String apiKey) {
    final cleaned = apiKey.trim();
    if (cleaned.isEmpty) {
      throw MimoApiException('请先填写 MiMo API Key');
    }
    final validBearerToken = RegExp(r'^[A-Za-z0-9._~+/=-]+$');
    if (!validBearerToken.hasMatch(cleaned)) {
      throw MimoApiException(
        'API Key 格式不对，请粘贴 MiMo 控制台里的完整 Key，不要填写说明文字、中文或空格',
      );
    }
    return cleaned;
  }

  Future<RecognitionResult> recognizePhoto({
    required String apiKey,
    required List<int> jpegBytes,
    required DateTime capturedAt,
    required double? gpsLatitude,
    required double? gpsLongitude,
    required double? gpsAccuracy,
    required String? userLocationNote,
  }) async {
    final prompt = recognitionPrompt(
      capturedAt: capturedAt,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      gpsAccuracy: gpsAccuracy,
      userLocationNote: userLocationNote,
    );
    final responseJson = await _post(
      apiKey: apiKey,
      body: {
        'model': 'mimo-v2.5',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,${base64Encode(jpegBytes)}',
                },
              },
            ],
          },
        ],
        'response_format': {'type': 'json_object'},
        'thinking': {'type': 'disabled'},
      },
    );
    return RecognitionResult.fromJson(_contentAsJson(responseJson));
  }

  Future<SearchResult> searchRecords({
    required String apiKey,
    required String question,
    required List<String> recordSummaries,
  }) async {
    final responseJson = await _post(
      apiKey: apiKey,
      body: {
        'model': 'mimo-v2.5',
        'messages': [
          {
            'role': 'user',
            'content': searchPrompt(
              question: question,
              recordSummaries: recordSummaries,
            ),
          },
        ],
        'response_format': {'type': 'json_object'},
        'thinking': {'type': 'disabled'},
      },
    );
    return SearchResult.fromJson(_contentAsJson(responseJson));
  }

  Future<void> testConnection({
    required String apiKey,
    required List<int> imageBytes,
  }) async {
    final responseJson = await _post(
      apiKey: apiKey,
      body: {
        'model': 'mimo-v2.5',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '这是一张连通性测试图片。请只返回 JSON：{"ok":true,"objects":["测试图片"]}',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/png;base64,${base64Encode(imageBytes)}',
                },
              },
            ],
          },
        ],
        'response_format': {'type': 'json_object'},
        'thinking': {'type': 'disabled'},
      },
    );
    final content = _contentAsJson(responseJson);
    if (content['ok'] != true) {
      throw MimoApiException('连通性测试响应异常：$content');
    }
  }

  Future<Map<String, Object?>> _post({
    required String apiKey,
    required Map<String, Object?> body,
  }) async {
    final cleanedApiKey = cleanApiKey(apiKey);
    final http.Response response;
    try {
      response = await _httpClient.post(
        _endpoint,
        headers: {
          'Authorization': 'Bearer $cleanedApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    } on FormatException {
      throw MimoApiException('API Key 格式不对，请重新粘贴 MiMo 控制台里的完整 Key');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MimoApiException(_messageForStatusCode(response.statusCode));
    }
    return jsonDecode(response.body) as Map<String, Object?>;
  }

  String _messageForStatusCode(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return 'MiMo API Key 无效或已过期，请在设置页重新填写';
    }
    if (statusCode == 429) {
      return 'MiMo 请求太频繁了，请稍后再试';
    }
    if (statusCode >= 500) {
      return 'MiMo 服务暂时异常，请稍后重试';
    }
    return 'MiMo 请求失败，状态码 $statusCode';
  }

  Map<String, Object?> _contentAsJson(Map<String, Object?> responseJson) {
    final choices = responseJson['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw MimoApiException('响应中没有 choices');
    }
    final firstChoice = choices.first as Map;
    final message = firstChoice['message'] as Map?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw MimoApiException('响应中没有 message.content');
    }
    return jsonDecode(content) as Map<String, Object?>;
  }
}
