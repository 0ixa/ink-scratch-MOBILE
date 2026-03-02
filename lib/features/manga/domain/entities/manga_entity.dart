// lib/features/manga/domain/entities/manga_entity.dart

class MangaEntity {
  final String id;
  final String title;
  final List<String> alternativeTitles;
  final String author;
  final String artist;
  final String description;
  final List<String> genre;
  final String status; // 'Ongoing' | 'Completed' | 'Hiatus' | 'Cancelled'
  final String coverImage;
  final double rating;
  final int? year;
  final int totalChapters;
  final String source;
  final String sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MangaEntity({
    required this.id,
    required this.title,
    required this.alternativeTitles,
    required this.author,
    required this.artist,
    required this.description,
    required this.genre,
    required this.status,
    required this.coverImage,
    required this.rating,
    this.year,
    required this.totalChapters,
    required this.source,
    required this.sourceId,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ChapterEntity {
  final String id;
  final String mangaId;
  final double chapterNumber;
  final String? title;
  final String sourceId;
  final DateTime publishedAt;

  const ChapterEntity({
    required this.id,
    required this.mangaId,
    required this.chapterNumber,
    this.title,
    required this.sourceId,
    required this.publishedAt,
  });
}

class ChapterPageEntity {
  final int index;
  final String imageUrl;

  const ChapterPageEntity({required this.index, required this.imageUrl});
}

class MangaListResult {
  final List<MangaEntity> items;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const MangaListResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });
}
