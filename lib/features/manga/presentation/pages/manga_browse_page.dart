// lib/features/manga/presentation/pages/manga_browse_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/manga_entity.dart';
import '../viewmodel/manga_browse_viewmodel.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kRed = Color(0xFFE63946);
const _kInk = Color(0xFF0A0A0F);
const _kInk2 = Color(0xFF16161F);

const _allGenres = [
  'All',
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Fantasy',
  'Horror',
  'Romance',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Supernatural',
];

const _allStatuses = ['All', 'Ongoing', 'Completed', 'Hiatus', 'Cancelled'];

const _sortOptions = [
  ('rating', 'Top Rated'),
  ('latest', 'Latest'),
  ('chapters', 'Most Chapters'),
  ('title', 'A → Z'),
];

// ── Status color helpers ──────────────────────────────────────────────────────
Color _statusColor(String status) {
  switch (status) {
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

Color _statusBg(String status) {
  switch (status) {
    case 'Ongoing':
      return const Color(0xFF4ADE80).withValues(alpha: 0.15);
    case 'Completed':
      return const Color(0xFF60A5FA).withValues(alpha: 0.15);
    case 'Cancelled':
      return const Color(0xFFF87171).withValues(alpha: 0.15);
    default:
      return const Color(0xFFFBBF24).withValues(alpha: 0.15);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────
class MangaBrowsePage extends ConsumerStatefulWidget {
  const MangaBrowsePage({super.key});

  @override
  ConsumerState<MangaBrowsePage> createState() => _MangaBrowsePageState();
}

class _MangaBrowsePageState extends ConsumerState<MangaBrowsePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showFilters = false;
  String _sortBy = 'rating';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mangaBrowseViewModelProvider);
    final vm = ref.read(mangaBrowseViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: _kInk,
      body: Stack(
        children: [
          _BackgroundGlow(),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _HeroAppBar(
                total: state.total,
                searchController: _searchController,
                isLoading: state.isLoading || state.isSearching,
                onSearchChanged: vm.onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  vm.onSearchChanged('');
                },
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(
                  activeGenre: state.activeGenre,
                  activeStatus: state.activeStatus,
                  sortBy: _sortBy,
                  showFilters: _showFilters,
                  onGenreSelected: vm.setGenre,
                  onStatusSelected: vm.setStatus,
                  onSortChanged: (s) {
                    setState(() => _sortBy = s);
                    vm.setSortBy(s);
                  },
                  onToggleFilters: () =>
                      setState(() => _showFilters = !_showFilters),
                ),
              ),
              SliverToBoxAdapter(
                child: _ResultsMeta(
                  total: state.total,
                  query: state.query,
                  isLoading: state.isLoading || state.isSearching,
                  hasFilters:
                      state.activeGenre != 'All' ||
                      state.activeStatus != 'All' ||
                      state.query.isNotEmpty,
                  onClearAll: () {
                    _searchController.clear();
                    vm.clearFilters();
                  },
                ),
              ),
              if (state.error != null)
                SliverFillRemaining(
                  child: _ErrorState(
                    message: state.error!,
                    onRetry: vm.fetchManga,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: state.isLoading
                      ? _SkeletonGrid()
                      : state.items.isEmpty
                      ? SliverToBoxAdapter(
                          child: _EmptyState(
                            onClear: () {
                              _searchController.clear();
                              vm.clearFilters();
                            },
                          ),
                        )
                      : _MangaGrid(items: state.items),
                ),
                if (!state.isLoading &&
                    state.query.isEmpty &&
                    state.totalPages > 1)
                  SliverToBoxAdapter(
                    child: _Pagination(
                      page: state.page,
                      totalPages: state.totalPages,
                      onPageChanged: vm.setPage,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND GLOW
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_kOrange.withValues(alpha: 0.18), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_kRed.withValues(alpha: 0.12), Colors.transparent],
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.025,
          child: SizedBox.expand(
            child: CustomPaint(painter: _HalftonePainter()),
          ),
        ),
      ],
    );
  }
}

class _HalftonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kOrange;
    const spacing = 24.0;
    const radius = 1.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _HeroAppBar extends StatelessWidget {
  final int total;
  final TextEditingController searchController;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _HeroAppBar({
    required this.total,
    required this.searchController,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 20,
          20,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '›',
                    style: TextStyle(
                      color: _kOrange.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  'Browse',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 20, height: 2, color: _kOrange),
                const SizedBox(width: 10),
                Text(
                  'THE LIBRARY — ALL TITLES',
                  style: TextStyle(
                    color: _kOrange.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, _kOrange, _kRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Browse Manga',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              total > 0
                  ? '$total titles in the library'
                  : 'Discover manga across every genre',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by title or author…',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _kOrange.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  suffixIcon: searchController.text.isNotEmpty || isLoading
                      ? GestureDetector(
                          onTap: onClear,
                          child: Icon(
                            isLoading
                                ? Icons.sync_rounded
                                : Icons.close_rounded,
                            color: Colors.white38,
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR (sticky)
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final String activeGenre;
  final String activeStatus;
  final String sortBy;
  final bool showFilters;
  final ValueChanged<String> onGenreSelected;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onToggleFilters;

  _FilterBarDelegate({
    required this.activeGenre,
    required this.activeStatus,
    required this.sortBy,
    required this.showFilters,
    required this.onGenreSelected,
    required this.onStatusSelected,
    required this.onSortChanged,
    required this.onToggleFilters,
  });

  int get _activeFilterCount =>
      (activeGenre != 'All' ? 1 : 0) + (activeStatus != 'All' ? 1 : 0);

  @override
  double get minExtent => showFilters ? 120 : 52;
  @override
  double get maxExtent => showFilters ? 120 : 52;
  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) => true;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: _kInk.withValues(alpha: 0.95),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: _allGenres
                          .map(
                            (g) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _GenrePill(
                                label: g,
                                active: activeGenre == g,
                                onTap: () => onGenreSelected(g),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggleFilters,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: showFilters || _activeFilterCount > 0
                            ? _kOrange.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: showFilters || _activeFilterCount > 0
                          ? _kOrange.withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: showFilters || _activeFilterCount > 0
                              ? _kOrange
                              : Colors.white38,
                        ),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: _kOrange,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$_activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showFilters)
            Container(
              height: 68,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'STATUS:',
                            style: TextStyle(
                              color: _kOrange.withValues(alpha: 0.5),
                              fontSize: 9,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ..._allStatuses.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _StatusPill(
                                label: s,
                                active: activeStatus == s,
                                onTap: () => onStatusSelected(s),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: sortBy,
                        isDense: true,
                        dropdownColor: _kInk2,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                        items: _sortOptions
                            .map(
                              (o) => DropdownMenuItem(
                                value: o.$1,
                                child: Text(o.$2),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onSortChanged(v);
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: Colors.white38,
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// PILLS
// ─────────────────────────────────────────────────────────────────────────────
class _GenrePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _GenrePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [_kOrange, _kRed])
              : null,
          color: active ? null : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.07),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontFamily: 'monospace',
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULTS META ROW
// ─────────────────────────────────────────────────────────────────────────────
class _ResultsMeta extends StatelessWidget {
  final int total;
  final String query;
  final bool isLoading;
  final bool hasFilters;
  final VoidCallback onClearAll;

  const _ResultsMeta({
    required this.total,
    required this.query,
    required this.isLoading,
    required this.hasFilters,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: isLoading
                ? Text(
                    'Loading…',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      children: [
                        TextSpan(
                          text: '$total',
                          style: const TextStyle(
                            color: _kOrange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(text: ' titles'),
                        if (query.isNotEmpty)
                          TextSpan(
                            text: ' for "$query"',
                            style: TextStyle(
                              color: _kOrange.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          if (hasFilters)
            GestureDetector(
              onTap: onClearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _kRed.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Clear All ×',
                  style: TextStyle(
                    color: _kRed,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANGA GRID
// ─────────────────────────────────────────────────────────────────────────────
class _MangaGrid extends StatelessWidget {
  final List<MangaEntity> items;
  const _MangaGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _MangaCard(manga: items[index]),
        childCount: items.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANGA CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MangaCard extends StatelessWidget {
  final MangaEntity manga;
  const _MangaCard({required this.manga});

  Color _coverFallback() {
    const colors = [
      Color(0xFF2A0A0A),
      Color(0xFF0A1A2A),
      Color(0xFF1A0A2E),
      Color(0xFF0A2A1A),
      Color(0xFF2A1A0A),
      Color(0xFF1A1A0A),
    ];
    return colors[manga.title.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to manga detail — context.push('/manga/${manga.id}')
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  manga.coverImage.isNotEmpty
                      ? Image.network(
                          manga.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _FallbackCover(color: _coverFallback()),
                        )
                      : _FallbackCover(color: _coverFallback()),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(manga.status),
                        border: Border.all(
                          color: _statusColor(
                            manga.status,
                          ).withValues(alpha: 0.25),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        manga.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(manga.status),
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  if (manga.rating > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFF4D03F,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '★',
                              style: TextStyle(
                                color: Color(0xFFF4D03F),
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              manga.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 5),
                      child: Text(
                        '${manga.totalChapters} ch.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            manga.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            manga.author,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.28),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (manga.genre.isNotEmpty) ...[
            const SizedBox(height: 5),
            Wrap(
              spacing: 4,
              runSpacing: 3,
              children: manga.genre
                  .take(2)
                  .map(
                    (g) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        g.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 7,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  final Color color;
  const _FallbackCover({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 32,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON GRID
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Column(
          children: [
            Expanded(
              child: _Shimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _Shimmer(
              child: Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _Shimmer(
              child: Container(
                height: 8,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        childCount: 24,
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _animation, child: widget.child);
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No Results Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Text(
                'Clear Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Manga',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Text(
                  'Try Again',
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGINATION
// ─────────────────────────────────────────────────────────────────────────────
class _Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  List<int> get _visiblePages {
    final start = (page - 2).clamp(1, (totalPages - 4).clamp(1, totalPages));
    final end = (start + 4).clamp(1, totalPages);
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageBtn(
            label: '← Prev',
            enabled: page > 1,
            onTap: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 8),
          ..._visiblePages.map(
            (p) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onPageChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: p == page
                        ? const LinearGradient(colors: [_kOrange, _kRed])
                        : null,
                    color: p == page
                        ? null
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: p == page
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.07),
                    ),
                    boxShadow: p == page
                        ? [
                            BoxShadow(
                              color: _kOrange.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$p',
                    style: TextStyle(
                      color: p == page
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _PageBtn(
            label: 'Next →',
            enabled: page < totalPages,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _PageBtn({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
            fontSize: 11,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
