// lib/features/auth/data/providers/auth_repository_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_scratch/core/services/storage/user_session_service.dart';
import 'package:ink_scratch/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:ink_scratch/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ink_scratch/features/auth/domain/repositories/auth_repository.dart';
import 'package:ink_scratch/core/providers/api_client_provider.dart';

final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService();
});

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final sessionService = ref.read(userSessionServiceProvider);
  return AuthRemoteDatasource(
    apiClient: apiClient,
    sessionService: sessionService,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDatasource = ref.read(authRemoteDatasourceProvider);
  return AuthRepositoryImpl(remoteDatasource: remoteDatasource);
});
