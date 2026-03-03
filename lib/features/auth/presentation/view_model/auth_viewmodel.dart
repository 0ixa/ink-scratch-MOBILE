// lib/features/auth/presentation/view_model/auth_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ink_scratch/core/services/storage/user_session_service.dart';
import 'package:ink_scratch/features/auth/domain/usecases/login_usecase.dart';
import 'package:ink_scratch/features/auth/domain/usecases/register_usecase.dart';
import 'package:ink_scratch/features/auth/domain/usecases/logout_usecase.dart';
import 'package:ink_scratch/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:ink_scratch/features/auth/domain/repositories/auth_repository.dart';
import 'package:ink_scratch/features/auth/presentation/state/auth_state.dart';

class AuthViewModel extends StateNotifier<AuthState> {
  final UserSessionService _sessionService = UserSessionService();
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final AuthRepository _authRepository;

  /// Called after login/register (true) or logout (false).
  /// Used by the provider to invalidate library + history without a self-cycle.
  final void Function(bool isAuthenticated)? onAuthChanged;

  AuthViewModel({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required AuthRepository authRepository,
    this.onAuthChanged,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _logoutUseCase = logoutUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _authRepository = authRepository,
       super(AuthState.initial());

  Future<void> checkCurrentUser() async {
    final token = await _sessionService.getToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authEntity = await _loginUseCase.call(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: authEntity,
        error: null,
      );
      // Invalidate library + history so they re-fetch with the new token
      onAuthChanged?.call(true);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.error.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register({
    required String fullName,
    String? phoneNumber,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authEntity = await _registerUseCase.call(
        fullName: fullName.trim(),
        phoneNumber: phoneNumber?.trim() ?? '',
        gender: gender ?? 'Not Specified',
        email: email.trim(),
        username: username.trim(),
        password: password,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: authEntity,
        error: null,
      );
      // Invalidate library + history so they re-fetch with the new token
      onAuthChanged?.call(true);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.error.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _logoutUseCase.call();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        currentUser: null,
        error: null,
      );
      // Invalidate library + history so they clear on logout
      onAuthChanged?.call(false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfile({String? bio, String? profilePicturePath}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _updateProfileUseCase.call(
        bio: bio,
        profilePicturePath: profilePicturePath,
      );
      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
        },
        (authEntity) {
          state = state.copyWith(
            isLoading: false,
            currentUser: authEntity,
            error: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sends a password reset email. Returns true on success.
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.forgotPassword(email: email.trim());
      return result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (_) {
          state = state.copyWith(isLoading: false, error: null);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Verifies the reset token from the deep link.
  Future<void> verifyResetToken(String token) async {
    state = state.copyWith(isLoading: true, error: null, resetTokenValid: null);
    try {
      final result = await _authRepository.verifyResetToken(token: token);
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
            resetTokenValid: false,
          );
        },
        (isValid) {
          state = state.copyWith(
            isLoading: false,
            error: null,
            resetTokenValid: isValid,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        resetTokenValid: false,
      );
    }
  }

  /// Resets the password. Returns true on success.
  Future<bool> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      return result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (_) {
          state = state.copyWith(isLoading: false, error: null);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
