// lib/features/manga/data/providers/manga_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_client_provider.dart';
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

// ── Reading History Service ───────────────────────────────────────────────────
final readingHistoryServiceProvider = FutureProvider<ReadingHistoryService>((
  ref,
) async {
  final service = ReadingHistoryServiceImpl();
  await service.init();
  return service;
});

// ── Library Service ───────────────────────────────────────────────────────────
final libraryServiceProvider = FutureProvider<LibraryService>((ref) async {
  final service = LibraryServiceImpl();
  await service.init();
  return service;
});

// ── Manga List Provider ───────────────────────────────────────────────────────
// Fetches all manga from the remote datasource
final mangaListProvider = FutureProvider<List<dynamic>>((ref) async {
  // TODO: Implement actual repository method to fetch all manga
  return [];
});

// ── Reading History Provider ───────────────────────────────────────────────────
// Fetches the current user's reading history
final readingHistoryProvider =
    FutureProvider.autoDispose<List<ReadingHistoryEntry>>((ref) async {
      final serviceAsync = ref.watch(readingHistoryServiceProvider);
      return serviceAsync.when(
        loading: () => [],
        error: (e, s) => [],
        data: (service) => service.getAll(),
      );
    });

// ── Library Notifier (needed for add/remove operations) ───────────────────────
class LibraryNotifier extends AsyncNotifier<List<LibraryManga>> {
  @override
  Future<List<LibraryManga>> build() async {
    final serviceAsync = ref.watch(libraryServiceProvider);
    return serviceAsync.when(
      loading: () => [],
      error: (e, s) => [],
      data: (service) => service.getAll(),
    );
  }

  Future<void> remove(String mangaId) async {
    final serviceAsync = ref.watch(libraryServiceProvider);
    await serviceAsync.when(
      loading: () async => {},
      error: (e, s) async => {},
      data: (service) async {
        await service.remove(mangaId);
        // Refresh the state after removal
        state = await AsyncValue.guard(() => service.getAll());
      },
    );
  }

  Future<void> add(LibraryManga manga) async {
    final serviceAsync = ref.watch(libraryServiceProvider);
    await serviceAsync.when(
      loading: () async => {},
      error: (e, s) async => {},
      data: (service) async {
        await service.add(manga);
        // Refresh the state after addition
        state = await AsyncValue.guard(() => service.getAll());
      },
    );
  }
}

// ── Library Provider ──────────────────────────────────────────────────────────
final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, List<LibraryManga>>(
      LibraryNotifier.new,
    );
