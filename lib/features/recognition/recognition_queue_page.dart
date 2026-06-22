import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/record_status.dart';
import '../../models/memory_record.dart';
import '../../services/memory_repository.dart';
import '../../services/photo_storage_service.dart';
import '../../services/recognition_service.dart';

class RecognitionQueuePage extends StatefulWidget {
  const RecognitionQueuePage({
    super.key,
    required this.repository,
    required this.photoStorageService,
    required this.recognitionService,
    required this.onRecordsChanged,
  });

  final MemoryRepository repository;
  final PhotoStorageService photoStorageService;
  final RecognitionService recognitionService;
  final Future<void> Function() onRecordsChanged;

  @override
  State<RecognitionQueuePage> createState() => _RecognitionQueuePageState();
}

class _RecognitionQueuePageState extends State<RecognitionQueuePage> {
  final _timeFormat = DateFormat('MM-dd HH:mm');
  List<MemoryRecord> _records = const [];
  final Set<String> _runningIds = {};
  bool _loading = true;
  bool _processingAll = false;
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await widget.repository.watchAllOnce();
    if (!mounted) return;
    setState(() {
      _records = records.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _recognizeOne(String recordId) async {
    if (_runningIds.contains(recordId)) return;
    setState(() {
      _runningIds.add(recordId);
    });
    await widget.recognitionService.recognize(recordId);
    await widget.onRecordsChanged();
    await _load();
    if (!mounted) return;
    setState(() {
      _runningIds.remove(recordId);
    });
  }

  Future<void> _recognizeAll() async {
    if (_processingAll) return;
    setState(() {
      _processingAll = true;
    });
    await widget.recognitionService.processBacklog();
    await widget.onRecordsChanged();
    await _load();
    if (!mounted) return;
    setState(() {
      _processingAll = false;
    });
  }

  Future<void> _deleteRecord(MemoryRecord record) async {
    if (_deletingIds.contains(record.recordId)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条记忆？'),
        content: const Text('照片、缩略图和识别信息都会从小龟寻物中删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingIds.add(record.recordId);
    });
    try {
      await widget.repository.delete(record.recordId);
      await widget.photoStorageService.deleteStoredPhoto(
        photoPath: record.photoPath,
        thumbnailPath: record.thumbnailPath,
      );
      await widget.onRecordsChanged();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已删除这条记忆')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(record.recordId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _records
        .where(
          (record) =>
              record.status == RecordStatus.pending ||
              record.status == RecordStatus.failed,
        )
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('识别进度'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? const Center(child: Text('还没有拍过照片'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _records.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilledButton.icon(
                    onPressed: pendingCount == 0 || _processingAll
                        ? null
                        : _recognizeAll,
                    icon: _processingAll
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.playlist_play_rounded),
                    label: Text(
                      pendingCount == 0
                          ? '没有待识别照片'
                          : '开始识别 $pendingCount 张待处理照片',
                    ),
                  );
                }
                final record = _records[index - 1];
                return _RecordTile(
                  record: record,
                  timeText: _timeFormat.format(record.capturedAt.toLocal()),
                  running: _runningIds.contains(record.recordId),
                  onRecognize: () => _recognizeOne(record.recordId),
                  deleting: _deletingIds.contains(record.recordId),
                  onDelete: () => _deleteRecord(record),
                );
              },
            ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.timeText,
    required this.running,
    required this.onRecognize,
    required this.deleting,
    required this.onDelete,
  });

  final MemoryRecord record;
  final String timeText;
  final bool running;
  final VoidCallback onRecognize;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final canRecognize = record.status != RecordStatus.recognized;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: XunwuColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(record.thumbnailPath),
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 78,
                      height: 78,
                      color: const Color(0xFFE8F1EC),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              timeText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _StatusPill(status: record.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _headline(record),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (record.errorMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _friendlyError(record.errorMessage!),
                          style: const TextStyle(color: Color(0xFFB3261E)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Detail(label: '拍摄地点', value: record.readableLocation),
            _Detail(label: '位置备注', value: record.userLocationNote),
            _Detail(label: '主要物品', value: record.aiMainObjects.join('、')),
            _Detail(label: '别名', value: record.aiAliases.join('、')),
            _Detail(label: '场景', value: record.aiSceneDescription),
            _Detail(label: '室内线索', value: record.aiLocationGuess),
            _Detail(label: '搜索摘要', value: record.aiSearchSummary),
            if (record.aiConfidence != null)
              _Detail(
                label: '置信度',
                value: record.aiConfidence!.toStringAsFixed(2),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: deleting ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB3261E),
                  ),
                  icon: deleting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(deleting ? '删除中' : '删除'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: canRecognize && !running && !deleting
                      ? onRecognize
                      : null,
                  icon: running
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(running ? '识别中' : '手动识别'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _headline(MemoryRecord record) {
    if (record.aiMainObjects.isNotEmpty) {
      return record.aiMainObjects.join('、');
    }
    switch (record.status) {
      case RecordStatus.pending:
        return '等待识别';
      case RecordStatus.recognizing:
        return '正在识别';
      case RecordStatus.failed:
        return '识别失败，可手动重试';
      case RecordStatus.recognized:
        return '已识别';
    }
  }

  String _friendlyError(String message) {
    if (message.contains('Invalid HTTP header') ||
        message.contains('FormatException')) {
      return 'API Key 格式不对，请到设置页重新粘贴 MiMo 控制台里的完整 Key';
    }
    return message;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final RecordStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      RecordStatus.pending => ('待识别', XunwuColors.warm),
      RecordStatus.recognizing => ('识别中', XunwuColors.mint),
      RecordStatus.recognized => ('已完成', XunwuColors.mintDark),
      RecordStatus.failed => ('失败', const Color(0xFFB3261E)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label：',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
