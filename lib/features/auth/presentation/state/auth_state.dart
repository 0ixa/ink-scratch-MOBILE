// lib/features/auth/presentation/state/auth_state.dart

import '../../domain/entities/auth_entity.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AuthEntity? currentUser;
  final String? error;

  /// Used by the reset-password flow to track token validity:
  /// null = not yet checked, true = valid, false = invalid/expired
  final bool? resetTokenValid;

  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.currentUser,
    this.error,
    this.resetTokenValid,
  });

  factory AuthState.initial() {
    return const AuthState(
      isLoading: false,
      isAuthenticated: false,
      currentUser: null,
      error: null,
      resetTokenValid: null,
    );
  }

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AuthEntity? currentUser,
    String? error,
    bool? resetTokenValid,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      // passing null intentionally clears the previous error
      error: error,
      resetTokenValid: resetTokenValid ?? this.resetTokenValid,
    );
  }
}
