import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qless/features/auth/providers/auth_provider.dart';
import 'package:qless/features/auth/screens/auth_screen.dart';
import 'package:qless/features/auth/services/auth_service.dart';
import 'package:qless/shared/models/user_role.dart';

// ---------------------------------------------------------------------------
// Fake AuthService — no external mocking libraries
// ---------------------------------------------------------------------------

class FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeAuthService implements AuthService {
  /// When non-null, [signInWithEmail] and [registerWithEmail] throw this.
  Exception? signInError;
  Exception? registerError;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (signInError != null) throw signInError!;
    return FakeUserCredential();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    if (signInError != null) throw signInError!;
    return FakeUserCredential();
  }

  @override
  Future<UserCredential> registerWithEmail(
      String email, String password, UserRole role) async {
    if (registerError != null) throw registerError!;
    return FakeUserCredential();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> refreshToken() async {}

  @override
  void startSilentTokenRefresh() {}

  @override
  void stopSilentTokenRefresh() {}

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  UserRole? get cachedRole => null;
}

// ---------------------------------------------------------------------------
// Helper — pumps AuthScreen wrapped in ProviderScope + MaterialApp
// ---------------------------------------------------------------------------

Widget buildAuthScreen(FakeAuthService fakeAuth) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(fakeAuth),
    ],
    child: const MaterialApp(
      home: AuthScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthScreen — tab toggle', () {
    testWidgets('renders TabBar with Login and Register tabs', (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      final tabBar = find.byKey(const Key('auth_tab_bar'));
      expect(tabBar, findsOneWidget);
      // 'Login' also appears on the submit button, so check inside the TabBar
      expect(
        find.descendant(of: tabBar, matching: find.text('Login')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tabBar, matching: find.text('Register')),
        findsOneWidget,
      );
    });

    testWidgets('login form is visible by default', (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      expect(find.byKey(const Key('login_email')), findsOneWidget);
      expect(find.byKey(const Key('login_password')), findsOneWidget);
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
    });

    testWidgets('tapping Register tab shows register form', (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_email')), findsOneWidget);
      expect(find.byKey(const Key('register_password')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm')), findsOneWidget);
      expect(find.byKey(const Key('register_submit')), findsOneWidget);
    });

    testWidgets('tapping Login tab after Register shows login form again',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_email')), findsOneWidget);
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
    });
  });

  group('AuthScreen — role toggle', () {
    testWidgets('role toggle is rendered with Student and Teacher options',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      expect(find.byKey(const Key('role_toggle')), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Teacher'), findsOneWidget);
    });

    testWidgets('Student is selected by default', (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      final segmented = tester.widget<SegmentedButton<UserRole>>(
        find.byKey(const Key('role_toggle')),
      );
      expect(segmented.selected, {UserRole.student});
    });

    testWidgets('tapping Teacher selects Teacher role', (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      await tester.tap(find.text('Teacher'));
      await tester.pumpAndSettle();

      final segmented = tester.widget<SegmentedButton<UserRole>>(
        find.byKey(const Key('role_toggle')),
      );
      expect(segmented.selected, {UserRole.teacher});
    });

    testWidgets('tapping Student after Teacher re-selects Student',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      await tester.tap(find.text('Teacher'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      final segmented = tester.widget<SegmentedButton<UserRole>>(
        find.byKey(const Key('role_toggle')),
      );
      expect(segmented.selected, {UserRole.student});
    });
  });

  group('AuthScreen — inline error display on auth failure', () {
    testWidgets('login error is shown when signInWithEmail throws',
        (tester) async {
      final fakeAuth = FakeAuthService()
        ..signInError =
            FirebaseAuthException(code: 'wrong-password', message: 'Bad creds');

      await tester.pumpWidget(buildAuthScreen(fakeAuth));
      await tester.pump();

      await tester.enterText(
          find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(
          find.byKey(const Key('login_password')), 'password123');

      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error')), findsOneWidget);
      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    testWidgets('login error is not shown before submission', (tester) async {
      await tester.pumpWidget(buildAuthScreen(FakeAuthService()));
      await tester.pump();

      expect(find.byKey(const Key('login_error')), findsNothing);
    });

    testWidgets('register error is shown when registerWithEmail throws',
        (tester) async {
      final fakeAuth = FakeAuthService()
        ..registerError = FirebaseAuthException(
            code: 'email-already-in-use', message: 'Duplicate');

      await tester.pumpWidget(buildAuthScreen(fakeAuth));
      await tester.pump();

      // Switch to Register tab
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('register_email')), 'user@test.com');
      await tester.enterText(
          find.byKey(const Key('register_password')), 'password123');
      await tester.enterText(
          find.byKey(const Key('register_confirm')), 'password123');

      await tester.tap(find.byKey(const Key('register_submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_error')), findsOneWidget);
      expect(
          find.text('An account with this email already exists.'), findsOneWidget);
    });

    testWidgets('generic error message shown for unknown exception',
        (tester) async {
      final fakeAuth = FakeAuthService()
        ..signInError = Exception('network-error');

      await tester.pumpWidget(buildAuthScreen(fakeAuth));
      await tester.pump();

      await tester.enterText(
          find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(
          find.byKey(const Key('login_password')), 'password123');

      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error')), findsOneWidget);
      expect(
          find.text('Authentication failed. Please try again.'), findsOneWidget);
    });

    testWidgets('login error clears on next successful attempt', (tester) async {
      final fakeAuth = FakeAuthService()
        ..signInError =
            FirebaseAuthException(code: 'wrong-password', message: 'Bad creds');

      await tester.pumpWidget(buildAuthScreen(fakeAuth));
      await tester.pump();

      await tester.enterText(
          find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(
          find.byKey(const Key('login_password')), 'password123');

      // First attempt — should show error
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login_error')), findsOneWidget);

      // Fix the fake — next call succeeds (but will try to navigate, which
      // MaterialApp without GoRouter will silently ignore)
      fakeAuth.signInError = null;

      await tester.tap(find.byKey(const Key('login_submit')));
      // pump a few frames so setState clears the error before navigation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('login_error')), findsNothing);
    });
  });
}
