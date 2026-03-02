// lib/features/manga/data/services/library_service_impl.dart

import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../domain/entities/library_manga.dart';
import '../../domain/services/library_service.dart';
import '../models/library_manga_hive_model.dart';

class LibraryServiceImpl implements LibraryService {
  static const String _boxName = 'library';
  late Box<LibraryMangaHiveModel> _box;

  /// Initialize the Hive box for library.
  /// Adapter registration is handled centrally by hive_registrar.g.dart.
  Future<void> init() async {
    _box = await Hive.openBox<LibraryMangaHiveModel>(_boxName);
  }

  @override
  Future<List<LibraryManga>> getAll() async {
    try {
      return _box.values.map((model) => model.toDomain()).toList();
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
      final entry = _box.values.cast<LibraryMangaHiveModel?>().firstWhere(
        (m) => m?.mangaId == mangaId,
        orElse: () => null,
      );
      return entry?.toDomain();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(LibraryManga manga) async {
    final model = LibraryMangaHiveModel.fromDomain(manga);
    await _box.put(manga.mangaId, model);
  }

  @override
  Future<void> update(LibraryManga manga) async {
    final model = LibraryMangaHiveModel.fromDomain(manga);
    await _box.put(manga.mangaId, model);
  }

  @override
  Future<void> remove(String mangaId) async {
    // Since we key by mangaId in add/update, we can delete directly
    await _box.delete(mangaId);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  @override
  Future<bool> isMangaInLibrary(String mangaId) async {
    try {
      return _box.values.any((m) => m.mangaId == mangaId);
    } catch (e) {
      return false;
    }
  }
}
