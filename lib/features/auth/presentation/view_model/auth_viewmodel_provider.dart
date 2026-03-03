// lib/features/auth/presentation/view_model/auth_viewmodel_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_scratch/features/auth/presentation/state/auth_state.dart';
import 'package:ink_scratch/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:ink_scratch/features/auth/data/providers/auth_usecase_providers.dart';
import 'package:ink_scratch/features/auth/data/providers/auth_repository_provider.dart';
import 'package:ink_scratch/features/manga/data/providers/manga_providers.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final loginUseCase = ref.read(loginUseCaseProvider);
  final registerUseCase = ref.read(registerUseCaseProvider);
  final logoutUseCase = ref.read(logoutUseCaseProvider);
  final updateProfileUseCase = ref.read(updateProfileUseCaseProvider);
  final authRepository = ref.read(authRepositoryProvider);

  return AuthViewModel(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    logoutUseCase: logoutUseCase,
    updateProfileUseCase: updateProfileUseCase,
    authRepository: authRepository,
    // Called after login/register (true) or logout (false)
    // Invalidates library + history so they re-fetch with the correct token
    onAuthChanged: (isAuthenticated) {
      ref.invalidate(libraryProvider);
      ref.invalidate(readingHistoryProvider);
    },
  );
});
