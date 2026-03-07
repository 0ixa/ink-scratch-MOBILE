// test/features/manga/presentation/viewmodel/manga_browse_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:ink_scratch/features/manga/domain/entities/manga_entity.dart';
import 'package:ink_scratch/features/manga/domain/repositories/manga_repository.dart';
import 'package:ink_scratch/features/manga/presentation/state/manga_browse_state.dart';
import 'package:ink_scratch/features/manga/presentation/viewmodel/manga_browse_viewmodel.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class FakeMangaRepository implements MangaRepository {
  MangaListResult result = MangaListResult(
    items: [],
    page: 1,
    limit: 24,
    total: 0,
    pages: 1,
  );
  List<MangaEntity> searchResults = [];
  bool shouldThrow = false;

  @override
  Future<MangaListResult> getAll({
    int page = 1,
    int limit = 24,
    String? genre,
    String? status,
    String? sort,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    return result;
  }

  @override
  Future<List<MangaEntity>> search(String query) async {
    if (shouldThrow) throw Exception('Search failed');
    return searchResults;
  }

  @override
  Future<MangaEntity> getById(String id) async => _manga('m0', 'Test');

  @override
  Future<List<ChapterEntity>> getChapters(String mangaId) async => [];

  @override
  Future<List<ChapterPageEntity>> getChapterPages(String chapterId) async => [];
}

// ── Fixture ───────────────────────────────────────────────────────────────────

final _now = DateTime(2024, 1, 1);

MangaEntity _manga(String id, String title) => MangaEntity(
  id: id,
  title: title,
  alternativeTitles: const [],
  author: 'Author',
  artist: 'Artist',
  description: 'A description',
  genre: const ['Action'],
  status: 'Ongoing',
  coverImage: 'https://example.com/cover.jpg',
  rating: 4.5,
  totalChapters: 10,
  source: 'source',
  sourceId: 'src-$id',
  createdAt: _now,
  updatedAt: _now,
);

MangaBrowseViewModel _buildVM(FakeMangaRepository repo) =>
    MangaBrowseViewModel(repository: repo);

// ══════════════════════════════════════════════════════════════════════════════
void main() {
  late FakeMangaRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeMangaRepository();
  });

  // ── MangaBrowseState — 3 tests ────────────────────────────────────────────
  group('MangaBrowseState — defaults', () {
    test('1. initial state has sensible defaults', () {
      const s = MangaBrowseState();
      expect(s.isLoading, isFalse);
      expect(s.isSearching, isFalse);
      expect(s.items, isEmpty);
      expect(s.query, '');
      expect(s.activeGenre, 'All');
      expect(s.activeStatus, 'All');
      expect(s.sortBy, 'rating');
      expect(s.page, 1);
    });

    test('2. copyWith(clearError: true) removes existing error', () {
      const s = MangaBrowseState(error: 'oops');
      final cleared = s.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('3. copyWith without clearError preserves existing error', () {
      const s = MangaBrowseState(error: 'still here');
      final copy = s.copyWith(isLoading: true);
      expect(copy.error, 'still here');
    });
  });

  // ── MangaBrowseViewModel — fetchManga ─────────────────────────────────────
  group('MangaBrowseViewModel — fetchManga', () {
    test(
      '4. constructor triggers fetchManga and populates items on success',
      () async {
        fakeRepo.result = MangaListResult(
          items: [_manga('m1', 'Naruto'), _manga('m2', 'Bleach')],
          page: 1,
          limit: 24,
          total: 72,
          pages: 3,
        );

        final vm = _buildVM(fakeRepo);
        await Future.microtask(() {});

        expect(vm.state.items.length, 2);
        expect(vm.state.isLoading, isFalse);
        expect(vm.state.totalPages, 3);
        expect(vm.state.total, 72);
      },
    );

    test('5. fetchManga sets error state when repository throws', () async {
      fakeRepo.shouldThrow = true;
      final vm = _buildVM(fakeRepo);
      await Future.microtask(() {});

      expect(vm.state.error, isNotNull);
      expect(vm.state.isLoading, isFalse);
      expect(vm.state.items, isEmpty);
    });
  });

  // ── MangaBrowseViewModel — filters & pagination ───────────────────────────
  group('MangaBrowseViewModel — filters & pagination', () {
    test('6. setGenre updates activeGenre and resets page to 1', () async {
      final vm = _buildVM(fakeRepo);
      await Future.microtask(() {});

      vm.setGenre('Action');

      expect(vm.state.activeGenre, 'Action');
      expect(vm.state.page, 1);
    });

    test('7. setStatus updates activeStatus and resets page to 1', () async {
      final vm = _buildVM(fakeRepo);
      await Future.microtask(() {});

      vm.setStatus('Completed');

      expect(vm.state.activeStatus, 'Completed');
      expect(vm.state.page, 1);
    });

    test('8. setSortBy updates sortBy and resets page to 1', () async {
      final vm = _buildVM(fakeRepo);
      await Future.microtask(() {});

      vm.setSortBy('latest');

      expect(vm.state.sortBy, 'latest');
      expect(vm.state.page, 1);
    });

    test('9. setPage changes current page', () async {
      fakeRepo.result = MangaListResult(
        items: [_manga('m3', 'One Piece')],
        page: 1,
        limit: 24,
        total: 100,
        pages: 5,
      );
      final vm = _buildVM(fakeRepo);
      await Future.microtask(() {});

      vm.setPage(3);
      await Future.microtask(() {});

      expect(vm.state.page, 3);
    });

    test(
      '10. clearFilters resets genre, status, query and page to defaults',
      () async {
        final vm = _buildVM(fakeRepo);
        await Future.microtask(() {});

        vm.setGenre('Horror');
        vm.setStatus('Completed');
        vm.clearFilters();

        expect(vm.state.activeGenre, 'All');
        expect(vm.state.activeStatus, 'All');
        expect(vm.state.query, '');
        expect(vm.state.page, 1);
      },
    );
  });
}
