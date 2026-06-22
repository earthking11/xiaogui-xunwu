import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:xiaogui_xunwu/core/record_status.dart';
import 'package:xiaogui_xunwu/models/memory_record.dart';
import 'package:xiaogui_xunwu/services/memory_repository.dart';
import 'package:xiaogui_xunwu/services/readable_location_backfill_service.dart';
import 'package:xiaogui_xunwu/services/readable_location_service.dart';

void main() {
  test('fills a readable location for an existing GPS record', () async {
    final repository = _FakeRepository();
    repository.seed(_record());
    final service = ReadableLocationBackfillService(
      repository: repository,
      readableLocationService: ReadableLocationService(
        placemarkReader: (_, _) async => [
          Placemark(locality: '福州市', subLocality: '仓山区'),
        ],
      ),
    );

    await service.fillMissingLocations();

    expect((await repository.getById('record-1'))!.readableLocation, '福州市仓山区');
  });
}

MemoryRecord _record() {
  final now = DateTime.parse('2026-06-22T09:00:00.000Z');
  return MemoryRecord(
    recordId: 'record-1',
    photoPath: '/photo.jpg',
    thumbnailPath: '/thumbnail.jpg',
    capturedAt: now,
    gpsLatitude: 26.01,
    gpsLongitude: 119.3,
    gpsAccuracy: 12,
    userLocationNote: null,
    aiMainObjects: const ['钥匙'],
    aiAliases: const [],
    aiSceneDescription: null,
    aiLocationGuess: '桌面上',
    aiSearchSummary: '钥匙 桌面',
    aiConfidence: 0.9,
    status: RecordStatus.recognized,
    errorMessage: null,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeRepository implements MemoryRepository {
  final Map<String, MemoryRecord> _records = {};

  void seed(MemoryRecord record) {
    _records[record.recordId] = record;
  }

  @override
  Future<void> delete(String recordId) async {
    _records.remove(recordId);
  }

  @override
  Future<MemoryRecord?> getById(String recordId) async => _records[recordId];

  @override
  Future<void> initialize() async {}

  @override
  Future<List<MemoryRecord>> recognizedRecords() async =>
      _records.values.toList();

  @override
  Future<List<MemoryRecord>> recordsNeedingRecognition() async => const [];

  @override
  Future<void> upsert(MemoryRecord record) async {
    _records[record.recordId] = record;
  }

  @override
  Future<List<MemoryRecord>> watchAllOnce() async => _records.values.toList();
}
