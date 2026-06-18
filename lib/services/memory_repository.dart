import '../models/memory_record.dart';

abstract class MemoryRepository {
  Future<void> initialize();
  Future<void> upsert(MemoryRecord record);
  Future<MemoryRecord?> getById(String recordId);
  Future<List<MemoryRecord>> watchAllOnce();
  Future<List<MemoryRecord>> recognizedRecords();
  Future<List<MemoryRecord>> recordsNeedingRecognition();
  Future<void> delete(String recordId);
}
