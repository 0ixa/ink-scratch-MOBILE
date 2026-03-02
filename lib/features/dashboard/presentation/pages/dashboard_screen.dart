// lib/features/dashboard/presentation/pages/dashboard_screen.dart
//
// Mirrors the web dashboard page exactly:
//   • Hero banner with greeting + "in library" stat
//   • Continue Reading (reading history with progress bars)
//   • Featured Today (large tall cards with genre badges + Featured badge)
//   • Top Rated (manga grid)
//   • Recently Updated (manga grid)
//   • My Library (mini grid + "Add More" cell)
//   • Browse CTA

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/view_model/auth_viewmodel_provider.dart';
import '../../../manga/data/providers/manga_providers.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kRed = Color(0xFFE63946);
const _kInk = Color(0xFF0A0A0F);
const _kBorder = Color(0x14FFFFFF); // white 8%

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  final VoidCallback onBrowseTap;
  const DashboardScreen({super.key, required this.onBrowseTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).currentUser;
    final displayName = user?.fullName ?? user?.username ?? 'Reader';

    final mangaAsync = ref.watch(mangaListProvider);
    final libraryAsync = ref.watch(libraryProvider);
    final historyAsync = ref.watch(readingHistoryProvider);

    return Scaffold(
      backgroundColor: _kInk,
      body: Stack(
        children: [
          // ── Ambient glows ──────────────────────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: _radialGlow(_kOrange, 360, 0.18),
          ),
          Positioned(
            bottom: 100,
            right: -60,
            child: _radialGlow(_kRed, 280, 0.12),
          ),
          // Halftone dots
          Opacity(
            opacity: 0.025,
            child: SizedBox.expand(child: CustomPaint(painter: _DotPainter())),
          ),
          // Scanlines
          Opacity(
            opacity: 0.018,
            child: SizedBox.expand(
              child: CustomPaint(painter: _ScanlinePainter()),
            ),
          ),
          // Diagonal lines (matches web)
          Opacity(
            opacity: 0.03,
            child: SizedBox.expand(
              child: CustomPaint(painter: _DiagLinePainter()),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─ App Bar ────────────────────────────────────────────────────
              _DashAppBar(greeting: _greeting()),

              // ─ Hero Banner ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroBanner(
                  displayName: displayName,
                  historyAsync: historyAsync,
                  libraryAsync: libraryAsync,
                ),
              ),

              // ─ Continue Reading ───────────────────────────────────────────
              _SectionPad(
                child: _SectionHeader(
                  title: 'Continue Reading',
                  sub: 'Pick up right where you left off',
                  chapter: 'Chapter 01 — In Progress',
                  onViewAll: onBrowseTap,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: historyAsync.when(
                    loading: () => _HistorySkeletonRow(),
                    error: (e, s) => const SizedBox.shrink(),
                    data: (history) => history.isEmpty
                        ? _EmptyState(
                            icon: '📖',
                            title: 'No Reading History Yet',
                            sub: 'Start reading a manga and it\'ll appear here',
                            cta: 'Browse Manga',
                            onTap: onBrowseTap,
                          )
                        : _ContinueReadingRow(
                            entries: history.take(6).toList(),
                          ),
                  ),
                ),
              ),

              // ─ Featured Today ─────────────────────────────────────────────
              _SectionPad(
                child: _SectionHeader(
                  title: 'Featured Today',
                  sub: 'Handpicked titles you might enjoy',
                  chapter: 'Chapter 02 — Featured',
                  onViewAll: onBrowseTap,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: mangaAsync.when(
                    loading: () => _FeaturedSkeleton(),
                    error: (e, s) => const SizedBox.shrink(),
                    data: (manga) {
                      final featured = (manga.toList()..shuffle())
                          .take(3)
                          .toList();
                      return _FeaturedRow(manga: featured, onTap: onBrowseTap);
                    },
                  ),
                ),
              ),

              // ─ Top Rated ─────────────────────────────────────────────────
              _SectionPad(
                child: _SectionHeader(
                  title: 'Top Rated',
                  sub: 'The best manga in the library',
                  chapter: 'Chapter 03 — Top Rated',
                  onViewAll: onBrowseTap,
                ),
              ),
              SliverToBoxAdapter(
                child: mangaAsync.when(
                  loading: () => _MangaGridSkeletonRow(),
                  error: (e, s) => const SizedBox.shrink(),
                  data: (manga) {
                    final sorted = [...manga]
                      ..sort((a, b) => b.rating.compareTo(a.rating));
                    return _MangaGridRow(
                      manga: sorted.take(6).toList(),
                      onTap: onBrowseTap,
                    );
                  },
                ),
              ),

              // ─ Recently Updated ───────────────────────────────────────────
              _SectionPad(
                child: _SectionHeader(
                  title: 'Recently Updated',
                  sub: 'Fresh chapters just added',
                  chapter: 'Chapter 04 — Latest',
                  onViewAll: onBrowseTap,
                ),
              ),
              SliverToBoxAdapter(
                child: mangaAsync.when(
                  loading: () => _MangaGridSkeletonRow(),
                  error: (e, s) => const SizedBox.shrink(),
                  data: (manga) {
                    return _MangaGridRow(
                      manga: manga.reversed.take(6).toList(),
                      onTap: onBrowseTap,
                    );
                  },
                ),
              ),

              // ─ My Library ────────────────────────────────────────────────
              _SectionPad(
                child: _SectionHeader(
                  title: 'My Library',
                  sub: 'Your saved titles',
                  chapter: 'Chapter 05 — Library',
                  onViewAll: onBrowseTap,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: libraryAsync.when(
                    loading: () => _MangaGridSkeletonRow(),
                    error: (e, s) => const SizedBox.shrink(),
                    data: (library) => library.isEmpty
                        ? _EmptyState(
                            icon: '📚',
                            title: 'Your Library is Empty',
                            sub: 'Browse manga and add titles to your library',
                            cta: 'Browse Manga',
                            onTap: onBrowseTap,
                          )
                        : _LibraryMiniGrid(
                            items: library.take(8).toList(),
                            onAddMore: onBrowseTap,
                          ),
                  ),
                ),
              ),

              // ─ Browse CTA ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 48),
                  child: _BrowseCTA(onTap: onBrowseTap),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _radialGlow(Color color, double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          Colors.transparent,
        ],
      ),
    ),
  );
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _DashAppBar extends StatelessWidget {
  final String greeting;
  const _DashAppBar({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kInk.withValues(alpha: 0.92),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 60,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: _kInk.withValues(alpha: 0.92),
          border: const Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'IS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [_kOrange, _kRed],
                  ).createShader(b),
                  child: const Text(
                    'INK SCRATCH',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$greeting 👋',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    letterSpacing: 0.5,
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

// ── Hero Banner ───────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final String displayName;
  final AsyncValue<dynamic> historyAsync;
  final AsyncValue<dynamic> libraryAsync;

  const _HeroBanner({
    required this.displayName,
    required this.historyAsync,
    required this.libraryAsync,
  });

  @override
  Widget build(BuildContext context) {
    final historyCount = historyAsync.valueOrNull?.length ?? 0;
    final libraryCount = libraryAsync.valueOrNull?.length ?? 0;

    return Stack(
      children: [
        // Diagonal stripe overlay (web: repeating-linear-gradient -55deg)
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(painter: _DiagLinePainter()),
          ),
        ),
        // Watermark text "LIBRARY" (web: large transparent text top-right)
        Positioned(
          top: -10,
          right: -20,
          child: Text(
            'LIBRARY',
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: _kOrange.withValues(alpha: 0.04),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow
              Row(
                children: [
                  Container(width: 28, height: 2, color: _kOrange),
                  const SizedBox(width: 12),
                  Text(
                    '${_greeting()} — Your Dashboard',
                    style: TextStyle(
                      color: _kOrange.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Display name (gradient)
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Colors.white, _kOrange, _kRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(b),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 0.92,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                historyCount > 0
                    ? 'You have $historyCount stor${historyCount == 1 ? "y" : "ies"} in progress. Keep the adventure going!'
                    : 'Start reading to track your progress here.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),

              // In Library stat card
              Container(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Left accent
                    Container(
                      width: 2,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _kOrange,
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📚', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              '$libraryCount',
                              style: const TextStyle(
                                color: _kOrange,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'IN LIBRARY',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String sub;
  final String chapter;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.sub,
    required this.chapter,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 20, height: 2, color: _kOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                chapter.toUpperCase(),
                style: TextStyle(
                  color: _kOrange.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'View All →',
                  style: TextStyle(
                    color: _kOrange.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Section padding sliver wrapper ────────────────────────────────────────────
class _SectionPad extends StatelessWidget {
  final Widget child;
  const _SectionPad({required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
        child: child,
      ),
    );
  }
}

// ── Continue Reading ──────────────────────────────────────────────────────────
class _ContinueReadingRow extends StatelessWidget {
  final List<dynamic> entries;
  const _ContinueReadingRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.map((entry) => _ContinueCard(entry: entry)).toList(),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final dynamic entry;
  const _ContinueCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final progress = (entry.progress as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Cover banner
          Stack(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: _Cover(
                  src: entry.coverImage as String?,
                  title: entry.title as String,
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Progress bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Stack(
                  children: [
                    Container(
                      height: 3,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    FractionallySizedBox(
                      widthFactor: (progress / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [_kOrange, _kRed]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Title + chapter overlay
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ch. ${entry.chapterNumber ?? "?"}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Bottom row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toInt()}% complete',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.1),
                    border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Continue →',
                    style: TextStyle(
                      color: _kOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 140 + 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// ── Featured Today ────────────────────────────────────────────────────────────
class _FeaturedRow extends StatelessWidget {
  final List<dynamic> manga;
  final VoidCallback onTap;
  const _FeaturedRow({required this.manga, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: manga
          .asMap()
          .entries
          .map(
            (e) => _FeaturedCard(
              manga: e.value,
              isFirst: e.key == 0,
              onTap: onTap,
            ),
          )
          .toList(),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final dynamic manga;
  final bool isFirst;
  final VoidCallback onTap;
  const _FeaturedCard({
    required this.manga,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final genres = (manga.genre as List?)?.take(2).toList() ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 240,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover
            _Cover(
              src: manga.coverImage as String?,
              title: manga.title as String,
            ),

            // Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE6000000)],
                  stops: [0.3, 1.0],
                ),
              ),
            ),

            // Featured badge (first card only)
            if (isFirst)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

            // Rating badge
            if ((manga.rating as num?) != null && manga.rating > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    border: Border.all(color: const Color(0x33F4D03F)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '★',
                        style: TextStyle(color: Color(0xFFF4D03F), fontSize: 9),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        (manga.rating as num).toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genre tags
                    if (genres.isNotEmpty)
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: genres
                            .map(
                              (g) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  g.toString().toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      manga.title as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${manga.author}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          height: 240,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// ── Manga grid row (Top Rated / Recently Updated) ─────────────────────────────
class _MangaGridRow extends StatelessWidget {
  final List<dynamic> manga;
  final VoidCallback onTap;
  const _MangaGridRow({required this.manga, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.57,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: manga.length,
        itemBuilder: (context, i) =>
            _MangaGridCard(manga: manga[i], onTap: onTap),
      ),
    );
  }
}

class _MangaGridCard extends StatelessWidget {
  final dynamic manga;
  final VoidCallback onTap;
  const _MangaGridCard({required this.manga, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Cover(
                    src: manga.coverImage as String?,
                    title: manga.title as String,
                  ),
                  // Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0x80000000), Colors.transparent],
                          stops: [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                  // Rating
                  if ((manga.rating as num?) != null && manga.rating > 0)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          border: Border.all(color: const Color(0x33F4D03F)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '★ ${(manga.rating as num).toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Color(0xFFF4D03F),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            manga.title as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            manga.author as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _MangaGridSkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.57,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── My Library mini-grid ──────────────────────────────────────────────────────
class _LibraryMiniGrid extends StatelessWidget {
  final List<dynamic> items;
  final VoidCallback onAddMore;
  const _LibraryMiniGrid({required this.items, required this.onAddMore});

  @override
  Widget build(BuildContext context) {
    // items + 1 "Add More" cell
    final count = items.length + 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (context, i) {
        if (i == items.length) {
          return GestureDetector(
            onTap: onAddMore,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kOrange.withValues(alpha: 0.2),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                      color: _kOrange.withValues(alpha: 0.03),
                    ),
                    child: Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          color: _kOrange.withValues(alpha: 0.4),
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add More',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        }
        final m = items[i];
        return GestureDetector(
          onTap: onAddMore,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _Cover(
                    src: m.coverImage as String?,
                    title: m.title as String,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                m.title as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Browse CTA ────────────────────────────────────────────────────────────────
class _BrowseCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _BrowseCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _kOrange.withValues(alpha: 0.04),
        border: Border.all(color: _kOrange.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: _kOrange.withValues(alpha: 0.25),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'FINAL ARC',
                  style: TextStyle(
                    color: _kOrange.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: _kOrange.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Discover New Stories',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thousands of manga titles waiting for you',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Browse All Titles →',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String sub;
  final String cta;
  final VoidCallback onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.sub,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
              height: 1.5,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Text(
                cta,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cover image with fallback ─────────────────────────────────────────────────
class _Cover extends StatefulWidget {
  final String? src;
  final String title;
  const _Cover({this.src, required this.title});

  @override
  State<_Cover> createState() => _CoverState();
}

class _CoverState extends State<_Cover> {
  bool _err = false;

  static const _gradients = [
    [Color(0xFF2a0a0a), Color(0xFF1a0a1a)],
    [Color(0xFF0a1a2a), Color(0xFF0a0a2a)],
    [Color(0xFF1a0a2e), Color(0xFF0d1a3a)],
    [Color(0xFF0a2a1a), Color(0xFF0a1a0a)],
    [Color(0xFF2a1a0a), Color(0xFF1a0a0a)],
    [Color(0xFF1a1a0a), Color(0xFF2a0a1a)],
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.src != null && widget.src!.isNotEmpty && !_err) {
      return Image.network(
        widget.src!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, s) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _err = true),
          );
          return _fallback();
        },
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final colors = _gradients[widget.title.codeUnitAt(0) % _gradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: CustomPaint(painter: _DotPainter()),
            ),
          ),
          const Center(
            child: Text(
              '📕',
              style: TextStyle(fontSize: 28, color: Colors.white10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────
class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _kOrange;
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DiagLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _kOrange.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    const spacing = 61.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
