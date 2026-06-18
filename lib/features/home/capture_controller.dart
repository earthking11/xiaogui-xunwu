import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/record_status.dart';
import '../../models/memory_record.dart';
import '../../services/memory_repository.dart';
import '../../services/photo_storage_service.dart';
import '../../services/recognition_service.dart';

typedef LocationReader = Future<Position?> Function();
typedef IdGenerator = String Function();

class CaptureController {
  CaptureController({
    required MemoryRepository repository,
    required PhotoStorageService photoStorageService,
    required RecognitionService recognitionService,
    LocationReader? locationReader,
    DateTime Function()? now,
    IdGenerator? idGenerator,
  }) : _repository = repository,
       _photoStorageService = photoStorageService,
       _recognitionService = recognitionService,
       _locationReader = locationReader ?? _defaultLocationReader,
       _now = now ?? DateTime.now,
       _idGenerator = idGenerator ?? const Uuid().v4;

  final MemoryRepository _repository;
  final PhotoStorageService _photoStorageService;
  final RecognitionService _recognitionService;
  final LocationReader _locationReader;
  final DateTime Function() _now;
  final IdGenerator _idGenerator;

  Future<MemoryRecord> saveCapture({
    required List<int> jpegBytes,
    String? userLocationNote,
  }) async {
    final recordId = _idGenerator();
    final now = _now().toUtc();
    final photo = await _photoStorageService.saveJpegBytes(
      recordId: recordId,
      jpegBytes: jpegBytes,
    );
    final record = MemoryRecord(
      recordId: recordId,
      photoPath: photo.photoPath,
      thumbnailPath: photo.thumbnailPath,
      capturedAt: now,
      gpsLatitude: null,
      gpsLongitude: null,
      gpsAccuracy: null,
      userLocationNote: userLocationNote,
      aiMainObjects: const [],
      aiAliases: const [],
      aiSceneDescription: null,
      aiLocationGuess: null,
      aiSearchSummary: null,
      aiConfidence: null,
      status: RecordStatus.pending,
      errorMessage: null,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(record);
    final position = await _locationReader();
    final savedRecord = position == null
        ? record
        : record.copyWith(
            gpsLatitude: position.latitude,
            gpsLongitude: position.longitude,
            gpsAccuracy: position.accuracy,
            updatedAt: _now().toUtc(),
          );
    if (position != null) {
      await _repository.upsert(savedRecord);
    }
    unawaited(_recognitionService.recognize(recordId));
    return savedRecord;
  }
}

Future<Position?> _defaultLocationReader() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    ).timeout(const Duration(seconds: 3));
  } on Exception {
    return null;
  }
}
