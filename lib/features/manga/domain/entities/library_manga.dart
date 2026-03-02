// lib/features/manga/domain/entities/library_manga.dart

class LibraryManga {
  final String id;
  final String mangaId;
  final String title;
  final String author;
  final String? coverImage;
  final String status; // Ongoing, Completed, Cancelled, etc.
  final double rating;
  final List<String> genre;
  final DateTime? addedAt;
  final DateTime? updatedAt;

  LibraryManga({
    required this.id,
    required this.mangaId,
    required this.title,
    required this.author,
    this.coverImage,
    required this.status,
    required this.rating,
    required this.genre,
    this.addedAt,
    this.updatedAt,
  });

  LibraryManga copyWith({
    String? id,
    String? mangaId,
    String? title,
    String? author,
    String? coverImage,
    String? status,
    double? rating,
    List<String>? genre,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return LibraryManga(
      id: id ?? this.id,
      mangaId: mangaId ?? this.mangaId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverImage: coverImage ?? this.coverImage,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      genre: genre ?? this.genre,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
