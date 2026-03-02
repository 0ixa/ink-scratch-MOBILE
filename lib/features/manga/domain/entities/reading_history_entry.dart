// lib/features/manga/domain/entities/reading_history_entry.dart

class ReadingHistoryEntry {
  final String id;
  final String mangaId;
  final String title;
  final String author;
  final String? coverImage;
  final int? chapterNumber;
  final String? chapterTitle;
  final double progress; // 0-100
  final DateTime? lastReadAt;
  final DateTime? createdAt;

  ReadingHistoryEntry({
    required this.id,
    required this.mangaId,
    required this.title,
    required this.author,
    this.coverImage,
    this.chapterNumber,
    this.chapterTitle,
    required this.progress,
    this.lastReadAt,
    this.createdAt,
  });

  ReadingHistoryEntry copyWith({
    String? id,
    String? mangaId,
    String? title,
    String? author,
    String? coverImage,
    int? chapterNumber,
    String? chapterTitle,
    double? progress,
    DateTime? lastReadAt,
    DateTime? createdAt,
  }) {
    return ReadingHistoryEntry(
      id: id ?? this.id,
      mangaId: mangaId ?? this.mangaId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverImage: coverImage ?? this.coverImage,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      progress: progress ?? this.progress,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
