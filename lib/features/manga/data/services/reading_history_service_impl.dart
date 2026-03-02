// lib/features/manga/data/services/reading_history_service_impl.dart

import 'package:hive/hive.dart';
import '../../domain/entities/reading_history_entry.dart';
import '../../domain/services/reading_history_service.dart';

class ReadingHistoryServiceImpl implements ReadingHistoryService {
  static const String _boxName = 'reading_history';
  late Box<dynamic> _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<List<ReadingHistoryEntry>> getAll() async {
    try {
      final entries = _box.values.cast<Map<dynamic, dynamic>>().map((map) {
        return ReadingHistoryEntry(
          id: map['id'] as String,
          mangaId: map['mangaId'] as String,
          title: map['title'] as String,
          author: map['author'] as String,
          coverImage: map['coverImage'] as String?,
          chapterNumber: map['chapterNumber'] as int?,
          chapterTitle: map['chapterTitle'] as String?,
          progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
          lastReadAt: map['lastReadAt'] != null
              ? DateTime.parse(map['lastReadAt'] as String)
              : null,
          createdAt: map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : null,
        );
      }).toList();
      return entries;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ReadingHistoryEntry?> getById(String id) async {
    try {
      final map = _box.get(id) as Map<dynamic, dynamic>?;
      if (map == null) return null;
      return ReadingHistoryEntry(
        id: map['id'] as String,
        mangaId: map['mangaId'] as String,
        title: map['title'] as String,
        author: map['author'] as String,
        coverImage: map['coverImage'] as String?,
        chapterNumber: map['chapterNumber'] as int?,
        chapterTitle: map['chapterTitle'] as String?,
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        lastReadAt: map['lastReadAt'] != null
            ? DateTime.parse(map['lastReadAt'] as String)
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ReadingHistoryEntry?> getByMangaId(String mangaId) async {
    try {
      final entries = await getAll();
      return entries.firstWhere(
        (e) => e.mangaId == mangaId,
        orElse: () => null as ReadingHistoryEntry,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(ReadingHistoryEntry entry) async {
    try {
      await _box.put(entry.id, {
        'id': entry.id,
        'mangaId': entry.mangaId,
        'title': entry.title,
        'author': entry.author,
        'coverImage': entry.coverImage,
        'chapterNumber': entry.chapterNumber,
        'chapterTitle': entry.chapterTitle,
        'progress': entry.progress,
        'lastReadAt': entry.lastReadAt?.toIso8601String(),
        'createdAt': entry.createdAt?.toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> update(ReadingHistoryEntry entry) async {
    try {
      await _box.put(entry.id, {
        'id': entry.id,
        'mangaId': entry.mangaId,
        'title': entry.title,
        'author': entry.author,
        'coverImage': entry.coverImage,
        'chapterNumber': entry.chapterNumber,
        'chapterTitle': entry.chapterTitle,
        'progress': entry.progress,
        'lastReadAt': entry.lastReadAt?.toIso8601String(),
        'createdAt': entry.createdAt?.toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.clear();
    } catch (e) {
      rethrow;
    }
  }
}
