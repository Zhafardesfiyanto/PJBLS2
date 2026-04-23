import 'package:firebase_auth/firebase_auth.dart';

/// Custom exception class untuk aplikasi
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Mapper untuk Firebase Auth error codes ke pesan Bahasa Indonesia
class FirebaseErrorMapper {
  static String mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'Email sudah digunakan.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' || 'invalid-email'
          => 'Email atau password tidak valid.',
      'weak-password' => 'Password terlalu lemah. Minimal 6 karakter.',
      'network-request-failed' => 'Tidak ada koneksi internet. Periksa koneksi dan coba lagi.',
      'too-many-requests' => 'Terlalu banyak percobaan login. Coba lagi nanti.',
      'user-disabled' => 'Akun ini telah dinonaktifkan.',
      _ => 'Terjadi kesalahan. Silakan coba lagi.',
    };
  }
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Unauthorized exception
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}

/// Not found exception
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException(super.message);
}
