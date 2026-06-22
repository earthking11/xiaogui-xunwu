import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xiaogui_xunwu/core/record_status.dart';
import 'package:xiaogui_xunwu/models/memory_record.dart';
import 'package:xiaogui_xunwu/services/sqlite_memory_repository.dart';

void main() {
  late Database db;
  late SqliteMemoryRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    repository = SqliteMemoryRepository.fromDatabase(db);
    await repository.initialize();
  });

  tearDown(() async {
    await db.close();
  });

  MemoryRecord sampleRecord(String id, RecordStatus status) {
    final now = DateTime.parse('2026-06-18T10:20:30.000Z');
    return MemoryRecord(
      recordId: id,
      photoPath: '/photo/$id.jpg',
      thumbnailPath: '/photo/$id-thumb.jpg',
      capturedAt: now,
      gpsLatitude: null,
      gpsLongitude: null,
      gpsAccuracy: null,
      userLocationNote: null,
      aiMainObjects: const [],
      aiAliases: const [],
      aiSceneDescription: null,
      aiLocationGuess: null,
      aiSearchSummary: null,
      aiConfidence: null,
      status: status,
      errorMessage: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('inserts and reads records oldest first', () async {
    await repository.upsert(sampleRecord('one', RecordStatus.pending));
    await repository.upsert(sampleRecord('two', RecordStatus.recognized));

    final records = await repository.watchAllOnce();

    expect(records.map((r) => r.recordId), ['one', 'two']);
  });

  test('finds records that need recognition', () async {
    await repository.upsert(sampleRecord('pending', RecordStatus.pending));
    await repository.upsert(sampleRecord('failed', RecordStatus.failed));
    await repository.upsert(sampleRecord('stale', RecordStatus.recognizing));
    await repository.upsert(sampleRecord('done', RecordStatus.recognized));

    final records = await repository.recordsNeedingRecognition();

    expect(records.map((r) => r.recordId), ['pending', 'failed', 'stale']);
  });

  test('updates recognition result', () async {
    await repository.upsert(sampleRecord('card', RecordStatus.pending));

    final record = await repository.getById('card');
    await repository.upsert(
      record!.copyWith(
        status: RecordStatus.recognized,
        aiMainObjects: const ['钥匙'],
        aiSearchSummary: '钥匙 玄关',
        updatedAt: DateTime.parse('2026-06-18T10:30:00.000Z'),
      ),
    );

    final updated = await repository.getById('card');

    expect(updated!.status, RecordStatus.recognized);
    expect(updated.aiMainObjects, ['钥匙']);
    expect(updated.aiSearchSummary, '钥匙 玄关');
  });

  test('stores a readable location alongside GPS coordinates', () async {
    await repository.upsert(
      sampleRecord('location', RecordStatus.recognized).copyWith(
        gpsLatitude: 26.01,
        gpsLongitude: 119.3,
        readableLocation: '福建省福州市仓山区',
      ),
    );

    final record = await repository.getById('location');

    expect(record!.readableLocation, '福建省福州市仓山区');
    expect(record.gpsLatitude, 26.01);
  });
}
