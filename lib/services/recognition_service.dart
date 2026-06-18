import 'dart:async';
import 'dart:io';

import '../core/record_status.dart';
import 'api_key_store.dart';
import 'memory_repository.dart';
import 'mimo_api_client.dart';

typedef PhotoBytesReader = Future<List<int>> Function(String photoPath);

class RecognitionService {
  RecognitionService({
    required MemoryRepository repository,
    required ApiKeyStore apiKeyStore,
    required MimoApiClient mimoApiClient,
    PhotoBytesReader? photoBytesReader,
    DateTime Function()? now,
  }) : _repository = repository,
       _apiKeyStore = apiKeyStore,
       _mimoApiClient = mimoApiClient,
       _photoBytesReader =
           photoBytesReader ?? ((path) => File(path).readAsBytes()),
       _now = now ?? DateTime.now;

  final MemoryRepository _repository;
  final ApiKeyStore _apiKeyStore;
  final MimoApiClient _mimoApiClient;
  final PhotoBytesReader _photoBytesReader;
  final DateTime Function() _now;

  Future<void> processBacklog() async {
    final records = await _repository.recordsNeedingRecognition();
    for (final record in records) {
      await recognize(record.recordId);
    }
  }

  Future<void> recognize(String recordId) async {
    final record = await _repository.getById(recordId);
    if (record == null) return;

    final apiKey = await _apiKeyStore.readApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      await _repository.upsert(
        record.copyWith(
          status: RecordStatus.pending,
          errorMessage: '请先填写 MiMo API Key',
          updatedAt: _now(),
        ),
      );
      return;
    }

    await _repository.upsert(
      record.copyWith(
        status: RecordStatus.recognizing,
        clearErrorMessage: true,
        updatedAt: _now(),
      ),
    );

    try {
      final jpegBytes = await _photoBytesReader(record.photoPath);
      final result = await _mimoApiClient.recognizePhoto(
        apiKey: apiKey,
        jpegBytes: jpegBytes,
        capturedAt: record.capturedAt,
        gpsLatitude: record.gpsLatitude,
        gpsLongitude: record.gpsLongitude,
        gpsAccuracy: record.gpsAccuracy,
        userLocationNote: record.userLocationNote,
      );
      await _repository.upsert(
        record.copyWith(
          aiMainObjects: result.mainObjects,
          aiAliases: result.aliases,
          aiSceneDescription: result.sceneDescription,
          aiLocationGuess: result.locationGuess,
          aiSearchSummary: result.searchSummary,
          aiConfidence: result.confidence,
          status: RecordStatus.recognized,
          clearErrorMessage: true,
          updatedAt: _now(),
        ),
      );
    } catch (error) {
      await _repository.upsert(
        record.copyWith(
          status: RecordStatus.failed,
          errorMessage: error.toString(),
          updatedAt: _now(),
        ),
      );
    }
  }
}

void runRecognitionInBackground(Future<void> future) {
  unawaited(future);
}
