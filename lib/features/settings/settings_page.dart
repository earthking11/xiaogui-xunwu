import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialApiKey,
    required this.onSave,
    required this.onTestApiKey,
  });

  final String? initialApiKey;
  final Future<void> Function(String value) onSave;
  final Future<void> Function(String value) onTestApiKey;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialApiKey ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'MiMo API Key',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Key 只保存在本机安全存储中，不写进源码或 APK。'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _testing
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() {
                      _testing = true;
                    });
                    try {
                      await widget.onTestApiKey(_controller.text.trim());
                      messenger.showSnackBar(
                        const SnackBar(content: Text('MiMo 连接正常')),
                      );
                    } on Exception catch (error) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('连接失败：${_friendlyError(error)}'),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _testing = false;
                        });
                      }
                    }
                  },
            icon: _testing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering_rounded),
            label: Text(_testing ? '测试中' : '测试 MiMo 连接'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    setState(() {
                      _saving = true;
                    });
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await widget.onSave(_controller.text.trim());
                    } on Exception catch (error) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(_friendlyError(error))),
                      );
                      if (mounted) {
                        setState(() {
                          _saving = false;
                        });
                      }
                      return;
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? '保存中' : '保存'),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Invalid HTTP header') ||
        message.contains('FormatException')) {
      return 'API Key 格式不对，请重新粘贴 MiMo 控制台里的完整 Key';
    }
    return message;
  }
}
