import 'dart:io';

import 'package:flutter/material.dart';

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
    final top = result.matches.isEmpty ? null : result.matches.first;
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
            result.answer,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          if (top != null) ...[
            const SizedBox(height: 16),
            if (showPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(top.record.photoPath),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _InfoRow(label: '匹配理由', value: top.reason),
            _InfoRow(
              label: '拍摄时间',
              value: top.record.capturedAt.toLocal().toString(),
            ),
            if (top.record.userLocationNote != null)
              _InfoRow(label: '备注位置', value: top.record.userLocationNote!),
            if (top.record.aiLocationGuess != null)
              _InfoRow(label: 'AI 推测', value: top.record.aiLocationGuess!),
            if (top.record.gpsLatitude != null &&
                top.record.gpsLongitude != null)
              _InfoRow(
                label: 'GPS',
                value: '${top.record.gpsLatitude}, ${top.record.gpsLongitude}',
              ),
          ],
        ],
      ),
    );
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
