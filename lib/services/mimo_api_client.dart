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

  Future<void> testConnection({required String apiKey}) async {
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
                  'url':
                      'data:image/jpeg;base64,${base64Encode(_testJpegBytes)}',
                },
              },
            ],
          },
        ],
        'response_format': {'type': 'json_object'},
      },
    );
    final content = _contentAsJson(responseJson);
    if (content['ok'] != true) {
      throw MimoApiException('连通性测试响应异常：$content');
    }
  }

  static const List<int> _testJpegBytes = [
    255,
    216,
    255,
    224,
    0,
    16,
    74,
    70,
    73,
    70,
    0,
    1,
    1,
    1,
    0,
    72,
    0,
    72,
    0,
    0,
    255,
    219,
    0,
    67,
    0,
    8,
    6,
    6,
    7,
    6,
    5,
    8,
    7,
    7,
    7,
    9,
    9,
    8,
    10,
    12,
    20,
    13,
    12,
    11,
    11,
    12,
    25,
    18,
    19,
    15,
    20,
    29,
    26,
    31,
    30,
    29,
    26,
    28,
    28,
    32,
    36,
    46,
    39,
    32,
    34,
    44,
    35,
    28,
    28,
    40,
    55,
    41,
    44,
    48,
    49,
    52,
    52,
    52,
    31,
    39,
    57,
    61,
    56,
    50,
    60,
    46,
    51,
    52,
    50,
    255,
    192,
    0,
    17,
    8,
    0,
    1,
    0,
    1,
    3,
    1,
    34,
    0,
    2,
    17,
    1,
    3,
    17,
    1,
    255,
    196,
    0,
    31,
    0,
    0,
    1,
    5,
    1,
    1,
    1,
    1,
    1,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    255,
    196,
    0,
    181,
    16,
    0,
    2,
    1,
    3,
    3,
    2,
    4,
    3,
    5,
    5,
    4,
    4,
    0,
    0,
    1,
    125,
    1,
    2,
    3,
    0,
    4,
    17,
    5,
    18,
    33,
    49,
    65,
    6,
    19,
    81,
    97,
    7,
    34,
    113,
    20,
    50,
    129,
    145,
    161,
    8,
    35,
    66,
    177,
    193,
    21,
    82,
    209,
    240,
    36,
    51,
    98,
    114,
    130,
    9,
    10,
    22,
    23,
    24,
    25,
    26,
    37,
    38,
    39,
    40,
    41,
    42,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    67,
    68,
    69,
    70,
    71,
    72,
    73,
    74,
    83,
    84,
    85,
    86,
    87,
    88,
    89,
    90,
    99,
    100,
    101,
    102,
    103,
    104,
    105,
    106,
    115,
    116,
    117,
    118,
    119,
    120,
    121,
    122,
    131,
    132,
    133,
    134,
    135,
    136,
    137,
    138,
    146,
    147,
    148,
    149,
    150,
    151,
    152,
    153,
    154,
    162,
    163,
    164,
    165,
    166,
    167,
    168,
    169,
    170,
    178,
    179,
    180,
    181,
    182,
    183,
    184,
    185,
    186,
    194,
    195,
    196,
    197,
    198,
    199,
    200,
    201,
    202,
    210,
    211,
    212,
    213,
    214,
    215,
    216,
    217,
    218,
    225,
    226,
    227,
    228,
    229,
    230,
    231,
    232,
    233,
    234,
    241,
    242,
    243,
    244,
    245,
    246,
    247,
    248,
    249,
    250,
    255,
    218,
    0,
    12,
    3,
    1,
    0,
    2,
    17,
    3,
    17,
    0,
    63,
    0,
    242,
    138,
    40,
    160,
    15,
    255,
    217,
  ];

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
