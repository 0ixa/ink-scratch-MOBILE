// lib/features/manga/data/datasources/manga_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/manga_model.dart';
import '../../domain/entities/manga_entity.dart';

abstract class MangaRemoteDatasource {
  Future<MangaListResult> getAll({
    int page = 1,
    int limit = 24,
    String? genre,
    String? status,
    String? sort,
  });

  Future<List<MangaModel>> search(String query);

  Future<MangaModel> getById(String id);

  Future<List<ChapterModel>> getChapters(String mangaId);

  Future<List<ChapterPageEntity>> getChapterPages(String chapterId);
}

class MangaRemoteDatasourceImpl implements MangaRemoteDatasource {
  final Dio _dio;

  MangaRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<MangaListResult> getAll({
    int page = 1,
    int limit = 24,
    String? genre,
    String? status,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (genre != null && genre != 'All') 'genre': genre,
      if (status != null && status != 'All') 'status': status,
      if (sort != null) 'sort': sort,
    };

    final response = await _dio.get(
      ApiEndpoints.manga,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => MangaModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return MangaListResult(
      items: items,
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      pages: pagination['pages'] as int,
    );
  }

  @override
  Future<List<MangaModel>> search(String query) async {
    final response = await _dio.get(
      ApiEndpoints.mangaSearch,
      queryParameters: {'q': query},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((e) => MangaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MangaModel> getById(String id) async {
    final response = await _dio.get(ApiEndpoints.mangaById(id));
    final data = response.data as Map<String, dynamic>;
    return MangaModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ChapterModel>> getChapters(String mangaId) async {
    final response = await _dio.get(ApiEndpoints.mangaChapters(mangaId));
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((e) => ChapterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ChapterPageEntity>> getChapterPages(String chapterId) async {
    final response = await _dio.get(ApiEndpoints.chapterPages(chapterId));
    final data = response.data as Map<String, dynamic>;
    final chapterData = data['data'] as Map<String, dynamic>;
    final pages = chapterData['pages'] as List<dynamic>;
    return pages
        .map(
          (e) => ChapterPageEntity(
            index: e['index'] as int,
            imageUrl: e['imageUrl'] as String,
          ),
        )
        .toList();
  }
}
