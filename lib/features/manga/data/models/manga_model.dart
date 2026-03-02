// lib/features/manga/data/models/manga_model.dart

import '../../domain/entities/manga_entity.dart';

class MangaModel extends MangaEntity {
  const MangaModel({
    required super.id,
    required super.title,
    required super.alternativeTitles,
    required super.author,
    required super.artist,
    required super.description,
    required super.genre,
    required super.status,
    required super.coverImage,
    required super.rating,
    super.year,
    required super.totalChapters,
    required super.source,
    required super.sourceId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MangaModel.fromJson(Map<String, dynamic> json) {
    return MangaModel(
      id: json['_id'] as String,
      title: json['title'] as String? ?? '',
      alternativeTitles:
          (json['alternativeTitles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      author: json['author'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      description: json['description'] as String? ?? '',
      genre:
          (json['genre'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      status: json['status'] as String? ?? 'Ongoing',
      coverImage: json['coverImage'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      year: json['year'] as int?,
      totalChapters: json['totalChapters'] as int? ?? 0,
      source: json['source'] as String? ?? '',
      sourceId: json['sourceId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'alternativeTitles': alternativeTitles,
    'author': author,
    'artist': artist,
    'description': description,
    'genre': genre,
    'status': status,
    'coverImage': coverImage,
    'rating': rating,
    'year': year,
    'totalChapters': totalChapters,
    'source': source,
    'sourceId': sourceId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ChapterModel extends ChapterEntity {
  const ChapterModel({
    required super.id,
    required super.mangaId,
    required super.chapterNumber,
    super.title,
    required super.sourceId,
    required super.publishedAt,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['_id'] as String,
      mangaId: json['mangaId'] as String? ?? '',
      chapterNumber: (json['chapterNumber'] as num?)?.toDouble() ?? 0,
      title: json['title'] as String?,
      sourceId: json['sourceId'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
