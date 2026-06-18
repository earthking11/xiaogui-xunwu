import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/core/record_status.dart';
import 'package:xiaogui_xunwu/models/memory_record.dart';

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
}
