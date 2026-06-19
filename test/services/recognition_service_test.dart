import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/core/record_status.dart';
import 'package:xiaogui_xunwu/models/memory_record.dart';
import 'package:xiaogui_xunwu/models/mimo_results.dart';
import 'package:xiaogui_xunwu/services/api_key_store.dart';
import 'package:xiaogui_xunwu/services/memory_repository.dart';
import 'package:xiaogui_xunwu/services/mimo_api_client.dart';
import 'package:xiaogui_xunwu/services/recognition_service.dart';

void main() {
  MemoryRecord record(String id, RecordStatus status, {String? errorMessage}) {
    final now = DateTime.parse('2026-06-18T10:20:30.000Z');
    return MemoryRecord(
      recordId: id,
      photoPath: '/photo/$id.jpg',
      thumbnailPath: '/photo/$id-thumb.jpg',
      capturedAt: now,
      gpsLatitude: 26.0,
      gpsLongitude: 119.0,
      gpsAccuracy: 10,
      userLocationNote: '卧室抽屉',
      aiMainObjects: const [],
      aiAliases: const [],
      aiSceneDescription: null,
      aiLocationGuess: null,
      aiSearchSummary: null,
      aiConfidence: null,
      status: status,
      errorMessage: errorMessage,
      createdAt: now,
      updatedAt: now,
    );
  }

  RecognitionService service({
    required FakeMemoryRepository repository,
    required InMemoryApiKeyStore keyStore,
    required FakeMimoApiClient client,
  }) {
    return RecognitionService(
      repository: repository,
      apiKeyStore: keyStore,
      mimoApiClient: client,
      photoBytesReader: (_) async => [1, 2, 3],
      now: () => DateTime.parse('2026-06-18T11:00:00.000Z'),
    );
  }

  test('recognizes pending record and stores AI fields', () async {
    final repository = FakeMemoryRepository()
      ..seed(record('card', RecordStatus.pending, errorMessage: '旧错误'));
    final keyStore = InMemoryApiKeyStore();
    await keyStore.saveApiKey('test-key');
    final recognitionService = service(
      repository: repository,
      keyStore: keyStore,
      client: FakeMimoApiClient.success(),
    );

    await recognitionService.recognize('card');

    final updated = (await repository.getById('card'))!;
    expect(updated.status, RecordStatus.recognized);
    expect(updated.aiMainObjects, ['医保卡']);
    expect(updated.aiAliases, ['社保卡']);
    expect(updated.aiLocationGuess, '可能在透明盒子旁。');
    expect(updated.errorMessage, isNull);
  });

  test('leaves record pending when api key is missing', () async {
    final repository = FakeMemoryRepository()
      ..seed(record('card', RecordStatus.pending));
    final recognitionService = service(
      repository: repository,
      keyStore: InMemoryApiKeyStore(),
      client: FakeMimoApiClient.success(),
    );

    await recognitionService.recognize('card');

    final updated = (await repository.getById('card'))!;
    expect(updated.status, RecordStatus.pending);
    expect(updated.errorMessage, '请先填写 MiMo API Key');
  });

  test('marks record failed when model call throws', () async {
    final repository = FakeMemoryRepository()
      ..seed(record('card', RecordStatus.pending));
    final keyStore = InMemoryApiKeyStore();
    await keyStore.saveApiKey('test-key');
    final recognitionService = service(
      repository: repository,
      keyStore: keyStore,
      client: FakeMimoApiClient.failure(),
    );

    await recognitionService.recognize('card');

    final updated = (await repository.getById('card'))!;
    expect(updated.status, RecordStatus.failed);
    expect(updated.errorMessage, contains('model failed'));
  });

  test('processBacklog processes pending and failed records', () async {
    final repository = FakeMemoryRepository()
      ..seed(record('pending', RecordStatus.pending))
      ..seed(record('failed', RecordStatus.failed))
      ..seed(record('stale', RecordStatus.recognizing))
      ..seed(record('done', RecordStatus.recognized));
    final keyStore = InMemoryApiKeyStore();
    await keyStore.saveApiKey('test-key');
    final client = FakeMimoApiClient.success();
    final recognitionService = service(
      repository: repository,
      keyStore: keyStore,
      client: client,
    );

    await recognitionService.processBacklog();

    expect(
      (await repository.getById('pending'))!.status,
      RecordStatus.recognized,
    );
    expect(
      (await repository.getById('failed'))!.status,
      RecordStatus.recognized,
    );
    expect(
      (await repository.getById('stale'))!.status,
      RecordStatus.recognized,
    );
    expect((await repository.getById('done'))!.status, RecordStatus.recognized);
    expect(client.calls, 3);
  });

  test(
    'recognize ignores duplicate in-flight request for same record',
    () async {
      final repository = FakeMemoryRepository()
        ..seed(record('card', RecordStatus.pending));
      final keyStore = InMemoryApiKeyStore();
      await keyStore.saveApiKey('test-key');
      final client = FakeMimoApiClient.success()
        ..waitBeforeResponse = Completer<void>();
      final recognitionService = service(
        repository: repository,
        keyStore: keyStore,
        client: client,
      );

      final first = recognitionService.recognize('card');
      await Future<void>.delayed(Duration.zero);
      final second = recognitionService.recognize('card');

      client.waitBeforeResponse!.complete();
      await Future.wait([first, second]);

      expect(client.calls, 1);
    },
  );
}

class FakeMemoryRepository implements MemoryRepository {
  final Map<String, MemoryRecord> _records = {};

  void seed(MemoryRecord record) {
    _records[record.recordId] = record;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> upsert(MemoryRecord record) async {
    _records[record.recordId] = record;
  }

  @override
  Future<MemoryRecord?> getById(String recordId) async {
    return _records[recordId];
  }

  @override
  Future<List<MemoryRecord>> watchAllOnce() async {
    return _records.values.toList();
  }

  @override
  Future<List<MemoryRecord>> recognizedRecords() async {
    return _records.values
        .where((record) => record.status == RecordStatus.recognized)
        .toList();
  }

  @override
  Future<List<MemoryRecord>> recordsNeedingRecognition() async {
    return _records.values
        .where(
          (record) =>
              record.status == RecordStatus.pending ||
              record.status == RecordStatus.failed ||
              record.status == RecordStatus.recognizing,
        )
        .toList();
  }

  @override
  Future<void> delete(String recordId) async {
    _records.remove(recordId);
  }
}

class FakeMimoApiClient extends MimoApiClient {
  FakeMimoApiClient.success() : shouldThrow = false, super();

  FakeMimoApiClient.failure() : shouldThrow = true, super();

  final bool shouldThrow;
  int calls = 0;
  Completer<void>? waitBeforeResponse;

  @override
  Future<RecognitionResult> recognizePhoto({
    required String apiKey,
    required List<int> jpegBytes,
    required DateTime capturedAt,
    required double? gpsLatitude,
    required double? gpsLongitude,
    required double? gpsAccuracy,
    required String? userLocationNote,
  }) async {
    calls += 1;
    await waitBeforeResponse?.future;
    if (shouldThrow) {
      throw MimoApiException('model failed');
    }
    return const RecognitionResult(
      mainObjects: ['医保卡'],
      aliases: ['社保卡'],
      sceneDescription: '桌面上有一张卡。',
      locationGuess: '可能在透明盒子旁。',
      searchSummary: '医保卡 社保卡 透明盒子',
      confidence: 0.91,
      needsUserNote: false,
    );
  }
}
