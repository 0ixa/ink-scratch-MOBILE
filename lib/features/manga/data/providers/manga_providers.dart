// lib/features/manga/data/providers/manga_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_client_provider.dart';
import '../datasources/manga_remote_datasource.dart';
import '../repositories/manga_repository_impl.dart';
import '../../domain/repositories/manga_repository.dart';

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
