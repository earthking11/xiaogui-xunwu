import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/core/record_status.dart';
import 'package:xiaogui_xunwu/features/home/capture_controller.dart';
import 'package:xiaogui_xunwu/models/memory_record.dart';
import 'package:xiaogui_xunwu/services/api_key_store.dart';
import 'package:xiaogui_xunwu/services/memory_repository.dart';
import 'package:xiaogui_xunwu/services/mimo_api_client.dart';
import 'package:xiaogui_xunwu/services/photo_storage_service.dart';
import 'package:xiaogui_xunwu/services/recognition_service.dart';

void main() {
  test('saveCapture creates pending record and starts recognition', () async {
    final repository = FakeCaptureRepository();
    final photoStorage = FakePhotoStorageService();
    final recognition = FakeRecognitionService();
    final controller = CaptureController(
      repository: repository,
      photoStorageService: photoStorage,
      recognitionService: recognition,
      locationReader: () async => null,
      now: () => DateTime.parse('2026-06-18T10:20:30.000Z'),
      idGenerator: () => 'record-1',
    );

    final record = await controller.saveCapture(
      jpegBytes: [1, 2, 3],
      userLocationNote: '卧室抽屉',
    );

    expect(record.recordId, 'record-1');
    expect(record.status, RecordStatus.pending);
    expect(record.photoPath, '/fake/record-1.jpg');
    expect(record.thumbnailPath, '/fake/record-1-thumb.jpg');
    expect(record.userLocationNote, '卧室抽屉');
    expect(
      (await repository.getById('record-1'))!.status,
      RecordStatus.pending,
    );
    expect(recognition.recognizedIds, ['record-1']);
  });
}

class FakeCaptureRepository implements MemoryRepository {
  final Map<String, MemoryRecord> records = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> upsert(MemoryRecord record) async {
    records[record.recordId] = record;
  }

  @override
  Future<MemoryRecord?> getById(String recordId) async => records[recordId];

  @override
  Future<List<MemoryRecord>> watchAllOnce() async => records.values.toList();

  @override
  Future<List<MemoryRecord>> recognizedRecords() async => const [];

  @override
  Future<List<MemoryRecord>> recordsNeedingRecognition() async => const [];

  @override
  Future<void> delete(String recordId) async {
    records.remove(recordId);
  }
}

class FakePhotoStorageService extends PhotoStorageService {
  FakePhotoStorageService() : super(rootDirectory: Directory.systemTemp);

  @override
  Future<StoredPhoto> saveJpegBytes({
    required String recordId,
    required List<int> jpegBytes,
  }) async {
    return StoredPhoto(
      photoPath: '/fake/$recordId.jpg',
      thumbnailPath: '/fake/$recordId-thumb.jpg',
    );
  }
}

class FakeRecognitionService extends RecognitionService {
  FakeRecognitionService()
    : super(
        repository: FakeCaptureRepository(),
        apiKeyStore: InMemoryApiKeyStore(),
        mimoApiClient: MimoApiClient(),
      );

  final List<String> recognizedIds = [];

  @override
  Future<void> recognize(String recordId) async {
    recognizedIds.add(recordId);
  }
}
