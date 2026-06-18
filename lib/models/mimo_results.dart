class RecognitionResult {
  const RecognitionResult({
    required this.mainObjects,
    required this.aliases,
    required this.sceneDescription,
    required this.locationGuess,
    required this.searchSummary,
    required this.confidence,
    required this.needsUserNote,
  });

  final List<String> mainObjects;
  final List<String> aliases;
  final String sceneDescription;
  final String locationGuess;
  final String searchSummary;
  final double confidence;
  final bool needsUserNote;

  factory RecognitionResult.fromJson(Map<String, Object?> json) {
    return RecognitionResult(
      mainObjects: _stringList(json['mainObjects']),
      aliases: _stringList(json['aliases']),
      sceneDescription: json['sceneDescription'] as String? ?? '',
      locationGuess: json['locationGuess'] as String? ?? '',
      searchSummary: json['searchSummary'] as String? ?? '',
      confidence: _doubleValue(json['confidence']) ?? 0,
      needsUserNote: json['needsUserNote'] as bool? ?? false,
    );
  }
}

class SearchMatch {
  const SearchMatch({
    required this.recordId,
    required this.confidence,
    required this.reason,
  });

  final String recordId;
  final double confidence;
  final String reason;

  factory SearchMatch.fromJson(Map<String, Object?> json) {
    return SearchMatch(
      recordId: json['recordId'] as String? ?? '',
      confidence: _doubleValue(json['confidence']) ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }
}

class SearchResult {
  const SearchResult({
    required this.answer,
    required this.matches,
    required this.notFound,
  });

  final String answer;
  final List<SearchMatch> matches;
  final bool notFound;

  factory SearchResult.fromJson(Map<String, Object?> json) {
    return SearchResult(
      answer: json['answer'] as String? ?? '',
      matches: _matchList(json['matches']),
      notFound: json['notFound'] as bool? ?? false,
    );
  }
}

List<String> _stringList(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

List<SearchMatch> _matchList(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is List) {
    return value
        .whereType<Map>()
        .map(
          (item) => SearchMatch.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }
  return const [];
}

double? _doubleValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.parse(value as String);
}
