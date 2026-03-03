// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';

abstract class AuthRepository {
  Future<AuthEntity> register({
    required String fullName,
    String? phoneNumber,
    required String gender,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  });

  Future<AuthEntity> login({required String email, required String password});

  Future<void> logout();

  Future<Either<Failure, AuthEntity>> updateProfile({
    String? bio,
    String? profilePicturePath,
  });

  /// Sends a password reset email. Always succeeds silently on the backend
  /// (so as not to reveal whether the email is registered).
  Future<Either<Failure, void>> forgotPassword({required String email});

  /// Verifies whether a reset token is still valid.
  Future<Either<Failure, bool>> verifyResetToken({required String token});

  /// Resets the user's password using a valid token.
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  });
}
