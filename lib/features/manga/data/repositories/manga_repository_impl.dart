// lib/features/manga/data/repositories/manga_repository_impl.dart

import '../../domain/entities/manga_entity.dart';
import '../../domain/repositories/manga_repository.dart';
import '../datasources/manga_remote_datasource.dart';

class MangaRepositoryImpl implements MangaRepository {
  final MangaRemoteDatasource _remote;

  MangaRepositoryImpl({required MangaRemoteDatasource remote})
    : _remote = remote;

  @override
  Future<MangaListResult> getAll({
    int page = 1,
    int limit = 24,
    String? genre,
    String? status,
    String? sort,
  }) => _remote.getAll(
    page: page,
    limit: limit,
    genre: genre,
    status: status,
    sort: sort,
  );

  @override
  Future<List<MangaEntity>> search(String query) => _remote.search(query);

  @override
  Future<MangaEntity> getById(String id) => _remote.getById(id);

  @override
  Future<List<ChapterEntity>> getChapters(String mangaId) =>
      _remote.getChapters(mangaId);

  @override
  Future<List<ChapterPageEntity>> getChapterPages(String chapterId) =>
      _remote.getChapterPages(chapterId);
}
