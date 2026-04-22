import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qless/features/auth/services/auth_service.dart';
import 'package:qless/shared/models/user_role.dart';

/// Provides the [AuthService] implementation.
final authServiceProvider = Provider<AuthService>((ref) {
  final service = FirebaseAuthService();
  service.startSilentTokenRefresh();
  ref.onDispose(service.stopSilentTokenRefresh);
  return service;
});

/// Exposes the Firebase auth state as a stream of nullable [User].
/// Used by the router guard and the app to determine if a user is signed in.
/// Satisfies Requirements 2.5, 2.6.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// he sai 
/// Reads the stored [UserRole] from secure storage.
/// Returns `null` if no role has been persisted yet.
/// Satisfies Requirements 9.3.

final roleProvider = FutureProvider<UserRole?>((ref) async {
  const storage = FlutterSecureStorage();
  final value = await storage.read(key: 'user_role');
  if (value == null) return null;
  try {
    return UserRole.values.byName(value);
  } catch (_) {
    return null;
  }
});
