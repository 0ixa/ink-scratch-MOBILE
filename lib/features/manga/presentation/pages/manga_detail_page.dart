// lib/features/manga/presentation/pages/manga_detail_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/manga_providers.dart';
import '../../domain/entities/manga_entity.dart';
import '../../domain/entities/library_manga.dart';
import 'manga_reader_page.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kRed = Color(0xFFE63946);
const _kInk = Color(0xFF0A0A0F);
const _kBorder = Color(0x0FFFFFFF);

// ── Status helpers ────────────────────────────────────────────────────────────
Color _statusColor(String s) {
  switch (s) {
    case 'Ongoing':
      return const Color(0xFF4ADE80);
    case 'Completed':
      return const Color(0xFF60A5FA);
    case 'Cancelled':
      return const Color(0xFFF87171);
    default:
      return const Color(0xFFFBBF24);
  }
}

Color _statusBg(String s) => _statusColor(s).withValues(alpha: 0.15);

// ── Time-ago helper ────────────────────────────────────────────────────────────
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays == 0) return 'Today';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

// ── State held by the page ────────────────────────────────────────────────────
enum _Tab { chapters, about }

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class MangaDetailPage extends ConsumerStatefulWidget {
  final String mangaId;
  const MangaDetailPage({super.key, required this.mangaId});

  @override
  ConsumerState<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends ConsumerState<MangaDetailPage> {
  MangaEntity? _manga;
  List<ChapterEntity> _chapters = [];
  bool _loading = true;
  String? _error;
  _Tab _tab = _Tab.chapters;
  bool _inLibrary = false;
  bool _libLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = ref.read(mangaRemoteDatasourceProvider);
      final results = await Future.wait([
        ds.getById(widget.mangaId),
        ds.getChapters(widget.mangaId),
      ]);
      final manga = results[0] as MangaEntity;
      final chapters = results[1] as List<ChapterEntity>;

      final libNotifier = ref.read(libraryProvider.notifier);
      final inLib = await libNotifier.isMangaInLibrary(manga.id);

      if (mounted) {
        setState(() {
          _manga = manga;
          _chapters = chapters;
          _inLibrary = inLib;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleLibrary() async {
    if (_manga == null || _libLoading) return;
    setState(() => _libLoading = true);
    try {
      final notifier = ref.read(libraryProvider.notifier);
      if (_inLibrary) {
        await notifier.remove(_manga!.id);
        if (mounted) setState(() => _inLibrary = false);
      } else {
        await notifier.add(
          LibraryManga(
            id: _manga!.id,
            mangaId: _manga!.id,
            title: _manga!.title,
            author: _manga!.author,
            coverImage: _manga!.coverImage,
            status: _manga!.status,
            genre: _manga!.genre,
            rating: _manga!.rating,
          ),
        );
        if (mounted) setState(() => _inLibrary = true);
      }
    } finally {
      if (mounted) setState(() => _libLoading = false);
    }
  }

  void _openReader(String chapterId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MangaReaderPage(mangaId: widget.mangaId, chapterId: chapterId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _LoadingScreen();
    if (_error != null || _manga == null) {
      return _ErrorScreen(error: _error ?? 'Failed to load manga');
    }
    return _DetailBody(
      manga: _manga!,
      chapters: _chapters,
      tab: _tab,
      inLibrary: _inLibrary,
      libLoading: _libLoading,
      onTabChange: (t) => setState(() => _tab = t),
      onLibraryToggle: _toggleLibrary,
      onReadChapter: _openReader,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL BODY
// ─────────────────────────────────────────────────────────────────────────────
class _DetailBody extends StatelessWidget {
  final MangaEntity manga;
  final List<ChapterEntity> chapters;
  final _Tab tab;
  final bool inLibrary;
  final bool libLoading;
  final ValueChanged<_Tab> onTabChange;
  final VoidCallback onLibraryToggle;
  final ValueChanged<String> onReadChapter;

  const _DetailBody({
    required this.manga,
    required this.chapters,
    required this.tab,
    required this.inLibrary,
    required this.libLoading,
    required this.onTabChange,
    required this.onLibraryToggle,
    required this.onReadChapter,
  });

  @override
  Widget build(BuildContext context) {
    final reversed = chapters.reversed.toList();
    final first = chapters.isNotEmpty ? chapters.first : null;
    final latest = chapters.isNotEmpty ? chapters.last : null;

    return Scaffold(
      backgroundColor: _kInk,
      body: Stack(
        children: [
          Positioned(top: -80, left: -60, child: _glow(_kOrange, 360, 0.18)),
          Positioned(bottom: 100, right: -60, child: _glow(_kRed, 280, 0.12)),
          Opacity(
            opacity: 0.025,
            child: SizedBox.expand(child: CustomPaint(painter: _DotPainter())),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  manga: manga,
                  chapters: chapters,
                  first: first,
                  latest: latest,
                  inLibrary: inLibrary,
                  libLoading: libLoading,
                  onLibrary: onLibraryToggle,
                  onReadFirst: first != null
                      ? () => onReadChapter(first.id)
                      : null,
                  onReadLatest: latest != null
                      ? () => onReadChapter(latest.id)
                      : null,
                ),
              ),

              SliverToBoxAdapter(
                child: _StatsBar(manga: manga, chapterCount: chapters.length),
              ),

              SliverToBoxAdapter(
                child: _TabBar(
                  tab: tab,
                  chapterCount: chapters.length,
                  onTabChange: onTabChange,
                ),
              ),

              if (tab == _Tab.chapters)
                _ChaptersSliver(
                  chapters: reversed,
                  onReadChapter: onReadChapter,
                )
              else
                SliverToBoxAdapter(
                  child: _AboutTab(manga: manga, chapterCount: chapters.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glow(Color c, double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          c.withValues(alpha: opacity),
          Colors.transparent,
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO
// ─────────────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final MangaEntity manga;
  final List<ChapterEntity> chapters;
  final ChapterEntity? first;
  final ChapterEntity? latest;
  final bool inLibrary;
  final bool libLoading;
  final VoidCallback onLibrary;
  final VoidCallback? onReadFirst;
  final VoidCallback? onReadLatest;

  const _Hero({
    required this.manga,
    required this.chapters,
    required this.first,
    required this.latest,
    required this.inLibrary,
    required this.libLoading,
    required this.onLibrary,
    required this.onReadFirst,
    required this.onReadLatest,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Stack(
        children: [
          if (manga.coverImage.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                manga.coverImage,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.75),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kInk.withValues(alpha: 0.55),
                    _kInk.withValues(alpha: 0.92),
                    _kInk,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
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
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _CoverImage(
                      src: manga.coverImage,
                      title: manga.title,
                      width: 120,
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 16, height: 2, color: _kOrange),
                              const SizedBox(width: 8),
                              Text(
                                'MANGA DETAIL',
                                style: TextStyle(
                                  color: _kOrange.withValues(alpha: 0.6),
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              ...manga.genre
                                  .take(3)
                                  .map((g) => _Chip(label: g)),
                              _StatusChip(status: manga.status),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text(
                            manga.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),

                          _MetaRow(manga: manga),
                          const SizedBox(height: 8),

                          if (manga.rating > 0)
                            _RatingRow(rating: manga.rating),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (manga.description.isNotEmpty)
                  Text(
                    manga.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                const SizedBox(height: 20),

                _ActionButtons(
                  first: first,
                  latest: latest,
                  inLibrary: inLibrary,
                  libLoading: libLoading,
                  onReadFirst: onReadFirst,
                  onReadLatest: onReadLatest,
                  onLibrary: onLibrary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta row ──────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final MangaEntity manga;
  const _MetaRow({required this.manga});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Author', manga.author.isNotEmpty ? manga.author : 'Unknown'),
      if (manga.artist.isNotEmpty && manga.artist != manga.author)
        ('Artist', manga.artist),
      if (manga.year != null) ('Year', manga.year.toString()),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: items
          .map(
            (item) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1.toUpperCase(),
                  style: TextStyle(
                    color: _kOrange.withValues(alpha: 0.5),
                    fontSize: 8,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

// ── Rating row ────────────────────────────────────────────────────────────────
class _RatingRow extends StatelessWidget {
  final double rating;
  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(
          5,
          (i) => Text(
            '★',
            style: TextStyle(
              color: rating / 2 >= i + 1
                  ? const Color(0xFFF4D03F)
                  : Colors.white.withValues(alpha: 0.15),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          ' / 10',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final ChapterEntity? first;
  final ChapterEntity? latest;
  final bool inLibrary;
  final bool libLoading;
  final VoidCallback? onReadFirst;
  final VoidCallback? onReadLatest;
  final VoidCallback onLibrary;

  const _ActionButtons({
    required this.first,
    required this.latest,
    required this.inLibrary,
    required this.libLoading,
    required this.onReadFirst,
    required this.onReadLatest,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final showLatest = latest != null && latest!.id != first?.id;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onReadFirst != null)
          _ActionBtn(
            label: 'Start Reading',
            onTap: onReadFirst!,
            style: _BtnStyle.white,
          ),
        if (showLatest && onReadLatest != null)
          _ActionBtn(
            label: 'Latest Chapter',
            onTap: onReadLatest!,
            style: _BtnStyle.accent,
          ),
        _ActionBtn(
          label: libLoading
              ? '...'
              : inLibrary
              ? 'In Library'
              : '+ Library',
          onTap: onLibrary,
          style: inLibrary ? _BtnStyle.inLibrary : _BtnStyle.ghost,
        ),
      ],
    );
  }
}

enum _BtnStyle { white, accent, ghost, inLibrary }

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final _BtnStyle style;

  const _ActionBtn({
    required this.label,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      label,
      style: TextStyle(
        color: style == _BtnStyle.white
            ? _kInk
            : style == _BtnStyle.inLibrary
            ? _kOrange
            : Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );

    BoxDecoration deco;
    switch (style) {
      case _BtnStyle.white:
        deco = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        );
      case _BtnStyle.accent:
        deco = BoxDecoration(
          gradient: const LinearGradient(colors: [_kOrange, _kRed]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: _kOrange.withValues(alpha: 0.35), blurRadius: 16),
          ],
        );
      case _BtnStyle.inLibrary:
        deco = BoxDecoration(
          color: _kOrange.withValues(alpha: 0.12),
          border: Border.all(color: _kOrange.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        );
      case _BtnStyle.ghost:
        deco = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(12),
        );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: deco,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS BAR
// ─────────────────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final MangaEntity manga;
  final int chapterCount;
  const _StatsBar({required this.manga, required this.chapterCount});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Chapters', chapterCount.toString()),
      ('Status', manga.status),
      (
        'Rating',
        manga.rating > 0 ? '${manga.rating.toStringAsFixed(1)}/10' : 'N/A',
      ),
      ('Year', manga.year?.toString() ?? 'N/A'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: const Border(
          top: BorderSide(color: _kBorder),
          bottom: BorderSide(color: _kBorder),
        ),
      ),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final i = e.key;
          final stat = e.value;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: i > 0
                      ? const BorderSide(color: _kBorder)
                      : BorderSide.none,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                children: [
                  Text(
                    stat.$2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stat.$1.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final _Tab tab;
  final int chapterCount;
  final ValueChanged<_Tab> onTabChange;

  const _TabBar({
    required this.tab,
    required this.chapterCount,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _TabBtn(
            label: 'Chapters ($chapterCount)',
            active: tab == _Tab.chapters,
            onTap: () => onTabChange(_Tab.chapters),
          ),
          const SizedBox(width: 4),
          _TabBtn(
            label: 'About',
            active: tab == _Tab.about,
            onTap: () => onTabChange(_Tab.about),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? _kOrange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _kOrange : Colors.white.withValues(alpha: 0.35),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAPTERS SLIVER
// ─────────────────────────────────────────────────────────────────────────────
class _ChaptersSliver extends StatelessWidget {
  final List<ChapterEntity> chapters;
  final ValueChanged<String> onReadChapter;

  const _ChaptersSliver({required this.chapters, required this.onReadChapter});

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Text('📂', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text(
                  'No Chapters Yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chapters are being imported in the background',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ChapterRow(
            chapter: chapters[i],
            isLatest: i == 0,
            onTap: () => onReadChapter(chapters[i].id),
          ),
          childCount: chapters.length,
        ),
      ),
    );
  }
}

class _ChapterRow extends StatefulWidget {
  final ChapterEntity chapter;
  final bool isLatest;
  final VoidCallback onTap;

  const _ChapterRow({
    required this.chapter,
    required this.isLatest,
    required this.onTap,
  });

  @override
  State<_ChapterRow> createState() => _ChapterRowState();
}

class _ChapterRowState extends State<_ChapterRow> {
  bool _hovered = false;

  String _fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered
              ? _kOrange.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: _hovered ? _kOrange.withValues(alpha: 0.3) : _kBorder,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: widget.isLatest
                    ? const LinearGradient(colors: [_kOrange, _kRed])
                    : null,
                color: widget.isLatest
                    ? null
                    : Colors.white.withValues(alpha: 0.05),
                border: widget.isLatest ? null : Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(10),
                boxShadow: widget.isLatest
                    ? [
                        BoxShadow(
                          color: _kOrange.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _fmtNum(widget.chapter.chapterNumber),
                  style: TextStyle(
                    color: widget.isLatest
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Chapter ${_fmtNum(widget.chapter.chapterNumber)}'
                          '${widget.chapter.title != null ? ": ${widget.chapter.title}" : ""}',
                          style: TextStyle(
                            color: _hovered
                                ? _kOrange
                                : Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isLatest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kOrange, _kRed],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LATEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(widget.chapter.publishedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: _hovered ? _kOrange : Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AboutTab extends StatelessWidget {
  final MangaEntity manga;
  final int chapterCount;

  const _AboutTab({required this.manga, required this.chapterCount});

  @override
  Widget build(BuildContext context) {
    final details = [
      ('Author', manga.author.isNotEmpty ? manga.author : 'N/A'),
      ('Artist', manga.artist.isNotEmpty ? manga.artist : 'N/A'),
      ('Status', manga.status),
      ('Year', manga.year?.toString() ?? 'N/A'),
      ('Chapters', chapterCount.toString()),
      (
        'Rating',
        manga.rating > 0 ? '${manga.rating.toStringAsFixed(1)} / 10' : 'N/A',
      ),
      ('Source', 'MangaDex'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          _Card(
            label: 'SYNOPSIS',
            child: Text(
              manga.description.isNotEmpty
                  ? manga.description
                  : 'No description available.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.8,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 12),

          _Card(
            label: 'DETAILS',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: details
                  .map(
                    (d) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 80) / 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.025),
                          border: Border.all(color: _kBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.$1.toUpperCase(),
                              style: TextStyle(
                                color: _kOrange.withValues(alpha: 0.5),
                                fontSize: 8,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.$2,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          if (manga.genre.isNotEmpty)
            _Card(
              label: 'GENRES',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: manga.genre
                    .map(
                      (g) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          g.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 9,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String label;
  final Widget child;
  const _Card({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 16, height: 2, color: _kOrange),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _kOrange.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COVER IMAGE
// ─────────────────────────────────────────────────────────────────────────────
class _CoverImage extends StatefulWidget {
  final String src;
  final String title;
  final double width;
  const _CoverImage({
    required this.src,
    required this.title,
    required this.width,
  });

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  bool _err = false;

  static const _gradients = [
    [Color(0xFF2a0a0a), Color(0xFF1a0a1a)],
    [Color(0xFF0a1a2a), Color(0xFF0a0a2a)],
    [Color(0xFF1a0a2e), Color(0xFF0d1a3a)],
    [Color(0xFF0a2a1a), Color(0xFF0a1a0a)],
    [Color(0xFF2a1a0a), Color(0xFF1a0a0a)],
  ];

  @override
  Widget build(BuildContext context) {
    final h = (widget.width / 2 * 3).roundToDouble();
    return Container(
      width: widget.width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOrange.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.src.isNotEmpty && !_err
          ? Image.network(
              widget.src,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => setState(() => _err = true),
                );
                return _fallback();
              },
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    final colors = _gradients[widget.title.codeUnitAt(0) % _gradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text(
          '📕',
          style: TextStyle(fontSize: 32, color: Colors.white10),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE CHIPS
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 8,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusBg(status),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 8,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER
// ─────────────────────────────────────────────────────────────────────────────
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING / ERROR SCREENS
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
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: _kOrange, strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text(
              'Loading…',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

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
                'Failed to Load',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
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
                  ),
                  child: const Text(
                    'Back to Browse',
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
