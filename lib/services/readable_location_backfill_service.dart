import 'memory_repository.dart';
import 'readable_location_service.dart';

class ReadableLocationBackfillService {
  ReadableLocationBackfillService({
    required MemoryRepository repository,
    required ReadableLocationService readableLocationService,
  }) : _repository = repository,
       _readableLocationService = readableLocationService;

  final MemoryRepository _repository;
  final ReadableLocationService _readableLocationService;

  Future<void> fillMissingLocations() async {
    final records = await _repository.watchAllOnce();
    for (final record in records) {
      if (record.gpsLatitude == null ||
          record.gpsLongitude == null ||
          (record.readableLocation?.trim().isNotEmpty ?? false)) {
        continue;
      }

      final readableLocation = await _readableLocationService.resolve(
        latitude: record.gpsLatitude!,
        longitude: record.gpsLongitude!,
      );
      if (readableLocation == null) continue;

      final latest = await _repository.getById(record.recordId);
      if (latest == null ||
          (latest.readableLocation?.trim().isNotEmpty ?? false)) {
        continue;
      }
      await _repository.upsert(
        latest.copyWith(
          readableLocation: readableLocation,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
  }
}
