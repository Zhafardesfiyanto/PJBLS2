import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_model.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../verification/data/verification_repository.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? institutionCode,
  });
  Future<UserModel> login(String email, String password);
  Future<UserModel> signInWithGoogle({required String role});
  Future<void> logout();
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
}

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final VerificationRepository _verificationRepository;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    VerificationRepository? verificationRepository,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _verificationRepository = verificationRepository ?? FirebaseVerificationRepository(),
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          clientId: '802774746484-7e3s5m2hicqivugtgvi5m8q50lnb94gd.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? institutionCode,
  }) async {
    try {
      // Register dengan Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AppException('Gagal membuat akun');
      }

      // Get FCM token
      final fcmToken = await _messaging.getToken();

      // Check if institution code is valid for auto-verification
      bool isAutoVerified = false;
      if (role == 'guru' && institutionCode != null && institutionCode.isNotEmpty) {
        isAutoVerified = await _verificationRepository.validateInstitutionCode(institutionCode);
      }

      // Buat user model
      final userModel = UserModel(
        uid: user.uid,
        fullName: fullName,
        email: email,
        role: role,
        fcmToken: fcmToken,
        verificationStatus: role == 'guru' 
            ? (isAutoVerified ? 'verified' : 'pending')
            : null,
      );

      // Simpan ke Firestore
      await _firestore.doc(FirestorePaths.user(user.uid)).set(userModel.toFirestore());

      // Jika guru dan tidak auto-verified, buat verification request
      if (role == 'guru' && !isAutoVerified) {
        await _verificationRepository.createVerificationRequest(user.uid, fullName);
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AppException('Terjadi kesalahan saat mendaftar: $e');
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw const AppException('Gagal masuk');

      final userDoc = await _firestore.doc(FirestorePaths.user(user.uid)).get();
      if (!userDoc.exists) throw const AppException('Data pengguna tidak ditemukan');

      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _firestore.doc(FirestorePaths.user(user.uid)).update({'fcmToken': fcmToken});
      }

      final userData = userDoc.data()!;
      userData['uid'] = user.uid;
      return UserModel.fromJson(userData);
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Terjadi kesalahan saat masuk: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle({required String role}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AppException('Login Google dibatalkan');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw const AppException('Gagal masuk dengan Google');

      final fcmToken = await _messaging.getToken();

      // Cek apakah user sudah ada di Firestore
      final userDoc = await _firestore.doc(FirestorePaths.user(user.uid)).get();

      if (userDoc.exists) {
        // User sudah ada, update FCM token dan return
        if (fcmToken != null) {
          await _firestore.doc(FirestorePaths.user(user.uid)).update({'fcmToken': fcmToken});
        }
        final userData = userDoc.data()!;
        userData['uid'] = user.uid;
        return UserModel.fromJson(userData);
      }

      // User baru — buat profil
      final userModel = UserModel(
        uid: user.uid,
        fullName: user.displayName ?? googleUser.displayName ?? 'Pengguna',
        email: user.email ?? googleUser.email,
        role: role,
        photoUrl: user.photoURL,
        fcmToken: fcmToken,
        verificationStatus: role == 'guru' ? 'pending' : null,
      );

      await _firestore.doc(FirestorePaths.user(user.uid)).set(userModel.toFirestore());

      if (role == 'guru') {
        await _verificationRepository.createVerificationRequest(
          user.uid, userModel.fullName,
        );
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Terjadi kesalahan saat login Google: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AppException('Gagal keluar: $e');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      try {
        final userDoc = await _firestore.doc(FirestorePaths.user(user.uid)).get();
        if (!userDoc.exists) return null;

        final userData = userDoc.data()!;
        userData['uid'] = user.uid;

        return UserModel.fromJson(userData);
      } catch (e) {
        return null;
      }
    });
  }

  @override
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? null : null; // Will be handled by authStateChanges stream
  }

  /// Map Firebase Auth errors to Indonesian messages
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password tidak valid';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa koneksi dan coba lagi';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi';
    }
  }
}