import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.pendingCount,
    required this.cameraController,
    required this.onCapturePressed,
    required this.onSearchSubmitted,
    required this.onSettingsPressed,
  });

  final int pendingCount;
  final CameraController? cameraController;
  final VoidCallback? onCapturePressed;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onSettingsPressed;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '小龟寻物',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '设置',
                    onPressed: widget.onSettingsPressed,
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.cameraController != null &&
                          widget.cameraController!.value.isInitialized)
                        CameraPreview(widget.cameraController!)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F1EC),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFEDF7F1), Color(0xFFDDEBE4)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '相机准备中',
                            style: TextStyle(color: Color(0xFF6B7C73)),
                          ),
                        ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _StatusChip(pendingCount: widget.pendingCount),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 76,
                height: 76,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: XunwuColors.mint,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: widget.onCapturePressed,
                  child: const Icon(Icons.camera_alt_rounded, size: 32),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: widget.onSearchSubmitted,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: '问问小龟：我的东西放哪了？',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final text = pendingCount == 0 ? '记忆库已就绪' : '$pendingCount 张照片待识别';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: XunwuColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
