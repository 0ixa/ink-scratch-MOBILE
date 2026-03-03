// lib/features/manga/data/providers/manga_providers.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_client_provider.dart';
import '../../../../core/services/storage/user_session_service.dart';
import '../datasources/manga_remote_datasource.dart';
import '../repositories/manga_repository_impl.dart';
import '../services/reading_history_service_impl.dart';
import '../services/library_service_impl.dart';
import '../../domain/repositories/manga_repository.dart';
import '../../domain/services/reading_history_service.dart';
import '../../domain/services/library_service.dart';
import '../../domain/entities/reading_history_entry.dart';
import '../../domain/entities/library_manga.dart';

// ── Helper: Dio options with Bearer token ─────────────────────────────────────
Options _authOptions(String token) =>
    Options(headers: {'Authorization': 'Bearer $token'});

// ── Datasource ────────────────────────────────────────────────────────────────
final mangaRemoteDatasourceProvider = Provider<MangaRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MangaRemoteDatasourceImpl(dio: apiClient.client);
});

// ── Repository ────────────────────────────────────────────────────────────────
final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  final datasource = ref.watch(mangaRemoteDatasourceProvider);
  return MangaRepositoryImpl(remote: datasource);
});

// ── Local Services (Hive) ─────────────────────────────────────────────────────
final readingHistoryServiceProvider = FutureProvider<ReadingHistoryService>((
  ref,
) async {
  final dio = ref.watch(apiClientProvider).client;
  final service = ReadingHistoryServiceImpl(dio: dio);
  await service.init();
  return service;
});

final libraryServiceProvider = FutureProvider<LibraryService>((ref) async {
  final service = LibraryServiceImpl();
  await service.init();
  return service;
});

// ── Session service ───────────────────────────────────────────────────────────
final _sessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService();
});

// ── Manga List Provider ───────────────────────────────────────────────────────
final mangaListProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(mangaRepositoryProvider);
  final result = await repository.getAll();
  return result.items;
});

// ── Reading History Provider ──────────────────────────────────────────────────
final readingHistoryProvider =
    FutureProvider.autoDispose<List<ReadingHistoryEntry>>((ref) async {
      final apiClient = ref.watch(apiClientProvider);
      final session = ref.watch(_sessionServiceProvider);
      final token = await session.getToken();

      if (token == null || token.isEmpty) {
        final service = ref.watch(readingHistoryServiceProvider).valueOrNull;
        if (service == null) return [];
        return service.getAll();
      }

      try {
        final response = await apiClient.client.get(
          '/history',
          options: _authOptions(token),
        );
        final data = response.data;
        final List<dynamic> list = data is Map
            ? (data['data'] ?? data['history'] ?? [])
            : (data ?? []);

        return list
            .map(
              (item) => ReadingHistoryEntry(
                id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
                mangaId: item['mangaId']?.toString() ?? '',
                title: item['title']?.toString() ?? '',
                author: item['author']?.toString() ?? '',
                coverImage: item['coverImage']?.toString(),
                chapterNumber: item['chapterNumber'] as int?,
                chapterTitle: item['chapterTitle']?.toString(),
                progress: ((item['progress'] ?? 0) as num).toDouble(),
                lastReadAt: item['lastReadAt'] != null
                    ? DateTime.tryParse(item['lastReadAt'].toString())
                    : null,
                createdAt: item['createdAt'] != null
                    ? DateTime.tryParse(item['createdAt'].toString())
                    : null,
              ),
            )
            .toList();
      } catch (e, s) {
        // ignore: avoid_print
        print('readingHistoryProvider error: $e\n$s');
        final service = ref.watch(readingHistoryServiceProvider).valueOrNull;
        if (service == null) return [];
        return service.getAll();
      }
    });

// ── Library Notifier ──────────────────────────────────────────────────────────
class LibraryNotifier extends AsyncNotifier<List<LibraryManga>> {
  @override
  Future<List<LibraryManga>> build() async {
    return _fetchFromBackend();
  }

