// lib/features/manga/presentation/view_model/manga_browse_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/manga_repository.dart';
import '../../data/providers/manga_providers.dart';
import '../state/manga_browse_state.dart';

class MangaBrowseViewModel extends StateNotifier<MangaBrowseState> {
  final MangaRepository _repository;
  Timer? _debounce;

  MangaBrowseViewModel({required MangaRepository repository})
    : _repository = repository,
      super(const MangaBrowseState()) {
    fetchManga();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchManga() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getAll(
        page: state.page,
        limit: 24,
        genre: state.activeGenre,
        status: state.activeStatus,
        sort: state.sortBy,
      );
      state = state.copyWith(
        items: result.items,
        totalPages: result.pages,
        total: result.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  void onSearchChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      fetchManga();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      state = state.copyWith(isSearching: true, clearError: true);
      try {
        final results = await _repository.search(query.trim());
        state = state.copyWith(
          items: results,
          totalPages: 1,
          total: results.length,
          isSearching: false,
        );
      } catch (e) {
        state = state.copyWith(
          isSearching: false,
          error: e.toString().replaceAll('Exception:', '').trim(),
        );
      }
    });
  }

  void setGenre(String genre) {
    if (genre == state.activeGenre) return;
    state = state.copyWith(activeGenre: genre, page: 1);
    fetchManga();
  }

  void setStatus(String status) {
    if (status == state.activeStatus) return;
    state = state.copyWith(activeStatus: status, page: 1);
    fetchManga();
  }

  void setSortBy(String sort) {
    if (sort == state.sortBy) return;
    state = state.copyWith(sortBy: sort, page: 1);
    fetchManga();
  }

  void setPage(int page) {
    if (page == state.page) return;
    state = state.copyWith(page: page);
    fetchManga();
  }

  void clearFilters() {
    state = state.copyWith(
      query: '',
      activeGenre: 'All',
      activeStatus: 'All',
      page: 1,
    );
    fetchManga();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final mangaBrowseViewModelProvider =
    StateNotifierProvider<MangaBrowseViewModel, MangaBrowseState>((ref) {
      final repo = ref.watch(mangaRepositoryProvider);
      return MangaBrowseViewModel(repository: repo);
    });
