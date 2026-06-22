import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/core/record_status.dart';
import 'package:xiaogui_xunwu/models/memory_record.dart';
import 'package:xiaogui_xunwu/models/mimo_results.dart';

void main() {
  test('MemoryRecord round-trips through database map', () {
    final capturedAt = DateTime.parse('2026-06-18T10:20:30.000Z');
    final createdAt = DateTime.parse('2026-06-18T10:21:00.000Z');
    final updatedAt = DateTime.parse('2026-06-18T10:22:00.000Z');

    final record = MemoryRecord(
      recordId: 'record-1',
      photoPath: '/private/photo.jpg',
      thumbnailPath: '/private/thumb.jpg',
      capturedAt: capturedAt,
      gpsLatitude: 26.01,
      gpsLongitude: 119.30,
      gpsAccuracy: 18.5,
      readableLocation: '福建省福州市仓山区金山大道',
      userLocationNote: '卧室床头柜第二层',
      aiMainObjects: const ['医保卡', '透明盒子'],
      aiAliases: const ['社保卡'],
      aiSceneDescription: '桌面上有一个透明盒子。',
      aiLocationGuess: '可能在透明盒子旁边。',
      aiSearchSummary: '医保卡 社保卡 透明盒子 桌面',
      aiConfidence: 0.87,
      status: RecordStatus.recognized,
      errorMessage: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final decoded = MemoryRecord.fromMap(record.toMap());

    expect(decoded.recordId, 'record-1');
    expect(decoded.status, RecordStatus.recognized);
    expect(decoded.aiMainObjects, ['医保卡', '透明盒子']);
    expect(decoded.aiAliases, ['社保卡']);
    expect(decoded.capturedAt, capturedAt);
    expect(decoded.gpsAccuracy, 18.5);
    expect(decoded.readableLocation, '福建省福州市仓山区金山大道');
    expect(decoded.summaryForSearch(), contains('拍摄地点: 福建省福州市仓山区金山大道'));
  });

  test('RecordStatus parses stored values', () {
    expect(RecordStatusX.fromStorageValue('pending'), RecordStatus.pending);
    expect(
      RecordStatusX.fromStorageValue('recognizing'),
      RecordStatus.recognizing,
    );
    expect(
      RecordStatusX.fromStorageValue('recognized'),
      RecordStatus.recognized,
    );
    expect(RecordStatusX.fromStorageValue('failed'), RecordStatus.failed);
  });

  test('SearchResult parses match confidence', () {
    final result = SearchResult.fromJson({
      'answer': '可能在书桌右上角。',
      'matches': [
        {
          'recordId': 'record-1',
          'confidence': 0.86,
          'reason': '问题提到黑色转接头，记录中有同名物品。',
        },
      ],
      'notFound': false,
    });

    expect(result.matches.single.recordId, 'record-1');
    expect(result.matches.single.confidence, 0.86);
    expect(result.matches.single.reason, '问题提到黑色转接头，记录中有同名物品。');
    expect(result.notFound, isFalse);
  });
}
