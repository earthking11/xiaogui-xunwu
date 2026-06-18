import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/home/capture_controller.dart';
import 'features/home/home_page.dart';
import 'features/search/search_result_page.dart';
import 'features/settings/settings_page.dart';
import 'services/api_key_store.dart';
import 'services/memory_repository.dart';
import 'services/mimo_api_client.dart';
import 'services/photo_storage_service.dart';
import 'services/recognition_service.dart';
import 'services/search_service.dart';
import 'services/sqlite_memory_repository.dart';

class XiaoguiXunwuApp extends StatefulWidget {
  const XiaoguiXunwuApp({super.key});

  @override
  State<XiaoguiXunwuApp> createState() => _XiaoguiXunwuAppState();
}

class _XiaoguiXunwuAppState extends State<XiaoguiXunwuApp> {
  late final MemoryRepository _repository;
  late final ApiKeyStore _apiKeyStore;
  late final RecognitionService _recognitionService;
  late final SearchService _searchService;
  CaptureController? _captureController;
  CameraController? _cameraController;
  int _pendingCount = 0;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _repository = SqliteMemoryRepository();
    await _repository.initialize();

    _apiKeyStore = SecureApiKeyStore();
    final mimoApiClient = MimoApiClient();
    _recognitionService = RecognitionService(
      repository: _repository,
      apiKeyStore: _apiKeyStore,
      mimoApiClient: mimoApiClient,
    );
    _searchService = SearchService(
      repository: _repository,
      apiKeyStore: _apiKeyStore,
      mimoApiClient: mimoApiClient,
    );
    _captureController = CaptureController(
      repository: _repository,
      photoStorageService: PhotoStorageService(),
      recognitionService: _recognitionService,
    );

    await _initializeCamera();
    await _recognitionService.processBacklog();
    await _reloadPendingCount();

    if (mounted) {
      setState(() {
        _bootstrapped = true;
      });
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    _cameraController = controller;
  }

  Future<void> _reloadPendingCount() async {
    final pending = await _repository.recordsNeedingRecognition();
    if (!mounted) return;
    setState(() {
      _pendingCount = pending.length;
    });
  }

  Future<void> _capturePhoto(BuildContext context) async {
    final camera = _cameraController;
    final capture = _captureController;
    if (!_bootstrapped || camera == null || capture == null) return;

    final image = await camera.takePicture();
    final bytes = await image.readAsBytes();
    await capture.saveCapture(jpegBytes: bytes);
    await _reloadPendingCount();

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已保存，正在识别')));
  }

  Future<void> _openSettings(BuildContext context) async {
    final currentKey = await _apiKeyStore.readApiKey();
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          initialApiKey: currentKey,
          onSave: (value) async {
            await _apiKeyStore.saveApiKey(value);
          },
        ),
      ),
    );

    await _recognitionService.processBacklog();
    await _reloadPendingCount();
  }

  Future<void> _search(BuildContext context, String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先输入你想找什么')));
      return;
    }

    final result = await _searchService.search(trimmed);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchResultPage(question: trimmed, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '小龟寻物',
      theme: buildXunwuTheme(),
      home: Builder(
        builder: (context) {
          return HomePage(
            pendingCount: _pendingCount,
            cameraController: _cameraController,
            onCapturePressed: _bootstrapped
                ? () => _capturePhoto(context)
                : null,
            onSearchSubmitted: _bootstrapped
                ? (question) => _search(context, question)
                : null,
            onSettingsPressed: _bootstrapped
                ? () => _openSettings(context)
                : null,
          );
        },
      ),
    );
  }
}
