import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/memory_record.dart';
import '../../services/search_service.dart';

class SearchResultPage extends StatelessWidget {
  const SearchResultPage({
    super.key,
    required this.question,
    required this.result,
    this.showPhoto = true,
  });

  final String question;
  final ResolvedSearchResult result;
  final bool showPhoto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('查找结果')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            '你问：$question',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            _displayAnswer(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          for (final match in result.matches) ...[
            const SizedBox(height: 16),
            if (showPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(match.record.thumbnailPath),
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _InfoRow(label: '匹配理由', value: match.reason),
            _InfoRow(
              label: '拍摄时间',
              value: match.record.capturedAt.toLocal().toString(),
            ),
            if (match.record.readableLocation != null)
              _InfoRow(label: '拍摄地点', value: match.record.readableLocation!),
            if (match.record.userLocationNote != null)
              _InfoRow(label: '备注位置', value: match.record.userLocationNote!),
            if (match.record.aiLocationGuess != null)
              _InfoRow(label: '室内线索', value: match.record.aiLocationGuess!),
            if (match.record.gpsLatitude != null &&
                match.record.gpsLongitude != null)
              _InfoRow(label: 'GPS 坐标', value: _gpsText(match.record)),
          ],
        ],
      ),
    );
  }

  String _displayAnswer() {
    if (result.matches.isEmpty) return result.answer;
    final record = result.matches.first.record;
    final place = record.readableLocation?.trim();
    if (place == null || place.isEmpty) return result.answer;

    final object = record.aiMainObjects.isEmpty
        ? '这件东西'
        : record.aiMainObjects.join('、');
    final indoor = _indoorClue(record.aiLocationGuess);
    if (indoor == null) return '$object 可能在$place附近。';
    return '$object 可能在$place的$indoor。';
  }

  String? _indoorClue(String? raw) {
    var value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    value = value.replaceFirst(RegExp(r'^(可能)?(在|是)'), '');
    value = value.replaceFirst(RegExp(r'[。！]+$'), '');
    return value.isEmpty ? null : value;
  }

  String _gpsText(MemoryRecord record) {
    final accuracy = record.gpsAccuracy;
    final base = '${record.gpsLatitude}, ${record.gpsLongitude}';
    if (accuracy == null) return base;
    return '$base（精度约 ${accuracy.toStringAsFixed(0)} 米）';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
