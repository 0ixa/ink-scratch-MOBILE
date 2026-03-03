// lib/features/manga/data/providers/manga_providers.dart

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
        // ApiClient interceptor already injects Authorization header
        final response = await apiClient.client.get('/history');
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
                // FIX: API returns doubles like 156.5 for decimal chapters
                chapterNumber: (item['chapterNumber'] as num?)?.toInt(),
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
      // GET /api/library — ApiClient interceptor injects Authorization header
      final response = await apiClient.client.get('/library');
      final data = response.data;
      final List<dynamic> list = data is Map
          ? (data['data'] ?? data['library'] ?? [])
          : (data ?? []);

      return list.map((item) {
        return LibraryManga(
          id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
          mangaId: item['mangaId']?.toString() ?? '',
          title: item['title']?.toString() ?? '',
          author: item['author']?.toString() ?? '',
          coverImage: item['coverImage']?.toString(),
          status: item['status']?.toString() ?? 'Unknown',
          genre: List<String>.from(item['genre'] ?? item['genres'] ?? []),
          rating: ((item['rating'] ?? 0) as num).toDouble(),
          addedAt: item['addedAt'] != null
              ? DateTime.tryParse(item['addedAt'].toString())
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

  Future<void> remove(String mangaId) async {
    // Optimistic update — remove from UI instantly
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((m) => m.mangaId != mangaId).toList());

    final apiClient = ref.read(apiClientProvider);
    final session = ref.read(_sessionServiceProvider);
    final token = await session.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        // DELETE /api/library/:mangaId
        await apiClient.client.delete('/library/$mangaId');
      } catch (e, s) {
        // ignore: avoid_print
        print('LibraryNotifier.remove error: $e\n$s');
        final service = ref.read(libraryServiceProvider).valueOrNull;
        await service?.remove(mangaId);
      }
    } else {
      final service = ref.read(libraryServiceProvider).valueOrNull;
      await service?.remove(mangaId);
    }
  }

  Future<void> add(LibraryManga manga) async {
    // Optimistic update — add to UI instantly
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, manga]);

    final apiClient = ref.read(apiClientProvider);
    final session = ref.read(_sessionServiceProvider);
    final token = await session.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        // FIX: correct endpoint is /library/add (not /library)
        // FIX: backend requires mangaId + title at minimum, send all fields
        await apiClient.client.post(
          '/library/add',
          data: {
            'mangaId': manga.mangaId,
            'title': manga.title,
            'author': manga.author,
            'coverImage': manga.coverImage ?? '',
            'status': manga.status,
            'genre': manga.genre,
            'rating': manga.rating,
          },
        );
      } catch (e, s) {
        // ignore: avoid_print
        print('LibraryNotifier.add error: $e\n$s');
        // Rollback optimistic update on failure
        final rolled = state.valueOrNull ?? [];
        state = AsyncData(
          rolled.where((m) => m.mangaId != manga.mangaId).toList(),
        );
        // Fallback to local storage
        final service = ref.read(libraryServiceProvider).valueOrNull;
        await service?.add(manga);
        final updated = state.valueOrNull ?? [];
        state = AsyncData([...updated, manga]);
      }
    } else {
      final service = ref.read(libraryServiceProvider).valueOrNull;
      await service?.add(manga);
    }
  }

  /// Checks backend directly — more reliable than trusting local state
  Future<bool> isMangaInLibrary(String mangaId) async {
    final apiClient = ref.read(apiClientProvider);
    final session = ref.read(_sessionServiceProvider);
    final token = await session.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        // GET /api/library/check/:mangaId
        final response = await apiClient.client.get('/library/check/$mangaId');
        final data = response.data;
        return data['data']?['inLibrary'] ?? false;
      } catch (_) {
        // Fall through to local state check
      }
    }

    final current = state.valueOrNull ?? [];
    return current.any((m) => m.mangaId == mangaId);
  }

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
