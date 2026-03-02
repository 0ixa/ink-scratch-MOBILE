// lib/features/manga/domain/services/reading_history_service.dart

import '../entities/reading_history_entry.dart';

abstract class ReadingHistoryService {
  Future<List<ReadingHistoryEntry>> getAll();
  Future<ReadingHistoryEntry?> getById(String id);
  Future<ReadingHistoryEntry?> getByMangaId(String mangaId);
  Future<void> add(ReadingHistoryEntry entry);
  Future<void> update(ReadingHistoryEntry entry);
  Future<void> delete(String id);
  Future<void> clear();
}
