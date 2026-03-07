// test/features/auth/domain/usecases/auth_usecases_test.mocks.dart
//
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// This file will be auto-generated. The stub below satisfies the import
// before generation so the project compiles in CI.
//
// To regenerate: dart run build_runner build

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

import 'package:dartz/dartz.dart';
import 'package:ink_scratch/core/error/failures.dart';
import 'package:ink_scratch/features/auth/domain/entities/auth_entity.dart';
import 'package:ink_scratch/features/auth/domain/repositories/auth_repository.dart';
import 'package:mockito/mockito.dart';

class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<AuthEntity> login({
    required String? email,
    required String? password,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#login, [], {#email: email, #password: password}),
            returnValue: Future<AuthEntity>.value(
              AuthEntity(id: '', username: '', email: ''),
            ),
            returnValueForMissingStub: Future<AuthEntity>.value(
              AuthEntity(id: '', username: '', email: ''),
            ),
          )
          as Future<AuthEntity>);

  @override
  Future<AuthEntity> register({
    required String? fullName,
    String? phoneNumber,
    required String? gender,
    required String? email,
    required String? username,
    required String? password,
    required String? confirmPassword,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#register, [], {
              #fullName: fullName,
              #phoneNumber: phoneNumber,
              #gender: gender,
              #email: email,
              #username: username,
              #password: password,
              #confirmPassword: confirmPassword,
            }),
            returnValue: Future<AuthEntity>.value(
              AuthEntity(id: '', username: '', email: ''),
            ),
            returnValueForMissingStub: Future<AuthEntity>.value(
              AuthEntity(id: '', username: '', email: ''),
            ),
          )
          as Future<AuthEntity>);

  @override
  Future<void> logout() =>
      (super.noSuchMethod(
            Invocation.method(#logout, []),
            returnValue: Future<void>.value(),
            returnValueForMissingStub: Future<void>.value(),
          )
          as Future<void>);

  @override
  Future<Either<Failure, AuthEntity>> updateProfile({
    String? bio,
    String? profilePicturePath,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#updateProfile, [], {
              #bio: bio,
              #profilePicturePath: profilePicturePath,
            }),
            returnValue: Future<Either<Failure, AuthEntity>>.value(
              Right(AuthEntity(id: '', username: '', email: '')),
            ),
            returnValueForMissingStub:
                Future<Either<Failure, AuthEntity>>.value(
                  Right(AuthEntity(id: '', username: '', email: '')),
                ),
          )
          as Future<Either<Failure, AuthEntity>>);

  @override
  Future<Either<Failure, void>> forgotPassword({required String? email}) =>
      (super.noSuchMethod(
            Invocation.method(#forgotPassword, [], {#email: email}),
            returnValue: Future<Either<Failure, void>>.value(const Right(null)),
            returnValueForMissingStub: Future<Either<Failure, void>>.value(
              const Right(null),
            ),
          )
          as Future<Either<Failure, void>>);

  @override
  Future<Either<Failure, bool>> verifyResetToken({required String? token}) =>
      (super.noSuchMethod(
            Invocation.method(#verifyResetToken, [], {#token: token}),
            returnValue: Future<Either<Failure, bool>>.value(const Right(true)),
            returnValueForMissingStub: Future<Either<Failure, bool>>.value(
              const Right(true),
            ),
          )
          as Future<Either<Failure, bool>>);

  @override
  Future<Either<Failure, void>> resetPassword({
    required String? token,
    required String? password,
    required String? confirmPassword,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#resetPassword, [], {
              #token: token,
              #password: password,
              #confirmPassword: confirmPassword,
            }),
            returnValue: Future<Either<Failure, void>>.value(const Right(null)),
            returnValueForMissingStub: Future<Either<Failure, void>>.value(
              const Right(null),
            ),
          )
          as Future<Either<Failure, void>>);
}
