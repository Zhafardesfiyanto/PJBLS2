import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:q_les/features/auth/domain/user_model.dart';
import 'package:q_les/core/errors/app_exception.dart';

void main() {
  group('Authentication Properties', () {
    // Property 2: UserModel role helpers akurat
    group('Property 2: UserModel role helpers akurat', () {
      test('isGuru benar untuk role guru', () {
        const user = UserModel(
          uid: 'uid1', fullName: 'Guru', email: 'g@test.com', role: 'guru',
        );
        expect(user.isGuru, isTrue);
        expect(user.isMurid, isFalse);
        expect(user.isAdmin, isFalse);
      });

      test('isMurid benar untuk role murid', () {
        const user = UserModel(
          uid: 'uid2', fullName: 'Murid', email: 'm@test.com', role: 'murid',
        );
        expect(user.isMurid, isTrue);
        expect(user.isGuru, isFalse);
        expect(user.isAdmin, isFalse);
      });

      test('isAdmin benar untuk role admin', () {
        const user = UserModel(
          uid: 'uid3', fullName: 'Admin', email: 'a@test.com', role: 'admin',
        );
        expect(user.isAdmin, isTrue);
        expect(user.isGuru, isFalse);
        expect(user.isMurid, isFalse);
      });
    });

    // Property 3: Pesan error tidak membocorkan detail
    group('Property 3: FirebaseErrorMapper tidak membocorkan detail', () {
      test('user-not-found menghasilkan pesan generik', () {
        final e = FirebaseAuthException(code: 'user-not-found');
        final msg = FirebaseErrorMapper.mapAuthError(e);
        expect(msg, equals('Email atau password tidak valid.'));
        expect(msg, isNot(contains('user-not-found')));
      });

      test('wrong-password menghasilkan pesan generik', () {
        final e = FirebaseAuthException(code: 'wrong-password');
        final msg = FirebaseErrorMapper.mapAuthError(e);
        expect(msg, equals('Email atau password tidak valid.'));
      });

      test('invalid-credential menghasilkan pesan generik', () {
        final e = FirebaseAuthException(code: 'invalid-credential');
        final msg = FirebaseErrorMapper.mapAuthError(e);
        expect(msg, equals('Email atau password tidak valid.'));
      });
    });

    // Property 4: Logout menghapus sesi
    group('Property 4: Logout menghapus sesi aktif', () {
      test('signOut mengubah currentUser menjadi null', () async {
        final auth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'test-uid', email: 'test@test.com'),
          signedIn: true,
        );

        expect(auth.currentUser, isNotNull);
        await auth.signOut();
        expect(auth.currentUser, isNull);
      });
    });

    // Property 26 & 27: Guru baru punya status pending, tidak bisa buat konten
    group('Property 26 & 27: Verifikasi status guru', () {
      test('Guru baru punya verificationStatus pending', () {
        const user = UserModel(
          uid: 'guru-uid',
          fullName: 'Guru Baru',
          email: 'guru@test.com',
          role: 'guru',
          verificationStatus: 'pending',
        );
        expect(user.isPending, isTrue);
        expect(user.isVerified, isFalse);
        expect(user.canCreateContent, isFalse);
      });

      test('Guru ditolak tidak bisa buat konten', () {
        const user = UserModel(
          uid: 'guru-uid',
          fullName: 'Guru Rejected',
          email: 'guru@test.com',
          role: 'guru',
          verificationStatus: 'rejected',
        );
        expect(user.isRejected, isTrue);
        expect(user.canCreateContent, isFalse);
      });

      test('Guru terverifikasi bisa buat konten', () {
        const user = UserModel(
          uid: 'guru-uid',
          fullName: 'Guru Verified',
          email: 'guru@test.com',
          role: 'guru',
          verificationStatus: 'verified',
        );
        expect(user.isVerified, isTrue);
        expect(user.canCreateContent, isTrue);
      });

      test('Murid selalu bisa akses konten', () {
        const user = UserModel(
          uid: 'murid-uid',
          fullName: 'Murid',
          email: 'murid@test.com',
          role: 'murid',
        );
        expect(user.canCreateContent, isTrue);
      });
    });
  });
}
