import '../models/memory_record.dart';
import '../models/mimo_results.dart';
import 'api_key_store.dart';
import 'memory_repository.dart';
import 'mimo_api_client.dart';

class ResolvedSearchResult {
  const ResolvedSearchResult({
    required this.answer,
    required this.notFound,
    required this.matches,
  });

  final String answer;
  final bool notFound;
  final List<ResolvedSearchMatch> matches;
}

class ResolvedSearchMatch {
  const ResolvedSearchMatch({
    required this.record,
    required this.confidence,
    required this.reason,
  });

  final MemoryRecord record;
  final double confidence;
  final String reason;
}

class SearchService {
  SearchService({
    required MemoryRepository repository,
    required ApiKeyStore apiKeyStore,
    required MimoApiClient mimoApiClient,
  }) : _repository = repository,
       _apiKeyStore = apiKeyStore,
       _mimoApiClient = mimoApiClient;

  final MemoryRepository _repository;
  final ApiKeyStore _apiKeyStore;
  final MimoApiClient _mimoApiClient;

  Future<ResolvedSearchResult> search(String question) async {
    final apiKey = await _apiKeyStore.readApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return const ResolvedSearchResult(
        answer: '请先填写 MiMo API Key，再查找物品。',
        notFound: true,
        matches: [],
      );
    }

    final records = await _repository.recognizedRecords();
    if (records.isEmpty) {
      return const ResolvedSearchResult(
        answer: '还没有可查找的记忆卡。先拍一张东西放在哪里吧。',
        notFound: true,
        matches: [],
      );
    }

    final raw = await _mimoApiClient.searchRecords(
      apiKey: apiKey,
      question: question,
      recordSummaries: records
          .map((record) => record.summaryForSearch())
          .toList(),
    );
    return _resolve(raw, records);
  }

  ResolvedSearchResult _resolve(SearchResult raw, List<MemoryRecord> records) {
    final byId = {for (final record in records) record.recordId: record};
    final matches = raw.matches
        .where((match) => byId.containsKey(match.recordId))
        .map(
          (match) => ResolvedSearchMatch(
            record: byId[match.recordId]!,
            confidence: match.confidence,
            reason: match.reason,
          ),
        )
        .toList();

    return ResolvedSearchResult(
      answer: raw.answer,
      notFound: raw.notFound || matches.isEmpty,
      matches: matches,
    );
  }
}
