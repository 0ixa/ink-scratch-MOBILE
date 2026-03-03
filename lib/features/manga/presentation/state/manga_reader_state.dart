// lib/features/manga/presentation/state/manga_reader_state.dart

import '../../domain/entities/manga_entity.dart';

enum ReadMode { vertical, paged }

enum FitMode { width, height, original }

class MangaReaderState {
  final ChapterEntity? chapter;
  final List<ChapterPageEntity> pages;
  final List<ChapterEntity> allChapters;
  final bool isLoading;
  final String? error;
  final ReadMode readMode;
  final FitMode fitMode;
  final int currentPage;
  final bool uiVisible;
  final bool settingsOpen;
  final String mangaTitle;
  final String mangaCoverImage;

  const MangaReaderState({
    this.chapter,
    this.pages = const [],
    this.allChapters = const [],
    this.isLoading = true,
    this.error,
    this.readMode = ReadMode.vertical,
    this.fitMode = FitMode.width,
    this.currentPage = 1,
    this.uiVisible = true,
    this.settingsOpen = false,
    this.mangaTitle = '',
    this.mangaCoverImage = '',
  });

  int get totalPages => pages.length;

  int get progressPct =>
      totalPages > 0 ? ((currentPage / totalPages) * 100).round() : 0;

  int get currentChapterIndex =>
      allChapters.indexWhere((c) => c.id == chapter?.id);

  ChapterEntity? get prevChapter {
    final idx = currentChapterIndex;
    return idx > 0 ? allChapters[idx - 1] : null;
  }

  ChapterEntity? get nextChapter {
    final idx = currentChapterIndex;
    return (idx >= 0 && idx < allChapters.length - 1)
        ? allChapters[idx + 1]
        : null;
  }

  MangaReaderState copyWith({
    ChapterEntity? chapter,
    List<ChapterPageEntity>? pages,
    List<ChapterEntity>? allChapters,
    bool? isLoading,
    String? error,
    bool clearError = false,
    ReadMode? readMode,
    FitMode? fitMode,
    int? currentPage,
    bool? uiVisible,
    bool? settingsOpen,
    String? mangaTitle,
    String? mangaCoverImage,
  }) {
    return MangaReaderState(
      chapter: chapter ?? this.chapter,
      pages: pages ?? this.pages,
      allChapters: allChapters ?? this.allChapters,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      readMode: readMode ?? this.readMode,
      fitMode: fitMode ?? this.fitMode,
      currentPage: currentPage ?? this.currentPage,
      uiVisible: uiVisible ?? this.uiVisible,
      settingsOpen: settingsOpen ?? this.settingsOpen,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      mangaCoverImage: mangaCoverImage ?? this.mangaCoverImage,
    );
  }
}
