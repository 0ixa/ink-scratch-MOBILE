// lib/features/manga/data/services/reading_history_service_impl.dart

import 'package:dio/dio.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../domain/entities/reading_history_entry.dart';
import '../../domain/services/reading_history_service.dart';
import '../models/reading_history_hive_model.dart';

class ReadingHistoryServiceImpl implements ReadingHistoryService {
  static const String _boxName = 'reading_history';

  final Dio _dio;
  late Box<ReadingHistoryHiveModel> _box;

  ReadingHistoryServiceImpl({required Dio dio}) : _dio = dio;

  /// Initialize the Hive box for reading history.
  /// Adapter registration is handled centrally by hive_registrar.g.dart.
  Future<void> init() async {
    _box = await Hive.openBox<ReadingHistoryHiveModel>(_boxName);
  }

  // ── Local reads ─────────────────────────────────────────────────────────────

  @override
  Future<List<ReadingHistoryEntry>> getAll() async {
    try {
      return _box.values.map((model) => model.toDomain()).toList()
        ..sort((a, b) {
          final aTime = a.lastReadAt ?? a.createdAt ?? DateTime(0);
          final bTime = b.lastReadAt ?? b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime); // most recent first
        });
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ReadingHistoryEntry?> getById(String id) async {
    try {
      return _box.get(id)?.toDomain();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReadingHistoryEntry?> getByMangaId(String mangaId) async {
    try {
      final entry = _box.values.firstWhere(
        (m) => m.mangaId == mangaId,
        orElse: () => throw StateError('not found'),
      );
      return entry.toDomain();
    } catch (_) {
      return null;
    }
  }

  // ── Writes: local-first, then remote sync ────────────────────────────────────

  @override
  Future<void> add(ReadingHistoryEntry entry) async {
    final model = ReadingHistoryHiveModel.fromDomain(entry);
    await _box.put(entry.id, model);
    await _syncToRemote(entry);
  }

  /// Updates the entry locally and pushes to the backend.
  /// Mirrors web's historyService.update() — POST /api/history/update.
  @override
  Future<void> update(ReadingHistoryEntry entry) async {
    // Preserve original createdAt if entry already exists locally
    final existing = _box.get(entry.mangaId) ?? _box.get(entry.id);
    final merged = entry.copyWith(
      createdAt: entry.createdAt ?? existing?.toDomain().createdAt,
      lastReadAt: entry.lastReadAt ?? DateTime.now(),
    );

    final model = ReadingHistoryHiveModel.fromDomain(merged);
    // Key by mangaId so there's only ever one entry per manga (same as backend)
    await _box.put(merged.mangaId, model);
    await _syncToRemote(merged);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    await _removeFromRemote(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
    await _clearRemote();
  }

  // ── Remote helpers ────────────────────────────────────────────────────────────

  /// POST /api/history/update
  /// Matches the payload shape expected by history.controller.ts
  Future<void> _syncToRemote(ReadingHistoryEntry entry) async {
    try {
      await _dio.post(
        '/history/update',
        data: {
          'mangaId': entry.mangaId,
          'title': entry.title,
          if (entry.coverImage != null) 'coverImage': entry.coverImage,
          'chapterId': entry.id,
          'chapterNumber': entry.chapterNumber,
          if (entry.chapterTitle != null) 'chapterTitle': entry.chapterTitle,
          'progress': entry.progress.round(),
        },
      );
    } catch (_) {
      // Silent fail — local data is source of truth when offline
    }
  }

  /// DELETE /api/history/:mangaId
  Future<void> _removeFromRemote(String mangaId) async {
    try {
      await _dio.delete('/history/$mangaId');
    } catch (_) {}
  }

  /// DELETE /api/history
  Future<void> _clearRemote() async {
    try {
      await _dio.delete('/history');
    } catch (_) {}
  }

  // ── Remote fetch (pull from backend into local cache) ────────────────────────

  /// Fetches the full history from the backend and syncs it into the local
  /// Hive box. Call this on app start or when the history screen is opened.
  Future<void> syncFromRemote() async {
    try {
      final response = await _dio.get('/history');
      final data = response.data as Map<String, dynamic>;
      final entries = (data['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      for (final map in entries) {
        final model = ReadingHistoryHiveModel.fromMap(map);
        // Key by mangaId — one entry per manga, matching backend behaviour
        await _box.put(model.mangaId, model);
      }
    } catch (_) {
      // Silently keep local cache if remote is unreachable
    }
  }
}
