import 'dart:convert';

import 'package:xiaogui_xunwu/core/record_status.dart';

class MemoryRecord {
  const MemoryRecord({
    required this.recordId,
    required this.photoPath,
    required this.thumbnailPath,
    required this.capturedAt,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.gpsAccuracy,
    required this.userLocationNote,
    required this.aiMainObjects,
    required this.aiAliases,
    required this.aiSceneDescription,
    required this.aiLocationGuess,
    required this.aiSearchSummary,
    required this.aiConfidence,
    required this.status,
    required this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String recordId;
  final String photoPath;
  final String thumbnailPath;
  final DateTime capturedAt;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final double? gpsAccuracy;
  final String? userLocationNote;
  final List<String> aiMainObjects;
  final List<String> aiAliases;
  final String? aiSceneDescription;
  final String? aiLocationGuess;
  final String? aiSearchSummary;
  final double? aiConfidence;
  final RecordStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'record_id': recordId,
      'photo_path': photoPath,
      'thumbnail_path': thumbnailPath,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'gps_accuracy': gpsAccuracy,
      'user_location_note': userLocationNote,
      'ai_main_objects': jsonEncode(aiMainObjects),
      'ai_aliases': jsonEncode(aiAliases),
      'ai_scene_description': aiSceneDescription,
      'ai_location_guess': aiLocationGuess,
      'ai_search_summary': aiSearchSummary,
      'ai_confidence': aiConfidence,
      'status': status.storageValue,
      'error_message': errorMessage,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory MemoryRecord.fromMap(Map<String, Object?> map) {
    return MemoryRecord(
      recordId: map['record_id'] as String,
      photoPath: map['photo_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String,
      capturedAt: DateTime.parse(map['captured_at'] as String),
      gpsLatitude: _toDouble(map['gps_latitude']),
      gpsLongitude: _toDouble(map['gps_longitude']),
      gpsAccuracy: _toDouble(map['gps_accuracy']),
      userLocationNote: map['user_location_note'] as String?,
      aiMainObjects: _decodeStringList(map['ai_main_objects']),
      aiAliases: _decodeStringList(map['ai_aliases']),
      aiSceneDescription: map['ai_scene_description'] as String?,
      aiLocationGuess: map['ai_location_guess'] as String?,
      aiSearchSummary: map['ai_search_summary'] as String?,
      aiConfidence: _toDouble(map['ai_confidence']),
      status: RecordStatusX.fromStorageValue(map['status'] as String),
      errorMessage: map['error_message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String summaryForSearch() {
    final parts = <String>[
      '记录ID: $recordId',
      '拍摄时间: ${capturedAt.toLocal().toIso8601String()}',
    ];

    void addIfPresent(String label, String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        parts.add('$label: $trimmed');
      }
    }

    addIfPresent('用户位置备注', userLocationNote);
    if (aiMainObjects.isNotEmpty) {
      parts.add('主要物品: ${aiMainObjects.join(', ')}');
    }
    if (aiAliases.isNotEmpty) {
      parts.add('别名: ${aiAliases.join(', ')}');
    }
    addIfPresent('场景描述', aiSceneDescription);
    addIfPresent('AI位置猜测', aiLocationGuess);
    addIfPresent('搜索摘要', aiSearchSummary);

    if (gpsLatitude != null && gpsLongitude != null) {
      final gps = StringBuffer('GPS: $gpsLatitude, $gpsLongitude');
      if (gpsAccuracy != null) {
        gps.write(' (accuracy: ${gpsAccuracy}m)');
      }
      parts.add(gps.toString());
    }

    return parts.join('\n');
  }

  MemoryRecord copyWith({
    String? recordId,
    String? photoPath,
    String? thumbnailPath,
    DateTime? capturedAt,
    double? gpsLatitude,
    double? gpsLongitude,
    double? gpsAccuracy,
    String? userLocationNote,
    List<String>? aiMainObjects,
    List<String>? aiAliases,
    String? aiSceneDescription,
    String? aiLocationGuess,
    String? aiSearchSummary,
    double? aiConfidence,
    RecordStatus? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemoryRecord(
      recordId: recordId ?? this.recordId,
      photoPath: photoPath ?? this.photoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      capturedAt: capturedAt ?? this.capturedAt,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      userLocationNote: userLocationNote ?? this.userLocationNote,
      aiMainObjects: aiMainObjects ?? this.aiMainObjects,
      aiAliases: aiAliases ?? this.aiAliases,
      aiSceneDescription: aiSceneDescription ?? this.aiSceneDescription,
      aiLocationGuess: aiLocationGuess ?? this.aiLocationGuess,
      aiSearchSummary: aiSearchSummary ?? this.aiSearchSummary,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double? _toDouble(Object? value) {
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

  static List<String> _decodeStringList(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    final decoded = jsonDecode(value as String) as List<dynamic>;
    return decoded.map((item) => item.toString()).toList();
  }
}
