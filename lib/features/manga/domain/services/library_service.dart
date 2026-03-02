// lib/features/manga/domain/services/library_service.dart

import '../entities/library_manga.dart';

abstract class LibraryService {
  Future<List<LibraryManga>> getAll();
  Future<LibraryManga?> getById(String id);
  Future<LibraryManga?> getByMangaId(String mangaId);
  Future<void> add(LibraryManga manga);
  Future<void> update(LibraryManga manga);
  Future<void> remove(String mangaId);
  Future<void> clear();
  Future<bool> isMangaInLibrary(String mangaId);
}
