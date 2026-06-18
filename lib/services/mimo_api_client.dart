import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mimo_results.dart';
import 'mimo_prompts.dart';

class MimoApiException implements Exception {
  MimoApiException(this.message);

  final String message;

  @override
  String toString() => 'MimoApiException: $message';
}

class MimoApiClient {
  MimoApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static final Uri _endpoint = Uri.parse(
    'https://api.xiaomimimo.com/v1/chat/completions',
  );

  final http.Client _httpClient;

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
      },
    );
    return SearchResult.fromJson(_contentAsJson(responseJson));
  }

  Future<Map<String, Object?>> _post({
    required String apiKey,
    required Map<String, Object?> body,
  }) async {
    final response = await _httpClient.post(
      _endpoint,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MimoApiException('HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, Object?>;
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
