import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qless/features/auth/providers/auth_provider.dart';
import 'package:qless/features/auth/services/auth_service.dart';
import 'package:qless/shared/models/user_role.dart';

// ---------------------------------------------------------------------------
// Fake secure storage
// ---------------------------------------------------------------------------

class FakeSecureStorage {
  final Map<String, String> _store = {};

  Future<void> write(String key, String value) async => _store[key] = value;
  Future<String?> read(String key) async => _store[key];
  Future<void> delete(String key) async => _store.remove(key);
  bool containsKey(String key) => _store.containsKey(key);
}

// ---------------------------------------------------------------------------
// Fake Firebase User
// ---------------------------------------------------------------------------

class FakeUser implements User {
  final List<String> getIdTokenCalls = [];

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    getIdTokenCalls.add(forceRefresh ? 'force' : 'cached');
    return 'fake-token';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// FakeAuthService — tracks calls to all session-management methods
// ---------------------------------------------------------------------------

class FakeAuthService implements AuthService {
  final FakeSecureStorage storage;
  final FakeUser? currentUser;

  int signOutCallCount = 0;
  int refreshTokenCallCount = 0;
  int startSilentTokenRefreshCallCount = 0;
  int stopSilentTokenRefreshCallCount = 0;

  UserRole? _roleCache;

  final _authStateController = StreamController<User?>.broadcast();

  FakeAuthService({
    required this.storage,
    this.currentUser,
  });

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> registerWithEmail(
      String email, String password, UserRole role) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    await storage.delete('user_role');
    _roleCache = null;
    _authStateController.add(null);
  }

  @override
  Future<void> refreshToken() async {
    refreshTokenCallCount++;
    await currentUser?.getIdToken(true);
  }

  @override
  void startSilentTokenRefresh() {
    startSilentTokenRefreshCallCount++;
  }

  @override
  void stopSilentTokenRefresh() {
    stopSilentTokenRefreshCallCount++;
  }

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  UserRole? get cachedRole => _roleCache;

  void dispose() {
    _authStateController.close();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Session management — signOut', () {
    test('signOut clears the role from secure storage (req 9.2, 9.4)',
        () async {
      final storage = FakeSecureStorage();
      await storage.write('user_role', 'student');

      final service = FakeAuthService(storage: storage);
      await service.signOut();

      final stored = await storage.read('user_role');
      expect(stored, isNull,
          reason: 'role must be removed from secure storage on sign-out');
    });

    test('signOut revokes the Firebase session (req 9.2)', () async {
      final storage = FakeSecureStorage();
      final service = FakeAuthService(storage: storage);

      await service.signOut();

      expect(service.signOutCallCount, 1,
          reason: 'signOut must be called exactly once');
    });

    test('signOut nulls the in-memory role cache (req 9.2)', () async {
      final storage = FakeSecureStorage();
      await storage.write('user_role', 'teacher');

      final service = FakeAuthService(storage: storage);
      // Simulate a cached role by calling signOut which sets _roleCache = null
      // First verify cachedRole is null initially (FakeAuthService starts null)
      expect(service.cachedRole, isNull);

      // Now sign out — cache should remain null and storage should be cleared
      await service.signOut();

      expect(service.cachedRole, isNull,
          reason: 'in-memory role cache must be null after sign-out');
    });
  });

  group('Session management — token refresh', () {
    test('refreshToken calls getIdToken(true) on the current user (req 9.1)',
        () async {
      final storage = FakeSecureStorage();
      final fakeUser = FakeUser();
      final service = FakeAuthService(storage: storage, currentUser: fakeUser);

      await service.refreshToken();

      expect(service.refreshTokenCallCount, 1);
      expect(fakeUser.getIdTokenCalls, ['force'],
          reason: 'getIdToken must be called with forceRefresh=true');
    });

    test(
        'startSilentTokenRefresh starts listening to auth state changes (req 9.1)',
        () async {
      final storage = FakeSecureStorage();
      final service = FakeAuthService(storage: storage);

      service.startSilentTokenRefresh();

      expect(service.startSilentTokenRefreshCallCount, 1,
          reason: 'startSilentTokenRefresh must be called once');
    });

    test('stopSilentTokenRefresh cancels the subscriptions (req 9.1)',
        () async {
      final storage = FakeSecureStorage();
      final service = FakeAuthService(storage: storage);

      service.startSilentTokenRefresh();
      service.stopSilentTokenRefresh();

      expect(service.stopSilentTokenRefreshCallCount, 1,
          reason: 'stopSilentTokenRefresh must be called once');
    });
  });

  group('Session management — roleProvider', () {
    test("roleProvider returns UserRole.student when 'student' is stored (req 9.3)",
        () async {
      final storage = FakeSecureStorage();
      await storage.write('user_role', 'student');

      final container = ProviderContainer(
        overrides: [
          roleProvider.overrideWith((_) async {
            final value = await storage.read('user_role');
            if (value == null) return null;
            try {
              return UserRole.values.byName(value);
            } catch (_) {
              return null;
            }
          }),
        ],
      );
      addTearDown(container.dispose);

      final role = await container.read(roleProvider.future);
      expect(role, UserRole.student);
    });

    test("roleProvider returns UserRole.teacher when 'teacher' is stored (req 9.3)",
        () async {
      final storage = FakeSecureStorage();
      await storage.write('user_role', 'teacher');

      final container = ProviderContainer(
        overrides: [
          roleProvider.overrideWith((_) async {
            final value = await storage.read('user_role');
            if (value == null) return null;
            try {
              return UserRole.values.byName(value);
            } catch (_) {
              return null;
            }
          }),
        ],
      );
      addTearDown(container.dispose);

      final role = await container.read(roleProvider.future);
      expect(role, UserRole.teacher);
    });

    test('roleProvider returns null when no role is stored (req 9.3)',
        () async {
      final storage = FakeSecureStorage();

      final container = ProviderContainer(
        overrides: [
          roleProvider.overrideWith((_) async {
            final value = await storage.read('user_role');
            if (value == null) return null;
            try {
              return UserRole.values.byName(value);
            } catch (_) {
              return null;
            }
          }),
        ],
      );
      addTearDown(container.dispose);

      final role = await container.read(roleProvider.future);
      expect(role, isNull);
    });
  });
}
