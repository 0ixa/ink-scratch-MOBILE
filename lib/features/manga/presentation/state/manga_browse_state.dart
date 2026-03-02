// lib/features/manga/presentation/state/manga_browse_state.dart

import '../../domain/entities/manga_entity.dart';

class MangaBrowseState {
  final List<MangaEntity> items;
  final bool isLoading;
  final bool isSearching;
  final String? error;
  final String query;
  final String activeGenre;
  final String activeStatus;
  final String sortBy;
  final int page;
  final int totalPages;
  final int total;

  const MangaBrowseState({
    this.items = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
    this.query = '',
    this.activeGenre = 'All',
    this.activeStatus = 'All',
    this.sortBy = 'rating',
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  MangaBrowseState copyWith({
    List<MangaEntity>? items,
    bool? isLoading,
    bool? isSearching,
    String? error,
    String? query,
    String? activeGenre,
    String? activeStatus,
    String? sortBy,
    int? page,
    int? totalPages,
    int? total,
    bool clearError = false,
  }) {
    return MangaBrowseState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
      activeGenre: activeGenre ?? this.activeGenre,
      activeStatus: activeStatus ?? this.activeStatus,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
    );
  }
}
