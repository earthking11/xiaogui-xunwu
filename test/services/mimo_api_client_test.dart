import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:xiaogui_xunwu/models/mimo_results.dart';
import 'package:xiaogui_xunwu/services/mimo_api_client.dart';

class CapturingClient extends http.BaseClient {
  CapturingClient(this.responseContent);

  final String responseContent;
  http.BaseRequest? lastRequest;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    if (request is http.Request) {
      lastBody = request.body;
    }
    final body = jsonEncode({
      'choices': [
        {
          'message': {'content': responseContent},
        },
      ],
    });
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test(
    'recognizePhoto sends mimo-v2.5 image request and parses JSON',
    () async {
      final client = CapturingClient(
        jsonEncode({
          'mainObjects': ['医保卡'],
          'aliases': ['社保卡'],
          'sceneDescription': '桌面上有一张卡。',
          'locationGuess': '可能在透明盒子旁。',
          'searchSummary': '医保卡 社保卡 透明盒子',
          'confidence': 0.91,
          'needsUserNote': false,
        }),
      );
      final api = MimoApiClient(httpClient: client);

      final result = await api.recognizePhoto(
        apiKey: 'test-key',
        jpegBytes: utf8.encode('fake-image'),
        capturedAt: DateTime.parse('2026-06-18T10:20:30.000Z'),
        gpsLatitude: 26.0,
        gpsLongitude: 119.0,
        gpsAccuracy: 10,
        userLocationNote: '卧室抽屉',
      );

      expect(result, isA<RecognitionResult>());
      expect(result.mainObjects, ['医保卡']);
      expect(
        client.lastRequest!.url.toString(),
        'https://api.xiaomimimo.com/v1/chat/completions',
      );
      expect(client.lastRequest!.headers['Authorization'], 'Bearer test-key');
      expect(client.lastBody, contains('"model":"mimo-v2.5"'));
      expect(client.lastBody, contains('data:image/jpeg;base64,'));
    },
  );

  test('searchRecords parses model search result', () async {
    final client = CapturingClient(
      jsonEncode({
        'answer': '可能在书桌右上角。',
        'matches': [
          {
            'recordId': 'record-1',
            'confidence': 0.88,
            'reason': '问题提到黑色转接头，记录中有同名物品。',
          },
        ],
        'notFound': false,
      }),
    );
    final api = MimoApiClient(httpClient: client);

    final result = await api.searchRecords(
      apiKey: 'test-key',
      question: '黑色转接头在哪',
      recordSummaries: const ['recordId: record-1\n主要物品: 黑色 Type-C 转接头'],
    );

    expect(result.answer, '可能在书桌右上角。');
    expect(result.matches.single.recordId, 'record-1');
    expect(result.matches.single.confidence, 0.88);
    expect(result.notFound, isFalse);
    expect(client.lastBody, contains('黑色转接头在哪'));
  });
}
