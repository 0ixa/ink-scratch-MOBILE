// lib/features/dashboard/presentation/pages/library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../manga/data/providers/manga_providers.dart';
import '../../../manga/domain/entities/library_manga.dart';
import '../../../../core/utils/navigation_utils.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kRed = Color(0xFFE63946);
const _kInk = Color(0xFF0A0A0F);
const _kCard = Color(0xFF111118);
const _kBorder = Color(0x10FFFFFF);

Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'ongoing':
      return const Color(0xFF4ADE80);
    case 'completed':
      return const Color(0xFF60A5FA);
    case 'cancelled':
      return const Color(0xFFF87171);
    default:
      return const Color(0xFFFBBF24);
  }
}

String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  if (diff < 30) return '${diff ~/ 7}w ago';
  if (diff < 365) return '${diff ~/ 30}mo ago';
  return '${diff ~/ 365}y ago';
}

enum _Filter { all, ongoing, completed, cancelled }

enum _Sort { addedAt, title, rating }

// ─────────────────────────────────────────────────────────────────────────────
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.addedAt;
  bool _isGrid = true;
  String _query = '';

  String? _removeId;
  bool _removing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doRemove(String mangaId) async {
    setState(() => _removing = true);
    await ref.read(libraryProvider.notifier).remove(mangaId);
    setState(() {
      _removeId = null;
      _removing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(libraryProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _kInk,
          body: Stack(
            children: [
              Positioned(
                top: -80,
                left: -60,
                child: _glow(_kOrange, 320, 0.15),
              ),
              Positioned(
                bottom: 80,
                right: -60,
                child: _glow(_kRed, 260, 0.10),
              ),
              Opacity(
                opacity: 0.025,
                child: SizedBox.expand(
                  child: CustomPaint(painter: _DotPainter()),
                ),
              ),

              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _LibAppBar(
                    isGrid: _isGrid,
                    onToggleView: () => setState(() => _isGrid = !_isGrid),
                  ),

                  // Hero + stats
                  SliverToBoxAdapter(
                    child: libraryAsync.when(
                      loading: () => const SizedBox(height: 120),
                      error: (e, s) => const SizedBox.shrink(),
                      data: (library) => _HeroStats(library: library),
                    ),
                  ),

                  // Search + filters + sort
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Column(
                        children: [
                          // Search bar
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search your library…',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  size: 20,
                                ),
                                suffixIcon: _query.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchCtrl.clear();
                                          setState(() => _query = '');
                                        },
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          size: 18,
                                        ),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Filter pills + sort in one scrollable row
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                // Filter pills
                                ..._Filter.values.map((f) {
                                  const labels = {
                                    _Filter.all: 'All',
                                    _Filter.ongoing: 'Ongoing',
                                    _Filter.completed: 'Completed',
                                    _Filter.cancelled: 'Cancelled',
                                  };
                                  final active = _filter == f;
                                  return GestureDetector(
                                    onTap: () => setState(() => _filter = f),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? _kOrange.withValues(alpha: 0.12)
                                            : Colors.white.withValues(
                                                alpha: 0.04,
                                              ),
                                        border: Border.all(
                                          color: active
                                              ? _kOrange.withValues(alpha: 0.4)
                                              : Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        labels[f]!,
                                        style: TextStyle(
                                          color: active
                                              ? _kOrange
                                              : Colors.white.withValues(
                                                  alpha: 0.4,
                                                ),
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: active
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                // Sort pill
                                GestureDetector(
                                  onTap: () => _showSortSheet(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.sort_rounded,
                                          size: 13,
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _sortLabel(_sort),
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 48),
                    sliver: libraryAsync.when(
                      loading: () =>
                          SliverToBoxAdapter(child: _buildSkeleton()),
                      error: (e, s) => SliverToBoxAdapter(
                        child: _ErrorBox(message: e.toString()),
                      ),
                      data: (library) {
                        if (library.isEmpty)
                          return SliverToBoxAdapter(child: _EmptyLibrary());
                        final filtered = _applyFilters(library);
                        if (filtered.isEmpty)
                          return SliverToBoxAdapter(
                            child: _NoResults(
                              onClear: () => setState(() {
                                _query = '';
                                _searchCtrl.clear();
                                _filter = _Filter.all;
                              }),
                            ),
                          );
                        return _isGrid
                            ? _buildGrid(filtered)
                            : _buildList(filtered);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_removeId != null)
          _RemoveModal(
            mangaId: _removeId!,
            library: ref.watch(libraryProvider).valueOrNull ?? [],
            removing: _removing,
            onConfirm: () => _doRemove(_removeId!),
            onCancel: () => setState(() => _removeId = null),
          ),
      ],
    );
  }

  List<LibraryManga> _applyFilters(List<LibraryManga> library) {
    return library.where((m) {
      final q = _query.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.author.toLowerCase().contains(q);
      final matchFilter =
          _filter == _Filter.all || m.status.toLowerCase() == _filter.name;
      return matchSearch && matchFilter;
    }).toList()..sort((a, b) {
      switch (_sort) {
        case _Sort.title:
          return a.title.compareTo(b.title);
        case _Sort.rating:
          return b.rating.compareTo(a.rating);
        case _Sort.addedAt:
          return (b.addedAt ?? DateTime.now()).compareTo(
            a.addedAt ?? DateTime.now(),
          );
      }
    });
  }

  // ✅ FIX: 2 columns instead of 3 — much more readable on mobile
  SliverGrid _buildGrid(List<LibraryManga> items) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => _GridCard(
          item: items[i],
          onTap: () => AppNavigator.toMangaDetail(context, items[i].mangaId),
          onRemove: () => setState(() => _removeId = items[i].mangaId),
        ),
        childCount: items.length,
      ),
    );
  }

  SliverList _buildList(List<LibraryManga> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ListRow(
            item: items[i],
            onTap: () => AppNavigator.toMangaDetail(context, items[i].mangaId),
            onRemove: () => setState(() => _removeId = items[i].mangaId),
          ),
        ),
        childCount: items.length,
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // ✅ FIX: match the 2-col layout for skeleton too
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  String _sortLabel(_Sort s) {
    switch (s) {
      case _Sort.addedAt:
        return 'Recent';
      case _Sort.title:
        return 'A–Z';
      case _Sort.rating:
        return 'Rating';
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort by',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._Sort.values.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _sortLabel(s),
                  style: TextStyle(
                    color: _sort == s
                        ? _kOrange
                        : Colors.white.withValues(alpha: 0.7),
                    fontWeight: _sort == s ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: _sort == s
                    ? const Icon(Icons.check_rounded, color: _kOrange, size: 18)
                    : null,
                onTap: () {
                  setState(() => _sort = s);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color c, double sz, double op) => Container(
    width: sz,
    height: sz,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          c.withValues(alpha: op),
          Colors.transparent,
        ],
      ),
    ),
  );
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _LibAppBar extends StatelessWidget {
  final bool isGrid;
  final VoidCallback onToggleView;
  const _LibAppBar({required this.isGrid, required this.onToggleView});

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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
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
                    'MY LIBRARY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onToggleView,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _kOrange.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isGrid
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: _kOrange,
                      size: 18,
                    ),
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

// ── Hero + Stats Bar ──────────────────────────────────────────────────────────
class _HeroStats extends StatelessWidget {
  final List<LibraryManga> library;
  const _HeroStats({required this.library});

  @override
  Widget build(BuildContext context) {
    final ongoingCount = library
        .where((m) => m.status.toLowerCase() == 'ongoing')
        .length;
    final completedCount = library
        .where((m) => m.status.toLowerCase() == 'completed')
        .length;
    final avgRating = library.isEmpty
        ? 0.0
        : library.fold<double>(0, (s, m) => s + m.rating) / library.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 20, height: 2, color: _kOrange),
                  const SizedBox(width: 8),
                  Text(
                    'MY LIBRARY',
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
              const Text(
                'My Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${library.length} series saved · your personal reading list',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        // Stats row — 4 equal columns
        Container(
          decoration: const BoxDecoration(
            color: Color(0x4C000000),
            border: Border.symmetric(horizontal: BorderSide(color: _kBorder)),
          ),
          child: Row(
            children: [
              _Stat(label: 'Total', value: '${library.length}', isFirst: true),
              _Stat(label: 'Ongoing', value: '$ongoingCount'),
              _Stat(label: 'Completed', value: '$completedCount'),
              _Stat(
                label: 'Avg ★',
                value: library.isEmpty ? '—' : avgRating.toStringAsFixed(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final bool isFirst;
  const _Stat({required this.label, required this.value, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            left: isFirst ? BorderSide.none : const BorderSide(color: _kBorder),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 8,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid card — 2 column, mobile friendly ────────────────────────────────────
class _GridCard extends StatefulWidget {
  final LibraryManga item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _GridCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> {
  bool _showRemove = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.item;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => setState(() => _showRemove = !_showRemove),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover — taller for 2-col layout
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Cover(src: m.coverImage, title: m.title),
                  // Gradient overlay at bottom
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xCC000000), Colors.transparent],
                          stops: [0.0, 0.45],
                        ),
                      ),
                    ),
                  ),
                  // Remove button (long-press)
                  if (_showRemove)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: widget.onRemove,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xD9EF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              '✕',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Status badge bottom-left
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(m.status).withValues(alpha: 0.2),
                        border: Border.all(
                          color: _statusColor(m.status).withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        m.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(m.status),
                          fontSize: 8,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Rating badge bottom-right
                  if (m.rating > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '★ ${m.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Color(0xFFF4D03F),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            m.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          // Author + time
          Row(
            children: [
              Expanded(
                child: Text(
                  m.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                _timeAgo(m.addedAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          // Long-press hint (shown when remove overlay is visible)
          if (_showRemove)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tap ✕ to remove',
                style: TextStyle(
                  color: _kRed.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── List row — bigger cover, swipe-friendly ───────────────────────────────────
class _ListRow extends StatelessWidget {
  final LibraryManga item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _ListRow({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final m = item;
    final genres = m.genre.take(2).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.025),
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ FIX: bigger cover — 64×88 instead of 48×64
            Container(
              width: 64,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kOrange.withValues(alpha: 0.15)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _Cover(src: m.coverImage, title: m.title),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by ${m.author}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(m.status).withValues(alpha: 0.15),
                          border: Border.all(
                            color: _statusColor(
                              m.status,
                            ).withValues(alpha: 0.35),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          m.status.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(m.status),
                            fontSize: 8,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Genres
                      ...genres.map(
                        (g) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            g.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 8,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bottom row: time + remove button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _timeAgo(m.addedAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x14EF4444),
                            border: Border.all(color: const Color(0x33EF4444)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✕ Remove',
                            style: TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }
}

// ── Remove Confirmation Modal ─────────────────────────────────────────────────
class _RemoveModal extends StatelessWidget {
  final String mangaId;
  final List<LibraryManga> library;
  final bool removing;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _RemoveModal({
    required this.mangaId,
    required this.library,
    required this.removing,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final LibraryManga? m = library.cast<LibraryManga?>().firstWhere(
      (x) => x?.mangaId == mangaId,
      orElse: () => null,
    );

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onCancel,
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kCard,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 60),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _kOrange.withValues(alpha: 0.15),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _Cover(src: m.coverImage, title: m.title),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    m.author,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0x1AEF4444),
                        border: Border.all(color: const Color(0x33EF4444)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🗑️', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Remove from Library?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can always re-add it later from the manga page.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: removing ? null : onConfirm,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFDC2626),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: removing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: onCancel,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Keep It',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error / No-results ────────────────────────────────────────────────
class _EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('📚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Your Library is Empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse manga and hit + Add to Library on any title to save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final VoidCallback onClear;
  const _NoResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          const Text(
            'No Results',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Clear Filters',
              style: TextStyle(
                color: _kOrange,
                fontSize: 12,
                fontFamily: 'monospace',
                decoration: TextDecoration.underline,
                decorationColor: _kOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AE63946),
        border: Border.all(color: const Color(0x4DE63946)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Failed to load library',
        style: TextStyle(color: Color(0xFFF87171), fontSize: 13),
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
    if (widget.title.isEmpty) return Container(color: const Color(0xFF111118));
    final c = _gradients[widget.title.codeUnitAt(0) % _gradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c,
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
              style: TextStyle(fontSize: 22, color: Colors.white10),
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _DiagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _kOrange.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 61) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
