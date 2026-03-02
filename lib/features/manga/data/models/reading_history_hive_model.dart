// lib/features/manga/data/models/reading_history_hive_model.dart

import 'package:hive_ce/hive.dart';
import '../../domain/entities/reading_history_entry.dart';
part 'reading_history_hive_model.g.dart';

@HiveType(typeId: 0)
class ReadingHistoryHiveModel {
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
  final int? chapterNumber;

  @HiveField(6)
  final String? chapterTitle;

  @HiveField(7)
  final double progress; // 0-100

  @HiveField(8)
  final DateTime? lastReadAt;

  @HiveField(9)
  final DateTime? createdAt;

  ReadingHistoryHiveModel({
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

  /// Convert from Hive model to domain entity
  ReadingHistoryEntry toDomain() {
    return ReadingHistoryEntry(
      id: id,
      mangaId: mangaId,
      title: title,
      author: author,
      coverImage: coverImage,
      chapterNumber: chapterNumber,
      chapterTitle: chapterTitle,
      progress: progress,
      lastReadAt: lastReadAt,
      createdAt: createdAt,
    );
  }

  /// Convert from domain entity to Hive model
  factory ReadingHistoryHiveModel.fromDomain(ReadingHistoryEntry entry) {
    return ReadingHistoryHiveModel(
      id: entry.id,
      mangaId: entry.mangaId,
      title: entry.title,
      author: entry.author,
      coverImage: entry.coverImage,
      chapterNumber: entry.chapterNumber,
      chapterTitle: entry.chapterTitle,
      progress: entry.progress,
      lastReadAt: entry.lastReadAt,
      createdAt: entry.createdAt,
    );
  }

  /// Convert from API map to Hive model
  factory ReadingHistoryHiveModel.fromMap(Map<dynamic, dynamic> map) {
    return ReadingHistoryHiveModel(
      id: (map['id'] ?? map['_id'] ?? '') as String,
      mangaId: (map['mangaId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      author: (map['author'] ?? '') as String,
      coverImage: map['coverImage'] as String?,
      chapterNumber: map['chapterNumber'] as int?,
      chapterTitle: map['chapterTitle'] as String?,
      progress: ((map['progress'] ?? 0) as num).toDouble(),
      lastReadAt: map['lastReadAt'] != null
          ? DateTime.parse(map['lastReadAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
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
      'chapterNumber': chapterNumber,
      'chapterTitle': chapterTitle,
      'progress': progress,
      'lastReadAt': lastReadAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
