// lib/features/manga/data/services/library_service_impl.dart

import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../domain/entities/library_manga.dart';
import '../../domain/services/library_service.dart';
import '../models/library_manga_hive_model.dart';

class LibraryServiceImpl implements LibraryService {
  static const String _boxName = 'library';
  late Box<dynamic> _box;

  /// Initialize the Hive box for library
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LibraryMangaHiveModelAdapter());
    }
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<List<LibraryManga>> getAll() async {
    try {
      final values = _box.values.cast<LibraryMangaHiveModel>();
      return values.map((model) => model.toDomain()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<LibraryManga?> getById(String id) async {
    try {
      final model = _box.get(id);
      return model?.toDomain();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<LibraryManga?> getByMangaId(String mangaId) async {
    try {
      final values = _box.values.cast<LibraryMangaHiveModel>();
      final entries = values.where((m) => m.mangaId == mangaId);
      return entries.isNotEmpty ? entries.first.toDomain() : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(LibraryManga manga) async {
    try {
      final model = LibraryMangaHiveModel.fromDomain(manga);
      await _box.put(manga.mangaId, model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> update(LibraryManga manga) async {
    try {
      final model = LibraryMangaHiveModel.fromDomain(manga);
      await _box.put(manga.mangaId, model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> remove(String mangaId) async {
    try {
      final values = _box.values.cast<LibraryMangaHiveModel>();
      // Find the key by mangaId
      final entry = values.firstWhere(
        (m) => m.mangaId == mangaId,
        orElse: () => null as dynamic,
      );
      if (entry != null) {
        await _box.delete(entry.id);
      }
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

  @override
  Future<bool> isMangaInLibrary(String mangaId) async {
    try {
      final values = _box.values.cast<LibraryMangaHiveModel>();
      final result = values.any((m) => m.mangaId == mangaId);
      return result;
    } catch (e) {
      return false;
    }
  }
}
