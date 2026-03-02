// lib/features/manga/domain/repositories/manga_repository.dart

import '../entities/manga_entity.dart';

abstract class MangaRepository {
  Future<MangaListResult> getAll({
    int page = 1,
    int limit = 24,
    String? genre,
    String? status,
    String? sort,
  });

  Future<List<MangaEntity>> search(String query);

  Future<MangaEntity> getById(String id);

  Future<List<ChapterEntity>> getChapters(String mangaId);

  Future<List<ChapterPageEntity>> getChapterPages(String chapterId);
}
