import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qless/shared/models/user_role.dart';

const _roleStorageKey = 'user_role';

abstract class AuthService {
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> registerWithEmail(
      String email, String password, UserRole role);
  Future<void> signOut();
  Future<void> refreshToken();
  void startSilentTokenRefresh();
  void stopSilentTokenRefresh();
  Stream<User?> get authStateChanges;
  UserRole? get cachedRole;
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FlutterSecureStorage? secureStorage,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _storage = secureStorage ?? const FlutterSecureStorage();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _storage;

  // In-memory cache so cachedRole is synchronous after first load
  UserRole? _roleCache;

  // Subscriptions for silent token refresh
  StreamSubscription<User?>? _authStateSub;
  StreamSubscription<User?>? _idTokenSub;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  UserRole? get cachedRole => _roleCache;

  /// Loads the role from secure storage into the in-memory cache.
  /// Call this once at app start (e.g. from a provider initializer).
  Future<void> loadCachedRole() async {
    final stored = await _storage.read(key: _roleStorageKey);
    _roleCache = _parseRole(stored);
  }

  @override
  Future<UserCredential> signInWithEmail(
      String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Refresh in-memory role cache from storage on sign-in
    await loadCachedRole();
    return credential;
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google Sign-In was cancelled by the user.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final oauthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final credential = await _auth.signInWithCredential(oauthCredential);
    await loadCachedRole();
    return credential;
  }

  @override
  Future<UserCredential> registerWithEmail(
      String email, String password, UserRole role) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _persistRole(role);
    return credential;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
      _storage.delete(key: _roleStorageKey),
    ]);
    _roleCache = null;
  }

  @override
  Future<void> refreshToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.getIdToken(true);
    }
  }

  // ---------------------------------------------------------------------------
  // Silent token refresh
  // ---------------------------------------------------------------------------

  /// Starts listening to auth state changes and silently refreshes the ID
  /// token whenever Firebase signals a token change (i.e. near expiry).
  /// Satisfies Requirement 9.1.
  @override
  void startSilentTokenRefresh() {
    stopSilentTokenRefresh(); // cancel any existing subscriptions first

    _authStateSub = _auth.authStateChanges().listen((user) {
      // Cancel any previous idToken subscription when auth state changes
      _idTokenSub?.cancel();
      _idTokenSub = null;

      if (user != null) {
        // Subscribe to token changes; each emission means the token was
        // refreshed or is about to expire — force an immediate refresh.
        _idTokenSub = _auth.idTokenChanges().listen((tokenUser) async {
          if (tokenUser != null) {
            await tokenUser.getIdToken(true);
          }
        });
      }
    });
  }

  /// Cancels all subscriptions started by [startSilentTokenRefresh].
  @override
  void stopSilentTokenRefresh() {
    _idTokenSub?.cancel();
    _idTokenSub = null;
    _authStateSub?.cancel();
    _authStateSub = null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _persistRole(UserRole role) async {
    await _storage.write(key: _roleStorageKey, value: role.name);
    _roleCache = role;
  }

  UserRole? _parseRole(String? value) {
    if (value == null) return null;
    try {
      return UserRole.values.byName(value);
    } catch (_) {
      return null;
    }
  }
}
