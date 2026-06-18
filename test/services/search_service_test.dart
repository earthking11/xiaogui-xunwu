import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/core/record_status.dart';
import 'package:xiaogui_xunwu/models/memory_record.dart';
import 'package:xiaogui_xunwu/models/mimo_results.dart';
import 'package:xiaogui_xunwu/services/api_key_store.dart';
import 'package:xiaogui_xunwu/services/memory_repository.dart';
import 'package:xiaogui_xunwu/services/mimo_api_client.dart';
import 'package:xiaogui_xunwu/services/search_service.dart';

void main() {
  MemoryRecord record(String id, RecordStatus status) {
    final now = DateTime.parse('2026-06-18T10:20:30.000Z');
    return MemoryRecord(
      recordId: id,
      photoPath: '/photo/$id.jpg',
      thumbnailPath: '/photo/$id-thumb.jpg',
      capturedAt: now,
      gpsLatitude: null,
      gpsLongitude: null,
      gpsAccuracy: null,
      userLocationNote: '书桌右上角透明盒旁',
      aiMainObjects: const ['黑色 Type-C 转接头'],
      aiAliases: const ['小黑头'],
      aiSceneDescription: '书桌上有透明盒。',
      aiLocationGuess: '可能在书桌右上角透明盒旁。',
      aiSearchSummary: '黑色 Type-C 转接头 小黑头 透明盒',
      aiConfidence: 0.9,
      status: status,
      errorMessage: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('sends all recognized summaries to mimo search', () async {
    final repository = FakeSearchRepository()
      ..seed(record('record-1', RecordStatus.recognized))
      ..seed(record('pending', RecordStatus.pending));
    final keyStore = InMemoryApiKeyStore();
    await keyStore.saveApiKey('test-key');
    final client = FakeSearchMimoClient();
    final service = SearchService(
      repository: repository,
      apiKeyStore: keyStore,
      mimoApiClient: client,
    );

    final result = await service.search('黑色转接头在哪');

    expect(result.answer, '可能在书桌右上角透明盒旁。');
    expect(result.matches.single.record.recordId, 'record-1');
    expect(result.matches.single.confidence, 0.88);
    expect(client.lastQuestion, '黑色转接头在哪');
    expect(client.lastSummaries.length, 1);
    expect(client.lastSummaries.single, contains('record-1'));
  });

  test('returns empty result when there are no recognized records', () async {
    final keyStore = InMemoryApiKeyStore();
    await keyStore.saveApiKey('test-key');
    final service = SearchService(
      repository: FakeSearchRepository(),
      apiKeyStore: keyStore,
      mimoApiClient: FakeSearchMimoClient(),
    );

    final result = await service.search('医保卡在哪');

    expect(result.notFound, isTrue);
    expect(result.matches, isEmpty);
    expect(result.answer, '还没有可查找的记忆卡。先拍一张东西放在哪里吧。');
  });

  test('returns key-required result when api key is missing', () async {
    final service = SearchService(
      repository: FakeSearchRepository(),
      apiKeyStore: InMemoryApiKeyStore(),
      mimoApiClient: FakeSearchMimoClient(),
    );

    final result = await service.search('医保卡在哪');

    expect(result.notFound, isTrue);
    expect(result.matches, isEmpty);
    expect(result.answer, '请先填写 MiMo API Key，再查找物品。');
  });
}

class FakeSearchRepository implements MemoryRepository {
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
  Future<MemoryRecord?> getById(String recordId) async => _records[recordId];

  @override
  Future<List<MemoryRecord>> watchAllOnce() async => _records.values.toList();

  @override
  Future<List<MemoryRecord>> recognizedRecords() async {
    return _records.values
        .where((record) => record.status == RecordStatus.recognized)
        .toList();
  }

  @override
  Future<List<MemoryRecord>> recordsNeedingRecognition() async => const [];

  @override
  Future<void> delete(String recordId) async {
    _records.remove(recordId);
  }
}

class FakeSearchMimoClient extends MimoApiClient {
  String? lastQuestion;
  List<String> lastSummaries = const [];

  @override
  Future<SearchResult> searchRecords({
    required String apiKey,
    required String question,
    required List<String> recordSummaries,
  }) async {
    lastQuestion = question;
    lastSummaries = recordSummaries;
    return const SearchResult(
      answer: '可能在书桌右上角透明盒旁。',
      matches: [
        SearchMatch(
          recordId: 'record-1',
          confidence: 0.88,
          reason: '用户提到黑色转接头，这条记录的主要物品和摘要都匹配。',
        ),
      ],
      notFound: false,
    );
  }
}
