// test/features/auth/domain/usecases/auth_usecases_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ink_scratch/features/auth/domain/repositories/auth_repository.dart';
import 'package:ink_scratch/features/auth/domain/usecases/login_usecase.dart';
import 'package:ink_scratch/features/auth/domain/usecases/register_usecase.dart';
import 'package:ink_scratch/features/auth/domain/usecases/logout_usecase.dart';
import 'package:ink_scratch/features/auth/domain/entities/auth_entity.dart';

import 'auth_usecases_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;
  late LoginUseCase loginUseCase;
  late RegisterUseCase registerUseCase;
  late LogoutUseCase logoutUseCase;

  // ── Shared test fixture ───────────────────────────────────────────────────
  final tAuthEntity = AuthEntity(
    id: 'user-001',
    username: 'testuser',
    email: 'test@example.com',
    fullName: 'Test User',
    token: 'mock-jwt-token',
    role: 'user',
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    loginUseCase = LoginUseCase(authRepository: mockRepo);
    registerUseCase = RegisterUseCase(authRepository: mockRepo);
    logoutUseCase = LogoutUseCase(authRepository: mockRepo);
  });

  // ══════════════════════════════════════════════════════════════════════════
  // LoginUseCase — 4 tests
  // ══════════════════════════════════════════════════════════════════════════
  group('LoginUseCase', () {
    test('1. returns AuthEntity when repository login succeeds', () async {
      when(
        mockRepo.login(email: 'test@example.com', password: 'password123'),
      ).thenAnswer((_) async => tAuthEntity);

      final result = await loginUseCase.call(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, equals(tAuthEntity));
      expect(result.token, isNotNull);
      verify(
        mockRepo.login(email: 'test@example.com', password: 'password123'),
      ).called(1);
    });

    test(
      '2. forwards the exact email and password to the repository',
      () async {
        when(
          mockRepo.login(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => tAuthEntity);

        await loginUseCase.call(email: 'another@mail.com', password: 'secret');

        verify(
          mockRepo.login(email: 'another@mail.com', password: 'secret'),
        ).called(1);
      },
    );

    test('3. propagates exception when repository throws', () async {
      when(
        mockRepo.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(Exception('Invalid credentials'));

      expect(
        () => loginUseCase.call(email: 'bad@example.com', password: 'wrong'),
        throwsException,
      );
    });

    test('4. returned entity contains expected username and email', () async {
      when(
        mockRepo.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => tAuthEntity);

      final result = await loginUseCase.call(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.username, 'testuser');
      expect(result.email, 'test@example.com');
      expect(result.id, 'user-001');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // RegisterUseCase — 3 tests
  // ══════════════════════════════════════════════════════════════════════════
  group('RegisterUseCase', () {
    test('5. returns AuthEntity when registration succeeds', () async {
      when(
        mockRepo.register(
          fullName: anyNamed('fullName'),
          phoneNumber: anyNamed('phoneNumber'),
          gender: anyNamed('gender'),
          email: anyNamed('email'),
          username: anyNamed('username'),
          password: anyNamed('password'),
          confirmPassword: anyNamed('confirmPassword'),
        ),
      ).thenAnswer((_) async => tAuthEntity);

      final result = await registerUseCase.call(
        fullName: 'Test User',
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
        gender: 'male',
      );

      expect(result, equals(tAuthEntity));
    });

    test(
      '6. passes null phoneNumber as empty string to the repository',
      () async {
        when(
          mockRepo.register(
            fullName: anyNamed('fullName'),
            phoneNumber: anyNamed('phoneNumber'),
            gender: anyNamed('gender'),
            email: anyNamed('email'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            confirmPassword: anyNamed('confirmPassword'),
          ),
        ).thenAnswer((_) async => tAuthEntity);

        await registerUseCase.call(
          fullName: 'Test User',
          email: 'test@example.com',
          username: 'testuser',
          password: 'password123',
          confirmPassword: 'password123',
          gender: 'male',
          phoneNumber: null,
        );

        // phoneNumber should be coerced to '' inside the usecase
        verify(
          mockRepo.register(
            fullName: 'Test User',
            phoneNumber: '',
            gender: 'male',
            email: 'test@example.com',
            username: 'testuser',
            password: 'password123',
            confirmPassword: 'password123',
          ),
        ).called(1);
      },
    );

    test('7. propagates exception when registration fails', () async {
      when(
        mockRepo.register(
          fullName: anyNamed('fullName'),
          phoneNumber: anyNamed('phoneNumber'),
          gender: anyNamed('gender'),
          email: anyNamed('email'),
          username: anyNamed('username'),
          password: anyNamed('password'),
          confirmPassword: anyNamed('confirmPassword'),
        ),
      ).thenThrow(Exception('Username taken'));

      expect(
        () => registerUseCase.call(
          fullName: 'Test User',
          email: 'test@example.com',
          username: 'testuser',
          password: 'password123',
          confirmPassword: 'password123',
          gender: 'male',
        ),
        throwsException,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // LogoutUseCase — 3 tests
  // ══════════════════════════════════════════════════════════════════════════
  group('LogoutUseCase', () {
    test('8. completes successfully when repository logout succeeds', () async {
      when(mockRepo.logout()).thenAnswer((_) async {});

      await expectLater(logoutUseCase.call(), completes);
      verify(mockRepo.logout()).called(1);
    });

    test('9. calls repository logout exactly once', () async {
      when(mockRepo.logout()).thenAnswer((_) async {});

      await logoutUseCase.call();

      verify(mockRepo.logout()).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('10. propagates exception when repository logout throws', () async {
      when(mockRepo.logout()).thenThrow(Exception('Network error'));

      expect(() => logoutUseCase.call(), throwsException);
    });
  });
}
