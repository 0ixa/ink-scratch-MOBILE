// lib/features/manga/presentation/pages/manga_reader_page.dart
//
// SENSOR 2 — Gyroscope dual-page spread
// ──────────────────────────────────────
// When the gyroscope + accelerometer detect landscape orientation,
// `state.isDualPage` becomes true and the paged reader switches from
// showing 1 page to a 2-page spread (_DualPageReader), matching the
// traditional manga tankobon / physical book experience.
//
// Layout logic:
//   • Portrait  → 1 page, navigation ±1
//   • Landscape → 2 pages side by side, navigation ±2
//   • Covers:    first page (p.1) shown solo if total pages is odd
//   • Indicator: a landscape badge appears in the top-bar area

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/manga_entity.dart';
import '../state/manga_reader_state.dart';
import '../viewmodel/manga_reader_viewmodel.dart';

// ── Colour constants ──────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kRed = Color(0xFFE63946);
const _kInk = Color(0xFF0A0A0F);

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
class MangaReaderPage extends ConsumerStatefulWidget {
  final String mangaId;
  final String chapterId;

  const MangaReaderPage({
    super.key,
    required this.mangaId,
    required this.chapterId,
  });

  @override
  ConsumerState<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends ConsumerState<MangaReaderPage> {
  late String _currentChapterId;
  final _scrollController = ScrollController();

  ({String mangaId, String chapterId}) get _args =>
      (mangaId: widget.mangaId, chapterId: _currentChapterId);

  @override
  void initState() {
    super.initState();
    _currentChapterId = widget.chapterId;
    // Allow all orientations so gyroscope can detect landscape naturally
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Restore portrait-only when leaving the reader
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _navigateToChapter(String chapterId) {
    setState(() => _currentChapterId = chapterId);
    _scrollController.jumpTo(0);
    ref
        .read(mangaReaderViewModelProvider(_args).notifier)
        .loadChapter(chapterId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mangaReaderViewModelProvider(_args));
    final vm = ref.read(mangaReaderViewModelProvider(_args).notifier);

    if (state.isLoading) return const _LoadingScreen();
    if (state.error != null || state.chapter == null) {
      return _ErrorScreen(
        error: state.error ?? 'Chapter not found',
        mangaId: widget.mangaId,
      );
    }

    return Scaffold(
      backgroundColor: _kInk,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: vm.resetHideTimer,
        child: Stack(
          children: [
            // ── Main reader ────────────────────────────────────────────────
            state.readMode == ReadMode.vertical
                ? _VerticalReader(
                    state: state,
                    vm: vm,
                    scrollController: _scrollController,
                    mangaId: widget.mangaId,
                    onChapterNav: _navigateToChapter,
                  )
                : state.isDualPage
                // ── LANDSCAPE: 2-page spread ─────────────────────────────
                ? _DualPageReader(
                    state: state,
                    vm: vm,
                    mangaId: widget.mangaId,
                    onChapterNav: _navigateToChapter,
                  )
                // ── PORTRAIT: single page ────────────────────────────────
                : _PagedReader(
                    state: state,
                    vm: vm,
                    mangaId: widget.mangaId,
                    onChapterNav: _navigateToChapter,
                  ),

            // ── Top bar ────────────────────────────────────────────────────
            _TopBar(state: state, vm: vm, mangaId: widget.mangaId),

            // ── Bottom bar (paged & dual-page modes) ───────────────────────
            if (state.readMode == ReadMode.paged)
              _BottomBar(
                state: state,
                vm: vm,
                mangaId: widget.mangaId,
                onChapterNav: _navigateToChapter,
              ),

            // ── Rotation shimmer overlay (briefly on orientation change) ───
            if (state.isRotating) const _RotationOverlay(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DUAL PAGE READER  (landscape — 2 pages side by side)
// ─────────────────────────────────────────────────────────────────────────────
class _DualPageReader extends StatelessWidget {
  final MangaReaderState state;
  final MangaReaderViewModel vm;
  final String mangaId;
  final void Function(String) onChapterNav;

  const _DualPageReader({
    required this.state,
    required this.vm,
    required this.mangaId,
    required this.onChapterNav,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 60.0;
    final pages = state.pages;
    if (pages.isEmpty) return const SizedBox.shrink();

    // Page spread calculation:
    // p1Index is always odd-0-indexed: 0,2,4…
    // For page 1 we show it solo (cover convention). For everything else 2 at a time.
    final pageIndex = (state.currentPage - 1).clamp(0, pages.length - 1);
    final isFirst = pageIndex == 0;

    // Left page
    final leftPage = pages[pageIndex];
    // Right page — only if it exists and this isn't the solo first page
    final hasRight = !isFirst && pageIndex + 1 < pages.length;
    final rightPage = hasRight ? pages[pageIndex + 1] : null;

    final screenW = MediaQuery.of(context).size.width;
    final halfW = screenW / 2;

    return Stack(
      children: [
        // ── Spread ──────────────────────────────────────────────────────────
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: topPad, bottom: 60),
            child: Row(
              children: [
                // Left page
                SizedBox(
                  width: rightPage != null ? halfW : screenW,
                  child: _MangaPageImage(
                    page: leftPage,
                    fitMode: state.fitMode,
                    forceWidth: rightPage != null ? halfW : screenW,
                  ),
                ),

                // Right page
                if (rightPage != null)
                  SizedBox(
                    width: halfW,
                    child: _MangaPageImage(
                      page: rightPage,
                      fitMode: state.fitMode,
                      forceWidth: halfW,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Centre divider line
        if (rightPage != null)
          Positioned(
            left: halfW - 0.5,
            top: topPad,
            bottom: 60,
            child: Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),

        // ── Left tap zone → prev spread ──────────────────────────────────
        Positioned(
          left: 0,
          top: topPad,
          bottom: 0,
          width: screenW * 0.25,
          child: GestureDetector(
            onTap: vm.goPrev,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        // ── Right tap zone → next spread / next chapter ───────────────────
        Positioned(
          right: 0,
          top: topPad,
          bottom: 0,
          width: screenW * 0.25,
          child: GestureDetector(
            onTap: () {
              final nextPageIdx = pageIndex + (isFirst ? 1 : 2);
              if (nextPageIdx < pages.length) {
                vm.goNext();
              } else if (state.nextChapter != null) {
                onChapterNav(state.nextChapter!.id);
              }
            },
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        // ── Left arrow ────────────────────────────────────────────────────
        AnimatedOpacity(
          opacity: state.uiVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrow(
                icon: Icons.chevron_left_rounded,
                enabled: state.currentPage > 1,
                onTap: vm.goPrev,
              ),
            ),
          ),
        ),

        // ── Right arrow ───────────────────────────────────────────────────
        AnimatedOpacity(
          opacity: state.uiVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrow(
                icon: Icons.chevron_right_rounded,
                enabled:
                    state.currentPage < state.totalPages ||
                    state.nextChapter != null,
                onTap: () {
                  final nextPageIdx = pageIndex + (isFirst ? 1 : 2);
                  if (nextPageIdx < pages.length) {
                    vm.goNext();
                  } else if (state.nextChapter != null) {
                    onChapterNav(state.nextChapter!.id);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROTATION OVERLAY  (brief shimmer when device rotates)
// ─────────────────────────────────────────────────────────────────────────────
class _RotationOverlay extends StatelessWidget {
  const _RotationOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [_kOrange.withValues(alpha: 0.08), Colors.transparent],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.screen_rotation_rounded,
                  color: _kOrange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'ROTATING…',
                  style: TextStyle(
                    color: _kOrange.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final MangaReaderState state;
  final MangaReaderViewModel vm;
  final String mangaId;

  const _TopBar({required this.state, required this.vm, required this.mangaId});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: state.uiVisible ? 0 : -(120 + MediaQuery.of(context).padding.top),
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Container(
            height: 3,
            color: Colors.white.withValues(alpha: 0.1),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (state.progressPct / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_kOrange, _kRed]),
                ),
              ),
            ),
          ),

          // Main top bar
          Container(
            color: const Color(0xFF111111).withValues(alpha: 0.95),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 12,
              right: 12,
            ),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withValues(alpha: 0.15),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // Chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chapter ${_fmtNum(state.chapter!.chapterNumber)}'
                        '${state.chapter!.title != null ? ": ${state.chapter!.title}" : ""}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _pageLabel(state),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Landscape dual-page badge ──────────────────────────────
                if (state.isDualPage) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _kOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: _kOrange,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '2-PAGE',
                          style: const TextStyle(
                            color: _kOrange,
                            fontSize: 9,
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Page counter pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pageCounterLeft(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '/',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${state.totalPages}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Settings toggle
                GestureDetector(
                  onTap: vm.toggleSettings,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: state.settingsOpen
                          ? _kOrange.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: state.settingsOpen
                          ? _kOrange
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Settings panel
          if (state.settingsOpen) _SettingsPanel(state: state, vm: vm),
        ],
      ),
    );
  }

  /// "Page 1-2 of 24" in dual mode, "Page 3 of 24" in single mode
  String _pageLabel(MangaReaderState s) {
    if (s.isDualPage && s.currentPage < s.totalPages) {
      final p1 = s.currentPage;
      final p2 = (s.currentPage == 1) ? 1 : (s.currentPage + 1);
      final capped = p2.clamp(1, s.totalPages);
      return 'Pages $p1–$capped of ${s.totalPages}';
    }
    return 'Page ${s.currentPage} of ${s.totalPages}';
  }

  /// Shows "1–2" in the counter pill when dual-page
  String _pageCounterLeft(MangaReaderState s) {
    if (s.isDualPage && s.currentPage < s.totalPages && s.currentPage > 1) {
      return '${s.currentPage}–${(s.currentPage + 1).clamp(1, s.totalPages)}';
    }
    return '${s.currentPage}';
  }

  String _fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsPanel extends StatelessWidget {
  final MangaReaderState state;
  final MangaReaderViewModel vm;

  const _SettingsPanel({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A).withValues(alpha: 0.98),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          // Reading mode
          _settingsLabel('READING MODE'),
          const SizedBox(height: 8),
          Row(
            children: [
              _SettingsChip(
                icon: Icons.view_agenda_rounded,
                label: 'Vertical Scroll',
                active: state.readMode == ReadMode.vertical,
                onTap: () => vm.setReadMode(ReadMode.vertical),
              ),
              const SizedBox(width: 8),
              _SettingsChip(
                icon: Icons.menu_book_rounded,
                label: 'Page by Page',
                active: state.readMode == ReadMode.paged,
                onTap: () => vm.setReadMode(ReadMode.paged),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Fit mode
          _settingsLabel('IMAGE FIT'),
          const SizedBox(height: 8),
          Row(
            children: [
              _SettingsChip(
                label: 'Fit Width',
                active: state.fitMode == FitMode.width,
                onTap: () => vm.setFitMode(FitMode.width),
              ),
              const SizedBox(width: 8),
              _SettingsChip(
                label: 'Fit Height',
                active: state.fitMode == FitMode.height,
                onTap: () => vm.setFitMode(FitMode.height),
              ),
              const SizedBox(width: 8),
              _SettingsChip(
                label: 'Original',
                active: state.fitMode == FitMode.original,
                onTap: () => vm.setFitMode(FitMode.original),
              ),
            ],
          ),
          // Sensor info row
          const SizedBox(height: 14),
          _settingsLabel('ORIENTATION SENSOR'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: state.isDualPage
                  ? _kOrange.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: state.isDualPage
                    ? _kOrange.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.isDualPage
                      ? Icons.screen_rotation_alt_rounded
                      : Icons.stay_current_portrait_rounded,
                  size: 14,
                  color: state.isDualPage
                      ? _kOrange
                      : Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  state.isDualPage
                      ? 'Landscape detected — 2-page spread active'
                      : 'Portrait — rotate device for 2-page spread',
                  style: TextStyle(
                    color: state.isDualPage
                        ? _kOrange.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _settingsLabel(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 9,
      fontFamily: 'monospace',
      letterSpacing: 2,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _SettingsChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  const _SettingsChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? _kOrange.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? _kOrange.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: active ? _kOrange : Colors.white38),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? _kOrange : Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR  (paged + dual-page modes)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final MangaReaderState state;
  final MangaReaderViewModel vm;
  final String mangaId;
  final void Function(String) onChapterNav;

  const _BottomBar({
    required this.state,
    required this.vm,
    required this.mangaId,
    required this.onChapterNav,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = state.totalPages.clamp(1, 99999);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: state.uiVisible ? 0 : -120,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: Color(0xEE111111),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slider
            Row(
              children: [
                Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _kOrange,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      thumbColor: _kOrange,
                      overlayColor: _kOrange.withValues(alpha: 0.2),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      min: 1,
                      max: totalPages.toDouble(),
                      value: state.currentPage.toDouble().clamp(
                        1.0,
                        totalPages.toDouble(),
                      ),
                      onChanged: (v) => vm.setPage(v.round()),
                    ),
                  ),
                ),
                Text(
                  '$totalPages',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (state.prevChapter != null)
                  GestureDetector(
                    onTap: () => onChapterNav(state.prevChapter!.id),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                        Text(
                          'Prev Ch.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(),
                // Dual-page label in bottom bar too
                state.isDualPage
                    ? Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 11,
                            color: _kOrange.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pages ${state.currentPage}–'
                            '${(state.currentPage + 1).clamp(1, totalPages)} of $totalPages',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Page ${state.currentPage} of $totalPages',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                if (state.nextChapter != null)
                  GestureDetector(
                    onTap: () => onChapterNav(state.nextChapter!.id),
                    child: Row(
                      children: [
                        Text(
                          'Next Ch.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERTICAL READER  (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────
class _VerticalReader extends StatelessWidget {
  final MangaReaderState state;
  final MangaReaderViewModel vm;
  final ScrollController scrollController;
  final String mangaId;
  final void Function(String) onChapterNav;

  const _VerticalReader({
    required this.state,
    required this.vm,
    required this.scrollController,
    required this.mangaId,
    required this.onChapterNav,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 60.0;

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(top: topPad),
      physics: const BouncingScrollPhysics(),
      itemCount: state.pages.length + 1,
      itemBuilder: (context, index) {
        if (index < state.pages.length) {
          return _VisibilityAwarePage(
            page: state.pages[index],
            fitMode: state.fitMode,
            onVisible: () => vm.onPageVisible(index + 1),
          );
        }
        return _ChapterEndCard(
          state: state,
          mangaId: mangaId,
          onChapterNav: onChapterNav,
        );
      },
    );
  }
}

class _VisibilityAwarePage extends StatefulWidget {
  final ChapterPageEntity page;
  final FitMode fitMode;
  final VoidCallback onVisible;

  const _VisibilityAwarePage({
    required this.page,
    required this.fitMode,
    required this.onVisible,
  });

  @override
  State<_VisibilityAwarePage> createState() => _VisibilityAwarePageState();
}

class _VisibilityAwarePageState extends State<_VisibilityAwarePage> {
  @override
  Widget build(BuildContext context) {
    return VisibilityDetectorShim(
      onVisible: widget.onVisible,
      child: _MangaPageImage(page: widget.page, fitMode: widget.fitMode),
    );
  }
}

class VisibilityDetectorShim extends StatefulWidget {
  final Widget child;
  final VoidCallback onVisible;

  const VisibilityDetectorShim({
    super.key,
    required this.child,
    required this.onVisible,
  });

  @override
  State<VisibilityDetectorShim> createState() => _VisibilityDetectorShimState();
}

class _VisibilityDetectorShimState extends State<VisibilityDetectorShim> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (_) {
        _checkVisibility();
        return false;
      },
      child: widget.child,
    );
  }

  void _checkVisibility() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final offset = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    final centre = offset.dy + box.size.height / 2;
    if (centre > screenH * 0.25 && centre < screenH * 0.75) {
      widget.onVisible();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGED READER  (portrait — single page, unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────
class _PagedReader extends StatelessWidget {
  final MangaReaderState state;
  final MangaReaderViewModel vm;
  final String mangaId;
  final void Function(String) onChapterNav;

  const _PagedReader({
    required this.state,
    required this.vm,
    required this.mangaId,
    required this.onChapterNav,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 60.0;
    final pages = state.pages;
    if (pages.isEmpty) return const SizedBox.shrink();

    final pageIndex = (state.currentPage - 1).clamp(0, pages.length - 1);

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: topPad),
            child: _MangaPageImage(
              page: pages[pageIndex],
              fitMode: state.fitMode,
            ),
          ),
        ),

        Positioned(
          left: 0,
          top: topPad,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.33,
          child: GestureDetector(
            onTap: vm.goPrev,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        Positioned(
          right: 0,
          top: topPad,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.33,
          child: GestureDetector(
            onTap: () {
              if (state.currentPage < state.totalPages) {
                vm.goNext();
              } else if (state.nextChapter != null) {
                onChapterNav(state.nextChapter!.id);
              }
            },
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        AnimatedOpacity(
          opacity: state.uiVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrow(
                icon: Icons.chevron_left_rounded,
                enabled: state.currentPage > 1,
                onTap: vm.goPrev,
              ),
            ),
          ),
        ),

        AnimatedOpacity(
          opacity: state.uiVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrow(
                icon: Icons.chevron_right_rounded,
                enabled:
                    state.currentPage < state.totalPages ||
                    state.nextChapter != null,
                onTap: () {
                  if (state.currentPage < state.totalPages) {
                    vm.goNext();
                  } else if (state.nextChapter != null) {
                    onChapterNav(state.nextChapter!.id);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.2,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE IMAGE WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _MangaPageImage extends StatefulWidget {
  final ChapterPageEntity page;
  final FitMode fitMode;
  final double? forceWidth; // override width for dual-page layout

  const _MangaPageImage({
    required this.page,
    required this.fitMode,
    this.forceWidth,
  });

  @override
  State<_MangaPageImage> createState() => _MangaPageImageState();
}

class _MangaPageImageState extends State<_MangaPageImage> {
  bool _loaded = false;
  bool _error = false;

  BoxFit get _fit {
    switch (widget.fitMode) {
      case FitMode.width:
        return BoxFit.fitWidth;
      case FitMode.height:
        return BoxFit.fitHeight;
      case FitMode.original:
        return BoxFit.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = widget.forceWidth ?? MediaQuery.of(context).size.width;

    if (_error) {
      return Container(
        color: const Color(0xFF1A1A1A),
        width: screenW,
        height: screenW * 1.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Page ${widget.page.index + 1} failed to load',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (!_loaded)
          _Shimmer(
            child: Container(
              width: screenW,
              height: screenW * 1.5,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        Image.network(
          widget.page.imageUrl,
          fit: _fit,
          width: widget.fitMode == FitMode.height ? null : screenW,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _loaded = true);
              });
            }
            return Opacity(opacity: _loaded ? 1.0 : 0.0, child: child);
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _error = true);
            });
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAPTER END CARD  (vertical mode)
// ─────────────────────────────────────────────────────────────────────────────
class _ChapterEndCard extends StatelessWidget {
  final MangaReaderState state;
  final String mangaId;
  final void Function(String) onChapterNav;

  const _ChapterEndCard({
    required this.state,
    required this.mangaId,
    required this.onChapterNav,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            'End of Chapter ${_fmtNum(state.chapter!.chapterNumber)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          if (state.chapter!.title != null) ...[
            const SizedBox(height: 4),
            Text(
              state.chapter!.title!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.prevChapter != null)
                _EndButton(
                  label: 'Previous',
                  icon: Icons.chevron_left_rounded,
                  iconFirst: true,
                  isAccent: false,
                  onTap: () => onChapterNav(state.prevChapter!.id),
                ),
              if (state.prevChapter != null && state.nextChapter != null)
                const SizedBox(width: 12),
              if (state.nextChapter != null)
                _EndButton(
                  label: 'Next Chapter',
                  icon: Icons.chevron_right_rounded,
                  isAccent: true,
                  onTap: () => onChapterNav(state.nextChapter!.id),
                )
              else
                _EndButton(
                  label: 'Back to Manga',
                  icon: Icons.chevron_right_rounded,
                  isAccent: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
}

class _EndButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconFirst;
  final bool isAccent;
  final VoidCallback onTap;

  const _EndButton({
    required this.label,
    required this.icon,
    this.iconFirst = false,
    required this.isAccent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: Colors.white, size: 18);
    final labelWidget = Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isAccent
              ? const LinearGradient(colors: [_kOrange, _kRed])
              : null,
          color: isAccent ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isAccent
              ? [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst
              ? [iconWidget, const SizedBox(width: 6), labelWidget]
              : [labelWidget, const SizedBox(width: 6), iconWidget],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _anim, child: widget.child);
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _kInk,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(color: _kOrange, strokeWidth: 3),
            ),
            SizedBox(height: 20),
            Text(
              'Loading chapter…',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final String error;
  final String mangaId;

  const _ErrorScreen({required this.error, required this.mangaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kInk,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Failed to load chapter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Back to Manga',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
