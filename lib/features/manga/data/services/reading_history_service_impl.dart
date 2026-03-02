// lib/features/manga/data/services/reading_history_service_impl.dart

import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../domain/entities/reading_history_entry.dart';
import '../../domain/services/reading_history_service.dart';
import '../models/reading_history_hive_model.dart';

class ReadingHistoryServiceImpl implements ReadingHistoryService {
  static const String _boxName = 'reading_history';
  late Box<dynamic> _box;

  /// Initialize the Hive box for reading history
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ReadingHistoryHiveModelAdapter());
    }
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<List<ReadingHistoryEntry>> getAll() async {
    try {
      final values = _box.values.cast<ReadingHistoryHiveModel>();
      return values.map((model) => model.toDomain()).toList();
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
      final values = _box.values.cast<ReadingHistoryHiveModel>();
      final entries = values.where((m) => m.mangaId == mangaId);
      return entries.isNotEmpty ? entries.first.toDomain() : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(ReadingHistoryEntry entry) async {
    try {
      final model = ReadingHistoryHiveModel.fromDomain(entry);
      await _box.put(entry.id, model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> update(ReadingHistoryEntry entry) async {
    try {
      final model = ReadingHistoryHiveModel.fromDomain(entry);
      await _box.put(entry.id, model);
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
