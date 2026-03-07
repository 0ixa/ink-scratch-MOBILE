// lib/features/manga/presentation/viewmodel/manga_reader_viewmodel.dart
//
// SENSOR 2 — Gyroscope + Accelerometer (sensors_plus)
// ──────────────────────────────────────────────────────
// Two sensor streams run while the reader is open:
//
//   1. accelerometerEventStream()
//      Reads the gravity vector. When |x| significantly exceeds |y|, the
//      device is in landscape. This drives the isDualPage layout switch.
//      Threshold: |x| > 5.5 m/s² (out of ~9.8 max) with 0.3 s debounce.
//
//   2. gyroscopeEventStream()
//      Reads angular velocity (rad/s). When the combined magnitude exceeds
//      1.2 rad/s the device is actively rotating — sets isRotating = true
//      for 400 ms so the UI can show a brief shimmer transition.
//
// Package required (add to pubspec.yaml):
//   sensors_plus: ^6.0.0

import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

  // ── Sensor subscriptions ──────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _rotatingResetTimer;
  Timer? _orientationDebounce;

  // Landscape threshold: gravity x-component must exceed this (in m/s²)
  static const double _landscapeThreshold = 5.5;
  // Gyro rotation magnitude threshold (rad/s) to flag "actively rotating"
  static const double _gyroThreshold = 1.2;

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
    _startSensors();
  }

  // ── Sensor initialisation ─────────────────────────────────────────────────
  void _startSensors() {
    // 1. Accelerometer → orientation detection
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen(
          (AccelerometerEvent event) {
            final absX = event.x.abs();
            final absY = event.y.abs();
            final landscape = absX > _landscapeThreshold && absX > absY;

            // Debounce so a brief rotation flicker doesn't thrash the layout
            _orientationDebounce?.cancel();
            _orientationDebounce = Timer(const Duration(milliseconds: 300), () {
              if (mounted && landscape != state.isLandscape) {
                state = state.copyWith(isLandscape: landscape);
              }
            });
          },
          onError: (_) {
            // Sensor unavailable (e.g. emulator) — silently ignore
          },
        );

    // 2. Gyroscope → detect active rotation for shimmer transition
    _gyroSub =
        gyroscopeEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen((GyroscopeEvent event) {
          final magnitude = math.sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          if (magnitude > _gyroThreshold && !state.isRotating) {
            if (mounted) state = state.copyWith(isRotating: true);
            // Auto-clear the rotating flag after 400 ms
            _rotatingResetTimer?.cancel();
            _rotatingResetTimer = Timer(const Duration(milliseconds: 400), () {
              if (mounted) state = state.copyWith(isRotating: false);
            });
          }
        }, onError: (_) {});
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> loadChapter(String newChapterId) async {
    _chapterId = newChapterId;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentPage: 1,
      pages: [],
    );

    try {
      final results = await Future.wait([
        _datasource.getChapters(mangaId),
        _datasource.getChapterPages(newChapterId),
      ]);

      final allChapters = results[0] as List<ChapterEntity>;

      ChapterEntity? chapterEntity;
      try {
        chapterEntity = allChapters.firstWhere((c) => c.id == newChapterId);
      } catch (_) {
        if (allChapters.isNotEmpty) chapterEntity = allChapters.first;
      }

      if (chapterEntity == null) throw Exception('Chapter not found');

      final freshPages = await _getFreshPages(chapterEntity.sourceId);

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

      _saveHistory(progress: 0);
      resetHideTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

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

  /// Steps forward by 1 in portrait, by 2 in dual-page landscape mode.
  void goNext() {
    final step = state.isDualPage ? 2 : 1;
    if (state.currentPage + step - 1 <= state.totalPages) {
      setPage(state.currentPage + step);
    } else if (state.currentPage < state.totalPages) {
      // Edge case: odd-numbered last page in dual mode
      setPage(state.currentPage + 1);
    }
  }

  /// Steps backward by 1 in portrait, by 2 in dual-page landscape mode.
  void goPrev() {
    final step = state.isDualPage ? 2 : 1;
    if (state.currentPage > step) {
      setPage(state.currentPage - step);
    } else {
      setPage(1);
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
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _rotatingResetTimer?.cancel();
    _orientationDebounce?.cancel();
    super.dispose();
  }
}
