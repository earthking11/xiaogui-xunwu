import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/record_status.dart';
import '../models/memory_record.dart';
import 'memory_repository.dart';

class SqliteMemoryRepository implements MemoryRepository {
  SqliteMemoryRepository({Database? database}) : _database = database;

  SqliteMemoryRepository.fromDatabase(Database database) : _database = database;

  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'xiaogui_xunwu.db');
    final db = await openDatabase(path, version: 1);
    _database = db;
    await initialize();
    return db;
  }

  @override
  Future<void> initialize() async {
    final db = _database ?? await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_records (
        record_id TEXT PRIMARY KEY,
        photo_path TEXT NOT NULL,
        thumbnail_path TEXT NOT NULL,
        captured_at TEXT NOT NULL,
        gps_latitude REAL,
        gps_longitude REAL,
        gps_accuracy REAL,
        user_location_note TEXT,
        ai_main_objects TEXT NOT NULL,
        ai_aliases TEXT NOT NULL,
        ai_scene_description TEXT,
        ai_location_guess TEXT,
        ai_search_summary TEXT,
        ai_confidence REAL,
        status TEXT NOT NULL,
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<void> upsert(MemoryRecord record) async {
    final db = await _db;
    await db.insert(
      'memory_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<MemoryRecord?> getById(String recordId) async {
    final db = await _db;
    final rows = await db.query(
      'memory_records',
      where: 'record_id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MemoryRecord.fromMap(rows.single);
  }

  @override
  Future<List<MemoryRecord>> watchAllOnce() async {
    final db = await _db;
    final rows = await db.query('memory_records', orderBy: 'created_at ASC');
    return rows.map(MemoryRecord.fromMap).toList();
  }

  @override
  Future<List<MemoryRecord>> recognizedRecords() async {
    final db = await _db;
    final rows = await db.query(
      'memory_records',
      where: 'status = ?',
      whereArgs: [RecordStatus.recognized.storageValue],
      orderBy: 'created_at DESC',
    );
    return rows.map(MemoryRecord.fromMap).toList();
  }

  @override
  Future<List<MemoryRecord>> recordsNeedingRecognition() async {
    final db = await _db;
    final rows = await db.query(
      'memory_records',
      where: 'status IN (?, ?)',
      whereArgs: [
        RecordStatus.pending.storageValue,
        RecordStatus.failed.storageValue,
      ],
      orderBy: 'created_at ASC',
    );
    return rows.map(MemoryRecord.fromMap).toList();
  }

  @override
  Future<void> delete(String recordId) async {
    final db = await _db;
    await db.delete(
      'memory_records',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }
}