  Future<List<LibraryManga>> _fetchFromBackend() async {
    final apiClient = ref.read(apiClientProvider);
    final session = ref.read(_sessionServiceProvider);
    final token = await session.getToken();

    if (token == null || token.isEmpty) {
      return _fetchFromLocal();
    }

    try {
      final response = await apiClient.client.get(
        '/library',
        options: _authOptions(token),
      );
      final data = response.data;
      final List<dynamic> list = data is Map
          ? (data['data'] ?? data['library'] ?? [])
          : (data ?? []);

      return list.map((item) {
        final mangaData = item['manga'] ?? item;
        return LibraryManga(
          id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
          mangaId:
              mangaData['_id']?.toString() ??
              mangaData['id']?.toString() ??
              item['mangaId']?.toString() ??
              '',
          title: mangaData['title']?.toString() ?? '',
          author: mangaData['author']?.toString() ?? '',
          coverImage: mangaData['coverImage']?.toString(),
          status: mangaData['status']?.toString() ?? 'Unknown',
          genre: List<String>.from(
            mangaData['genre'] ?? mangaData['genres'] ?? [],
          ),
          rating: ((mangaData['rating'] ?? 0) as num).toDouble(),
          addedAt: item['createdAt'] != null
              ? DateTime.tryParse(item['createdAt'].toString())
              : null,
        );
      }).toList();
    } catch (e, s) {
      // ignore: avoid_print
      print('LibraryNotifier fetch error: $e\n$s');
      return _fetchFromLocal();
    }
  }

  Future<List<LibraryManga>> _fetchFromLocal() async {
    final service = ref.read(libraryServiceProvider).valueOrNull;
    if (service == null) return [];
    return service.getAll();
  }

  // ── FIXED: optimistic remove — update UI instantly, sync in background ──────
  Future<void> remove(String mangaId) async {
    // 1. Immediately remove from local state — no loading freeze
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((m) => m.mangaId != mangaId).toList());

    final apiClient = ref.read(apiClientProvider);
    final session = ref.read(_sessionServiceProvider);
    final token = await session.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        await apiClient.client.delete(
          '/library/$mangaId',
          options: _authOptions(token),
        );
      } catch (e, s) {
        // ignore: avoid_print
        print('LibraryNotifier.remove error: $e\n$s');
        // Also remove from local Hive as fallback
        final service = ref.read(libraryServiceProvider).valueOrNull;
        await service?.remove(mangaId);
      }
    } else {
      final service = ref.read(libraryServiceProvider).valueOrNull;
      await service?.remove(mangaId);
    }
  }

  // ── FIXED: optimistic add — update UI instantly, sync in background ─────────
  Future<void> add(LibraryManga manga) async {
    // 1. Immediately add to local state — no loading freeze
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, manga]);

    final apiClient = ref.read(apiClientProvider);
    final session = ref.read(_sessionServiceProvider);
    final token = await session.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        await apiClient.client.post(
          '/library',
          data: {'mangaId': manga.mangaId},
          options: _authOptions(token),
        );
      } catch (e, s) {
        // ignore: avoid_print
        print('LibraryNotifier.add error: $e\n$s');
        // Rollback optimistic update on failure
        final rolled = state.valueOrNull ?? [];
        state = AsyncData(
          rolled.where((m) => m.mangaId != manga.mangaId).toList(),
        );
        // Try saving locally as fallback
        final service = ref.read(libraryServiceProvider).valueOrNull;
        await service?.add(manga);
        // Re-add from local
        final updated = state.valueOrNull ?? [];
        state = AsyncData([...updated, manga]);
      }
    } else {
      final service = ref.read(libraryServiceProvider).valueOrNull;
      await service?.add(manga);
    }
  }

  Future<bool> isMangaInLibrary(String mangaId) async {
    final current = state.valueOrNull ?? [];
    return current.any((m) => m.mangaId == mangaId);
  }

  // ── Manual refresh — only called explicitly (e.g. pull-to-refresh) ──────────
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFromBackend());
  }
}

// ── Library Provider ──────────────────────────────────────────────────────────
final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, List<LibraryManga>>(
      LibraryNotifier.new,
    );
