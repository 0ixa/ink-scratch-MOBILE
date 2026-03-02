// lib/features/manga/data/services/reading_history_service_impl.dart

import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../domain/entities/reading_history_entry.dart';
import '../../domain/services/reading_history_service.dart';
import '../models/reading_history_hive_model.dart';

class ReadingHistoryServiceImpl implements ReadingHistoryService {
  static const String _boxName = 'reading_history';
  late Box<ReadingHistoryHiveModel> _box;

  /// Initialize the Hive box for reading history.
  /// Adapter registration is handled centrally by hive_registrar.g.dart.
  Future<void> init() async {
    _box = await Hive.openBox<ReadingHistoryHiveModel>(_boxName);
  }

  @override
  Future<List<ReadingHistoryEntry>> getAll() async {
    try {
      return _box.values.map((model) => model.toDomain()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ReadingHistoryEntry?> getById(String id) async {
    try {
      final model = _box.get(id);
      return model?.toDomain();
    } catch (e) {
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
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(ReadingHistoryEntry entry) async {
    final model = ReadingHistoryHiveModel.fromDomain(entry);
    await _box.put(entry.id, model);
  }

  @override
  Future<void> update(ReadingHistoryEntry entry) async {
    final model = ReadingHistoryHiveModel.fromDomain(entry);
    await _box.put(entry.id, model);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
