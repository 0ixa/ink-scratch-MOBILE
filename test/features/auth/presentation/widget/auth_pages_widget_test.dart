// test/features/auth/presentation/widget/auth_pages_widget_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ink_scratch/core/error/failures.dart';
import 'package:ink_scratch/features/auth/domain/entities/auth_entity.dart';
import 'package:ink_scratch/features/auth/domain/repositories/auth_repository.dart';
import 'package:ink_scratch/features/auth/domain/usecases/login_usecase.dart';
import 'package:ink_scratch/features/auth/domain/usecases/logout_usecase.dart';
import 'package:ink_scratch/features/auth/domain/usecases/register_usecase.dart';
import 'package:ink_scratch/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:ink_scratch/features/auth/presentation/pages/login_page.dart';
import 'package:ink_scratch/features/auth/presentation/pages/signup_page.dart';
import 'package:ink_scratch/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:ink_scratch/features/auth/presentation/view_model/auth_viewmodel_provider.dart';

// ── No-op repository ──────────────────────────────────────────────────────────

class _NoopRepo implements AuthRepository {
  @override
  Future<AuthEntity> login({
    required String email,
    required String password,
  }) async => AuthEntity(id: '', username: '', email: '');

  @override
  Future<AuthEntity> register({
    required String fullName,
    String? phoneNumber,
    required String gender,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async => AuthEntity(id: '', username: '', email: '');

  @override
  Future<void> logout() async {}

  @override
  Future<Either<Failure, AuthEntity>> updateProfile({
    String? bio,
    String? profilePicturePath,
  }) async => Right(AuthEntity(id: '', username: '', email: ''));

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async =>
      const Right(null);

  @override
  Future<Either<Failure, bool>> verifyResetToken({
    required String token,
  }) async => const Right(true);

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async => const Right(null);
}

// ── No-op use cases ───────────────────────────────────────────────────────────

class _NoopLoginUseCase implements LoginUseCase {
  @override
  AuthRepository get authRepository => _NoopRepo();
  @override
  Future<AuthEntity> call({
    required String email,
    required String password,
  }) async => AuthEntity(id: '', username: '', email: '');
}

class _NoopRegisterUseCase implements RegisterUseCase {
  @override
  AuthRepository get authRepository => _NoopRepo();
  @override
  Future<AuthEntity> call({
    required String fullName,
    String? phoneNumber,
    required String gender,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async => AuthEntity(id: '', username: '', email: '');
}

class _NoopLogoutUseCase implements LogoutUseCase {
  @override
  AuthRepository get authRepository => _NoopRepo();
  @override
  Future<void> call() async {}
}

class _NoopUpdateProfileUseCase implements UpdateProfileUseCase {
  @override
  AuthRepository get repository => _NoopRepo();
  @override
  Future<Either<Failure, AuthEntity>> call({
    String? bio,
    String? profilePicturePath,
  }) async => Right(AuthEntity(id: '', username: '', email: ''));
}

// ── Stub ViewModel ────────────────────────────────────────────────────────────

class _StubAuthViewModel extends AuthViewModel {
  _StubAuthViewModel()
    : super(
        loginUseCase: _NoopLoginUseCase(),
        registerUseCase: _NoopRegisterUseCase(),
        logoutUseCase: _NoopLogoutUseCase(),
        updateProfileUseCase: _NoopUpdateProfileUseCase(),
        authRepository: _NoopRepo(),
      );

  @override
  Future<void> checkCurrentUser() async {}

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> register({
    required String fullName,
    String? phoneNumber,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    String? gender,
  }) async {}
}

// ── Widget wrappers ───────────────────────────────────────────────────────────

Widget _wrapLogin() => ProviderScope(
  overrides: [
    authViewModelProvider.overrideWith((ref) => _StubAuthViewModel()),
  ],
  child: const MaterialApp(home: LoginPage()),
);

// SignupPage is tall — give it a large surface so nothing is off-screen
Widget _wrapSignup() => ProviderScope(
  overrides: [
    authViewModelProvider.overrideWith((ref) => _StubAuthViewModel()),
  ],
  child: MediaQuery(
    data: const MediaQueryData(size: Size(800, 2000)),
    child: const MaterialApp(home: SignupPage()),
  ),
);

// Helper: scroll until a finder is visible then tap it
Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

// ══════════════════════════════════════════════════════════════════════════════
void main() {
  // ── LoginPage — 10 widget tests ───────────────────────────────────────────
  group('LoginPage widgets', () {
    testWidgets('1. renders WELCOME BACK heading', (tester) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      expect(find.text('WELCOME BACK'), findsOneWidget);
    });

    testWidgets('2. renders email and password text fields', (tester) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('3. renders Log In button', (tester) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('4. shows email required error when form submitted empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log In'));
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('5. shows invalid-email error for malformed email', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.tap(find.text('Log In'));
      await tester.pump();
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets(
      '6. shows password-too-short error for passwords under 6 chars',
      (tester) async {
        await tester.pumpWidget(_wrapLogin());
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), '123');
        await tester.tap(find.text('Log In'));
        await tester.pump();
        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
        );
      },
    );

    testWidgets('7. renders Forgot password? link', (tester) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('8. renders Register now link', (tester) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      expect(find.text('Register now'), findsOneWidget);
    });

    testWidgets('9. Remember me checkbox is initially unchecked', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('10. tapping Remember me checkbox toggles its value', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });
  });

  // ── SignupPage — 10 widget tests ──────────────────────────────────────────
  group('SignupPage widgets', () {
    testWidgets('11. renders CREATE ACCOUNT heading', (tester) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    });

    testWidgets(
      '12. renders at least 5 text fields (name, username, email, pw, confirm)',
      (tester) async {
        await tester.pumpWidget(_wrapSignup());
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsAtLeastNWidgets(5));
      },
    );

    testWidgets('13. renders Create Account submit button', (tester) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('14. shows full-name required error when submitted empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      await _scrollAndTap(tester, find.text('Create Account'));
      expect(find.text('Please enter your full name'), findsOneWidget);
    });

    testWidgets('15. shows username-too-short error', (tester) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(2), 'ab');
      await _scrollAndTap(tester, find.text('Create Account'));
      expect(find.text('Must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('16. shows invalid-email error for bad email input', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      // Fill name + username to pass earlier validators
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(2), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(3), 'bad-email');
      await _scrollAndTap(tester, find.text('Create Account'));
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('17. shows passwords-do-not-match error', (tester) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      // Fill all fields before password to avoid earlier validator stops
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(2), 'testuser');
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(4), 'password123');
      await tester.enterText(find.byType(TextFormField).at(5), 'different999');
      await _scrollAndTap(tester, find.text('Create Account'));
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('18. renders gender dropdown with Male option', (tester) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      expect(find.text('Male'), findsOneWidget);
    });

    testWidgets('19. renders Log In navigation link', (tester) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('20. shows password-too-short error on signup', (tester) async {
      await tester.pumpWidget(_wrapSignup());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(2), 'testuser');
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(4), '123');
      await _scrollAndTap(tester, find.text('Create Account'));
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });
  });
}
