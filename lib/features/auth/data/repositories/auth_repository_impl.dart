// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/error/failures.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl({required this.remoteDatasource});

  @override
  Future<AuthEntity> register({
    required String fullName,
    String? phoneNumber,
    required String gender,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final auth = await remoteDatasource.register(
        fullName: fullName,
        phoneNumber: phoneNumber ?? '',
        gender: gender,
        email: email,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
      );
      return auth;
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<AuthEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final auth = await remoteDatasource.login(
        email: email,
        password: password,
      );
      return auth;
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await remoteDatasource.logout();
  }

  @override
  Future<Either<Failure, AuthEntity>> updateProfile({
    String? bio,
    String? profilePicturePath,
  }) async {
    try {
      final authEntity = await remoteDatasource.updateProfile(
        bio: bio,
        profilePicturePath: profilePicturePath,
      );
      return Right(authEntity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    try {
      await remoteDatasource.forgotPassword(email: email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyResetToken({
    required String token,
  }) async {
    try {
      final isValid = await remoteDatasource.verifyResetToken(token: token);
      return Right(isValid);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await remoteDatasource.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
