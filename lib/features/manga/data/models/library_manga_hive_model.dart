// lib/features/manga/data/models/library_manga_hive_model.dart

import 'package:hive_ce/hive.dart';
import '../../domain/entities/library_manga.dart';
part 'library_manga_hive_model.g.dart';

@HiveType(typeId: 1)
class LibraryMangaHiveModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String mangaId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String author;

  @HiveField(4)
  final String? coverImage;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final double rating;

  @HiveField(7)
  final List<String> genre;

  @HiveField(8)
  final DateTime? addedAt;

  @HiveField(9)
  final DateTime? updatedAt;

  LibraryMangaHiveModel({
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

  /// Convert from Hive model to domain entity
  LibraryManga toDomain() {
    return LibraryManga(
      id: id,
      mangaId: mangaId,
      title: title,
      author: author,
      coverImage: coverImage,
      status: status,
      rating: rating,
      genre: genre,
      addedAt: addedAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert from domain entity to Hive model
  factory LibraryMangaHiveModel.fromDomain(LibraryManga manga) {
    return LibraryMangaHiveModel(
      id: manga.id,
      mangaId: manga.mangaId,
      title: manga.title,
      author: manga.author,
      coverImage: manga.coverImage,
      status: manga.status,
      rating: manga.rating,
      genre: manga.genre,
      addedAt: manga.addedAt,
      updatedAt: manga.updatedAt,
    );
  }

  /// Convert from API map to Hive model
  factory LibraryMangaHiveModel.fromMap(Map<dynamic, dynamic> map) {
    return LibraryMangaHiveModel(
      id: (map['_id'] ?? map['id'] ?? '') as String,
      mangaId: (map['mangaId'] ?? map['_id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      author: (map['author'] ?? '') as String,
      coverImage: map['coverImage'] as String?,
      status: (map['status'] ?? 'Unknown') as String,
      rating: ((map['rating'] ?? 0) as num).toDouble(),
      genre: (map['genre'] as List?)?.cast<String>() ?? [],
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Convert Hive model to map for API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mangaId': mangaId,
      'title': title,
      'author': author,
      'coverImage': coverImage,
      'status': status,
      'rating': rating,
      'genre': genre,
      'addedAt': addedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

// Import domain entity for type hints
