// lib/features/manga/presentation/viewmodel/manga_reader_viewmodel.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_client_provider.dart';
import '../../data/datasources/manga_remote_datasource.dart';
import '../../domain/entities/manga_entity.dart';
import '../state/manga_reader_state.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final mangaReaderViewModelProvider =
    StateNotifierProvider.family<
      MangaReaderViewModel,
      MangaReaderState,
      ({String mangaId, String chapterId})
    >((ref, args) {
      final dio = ref.watch(apiClientProvider).client;
      return MangaReaderViewModel(
        mangaId: args.mangaId,
        chapterId: args.chapterId,
        datasource: MangaRemoteDatasourceImpl(dio: dio),
        dio: dio,
      );
    });

// ─────────────────────────────────────────────────────────────────────────────
// VIEW MODEL
// ─────────────────────────────────────────────────────────────────────────────
class MangaReaderViewModel extends StateNotifier<MangaReaderState> {
  final String mangaId;
  String _chapterId;
  final MangaRemoteDatasource _datasource;
  final Dio _dio;

  Timer? _hideTimer;
  Timer? _saveTimer;

  MangaReaderViewModel({
    required this.mangaId,
    required String chapterId,
    required MangaRemoteDatasource datasource,
    required Dio dio,
  }) : _chapterId = chapterId,
       _datasource = datasource,
       _dio = dio,
       super(const MangaReaderState()) {
    loadChapter(chapterId);
  }

  // ── Load ────────────────────────────────────────────────────────────────────
  Future<void> loadChapter(String newChapterId) async {
    _chapterId = newChapterId;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentPage: 1,
      pages: [],
    );

    try {
      // Parallel: chapter list + pages metadata
      final results = await Future.wait([
        _datasource.getChapters(mangaId),
        _datasource.getChapterPages(newChapterId),
      ]);

      final allChapters = results[0] as List<ChapterEntity>;

      // Find the current chapter entity from the list to get sourceId
      ChapterEntity? chapterEntity;
      try {
        chapterEntity = allChapters.firstWhere((c) => c.id == newChapterId);
      } catch (_) {
        // getChapterPages returns pages but we need sourceId — fall back to
        // scanning the chapters list by index if id match fails
        if (allChapters.isNotEmpty) chapterEntity = allChapters.first;
      }

      if (chapterEntity == null) throw Exception('Chapter not found');

      // Fetch fresh image URLs from MangaDex at-home (mirrors web getFreshPages)
      final freshPages = await _getFreshPages(chapterEntity.sourceId);

      // Fetch manga info once for history tracking
      String title = state.mangaTitle;
      String cover = state.mangaCoverImage;
      if (title.isEmpty) {
        try {
          final manga = await _datasource.getById(mangaId);
          title = manga.title;
          cover = manga.coverImage;
        } catch (_) {}
      }

      state = state.copyWith(
        chapter: chapterEntity,
        pages: freshPages,
        allChapters: allChapters,
        isLoading: false,
        mangaTitle: title,
        mangaCoverImage: cover,
      );

      // Save to history immediately on chapter open (progress = 0)
      _saveHistory(progress: 0);
      resetHideTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Mirrors mangaService.getFreshPages — calls MangaDex at-home directly
  Future<List<ChapterPageEntity>> _getFreshPages(String sourceId) async {
    final res = await Dio().get(
      'https://api.mangadex.org/at-home/server/$sourceId',
    );
    final data = res.data as Map<String, dynamic>;
    final baseUrl = data['baseUrl'] as String;
    final chapter = data['chapter'] as Map<String, dynamic>;
    final hash = chapter['hash'] as String;
    final files = (chapter['dataSaver'] as List<dynamic>).cast<String>();

    return files.asMap().entries.map((e) {
      return ChapterPageEntity(
        index: e.key,
        imageUrl: '$baseUrl/data-saver/$hash/${e.value}',
      );
    }).toList();
  }

  // ── UI visibility ─────────────────────────────────────────────────────────
  void resetHideTimer() {
    _hideTimer?.cancel();
    state = state.copyWith(uiVisible: true);
    _hideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) state = state.copyWith(uiVisible: false);
    });
  }

  // ── Page navigation ───────────────────────────────────────────────────────
  void setPage(int page) {
    final clamped = page.clamp(1, state.totalPages.clamp(1, 99999));
    state = state.copyWith(currentPage: clamped);
    _scheduleSaveHistory();
  }

  void goNext() {
    if (state.currentPage < state.totalPages) {
      setPage(state.currentPage + 1);
    }
  }

  void goPrev() {
    if (state.currentPage > 1) {
      setPage(state.currentPage - 1);
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  void toggleSettings() =>
      state = state.copyWith(settingsOpen: !state.settingsOpen);

  void setReadMode(ReadMode mode) =>
      state = state.copyWith(readMode: mode, currentPage: 1);

  void setFitMode(FitMode mode) => state = state.copyWith(fitMode: mode);

  // ── Vertical scroll page tracking ─────────────────────────────────────────
  void onPageVisible(int pageNumber) {
    if (pageNumber != state.currentPage) {
      state = state.copyWith(currentPage: pageNumber);
      _scheduleSaveHistory();
    }
  }

  // ── History ───────────────────────────────────────────────────────────────
  void _scheduleSaveHistory() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveHistory(progress: state.progressPct);
    });
  }

  void _saveHistory({required int progress}) {
    final chapter = state.chapter;
    if (chapter == null || state.mangaTitle.isEmpty) return;
    // Fire-and-forget with proper async error handling (avoids catchError type issues)
    Future(() async {
      try {
        await _dio.post(
          '/history/update',
          data: {
            'mangaId': mangaId,
            'title': state.mangaTitle,
            'coverImage': state.mangaCoverImage,
            'chapterId': _chapterId,
            'chapterNumber': chapter.chapterNumber,
            'chapterTitle': chapter.title ?? '',
            'progress': progress,
          },
        );
      } catch (_) {
        // Silent fail — offline-safe
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}
