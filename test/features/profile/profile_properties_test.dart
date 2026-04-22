import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:q_les/features/profile/data/profile_repository.dart';
import 'package:q_les/features/auth/domain/user_model.dart';
import 'package:q_les/core/errors/app_exception.dart';

class MockFile extends Mock implements File {}

void main() {
  group('Profile Properties', () {
    late FirebaseProfileRepository repository;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      repository = FirebaseProfileRepository(
        firestore: fakeFirestore,
        storage: mockStorage,
      );
    });

    // Property 24: Upload foto profil memperbarui URL di Firestore
    group('Property 24: Upload foto profil memperbarui URL di Firestore', () {
      for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
        test('upload file $ext berhasil dan update Firestore', () async {
          const uid = 'test-uid-123';
          final mockFile = MockFile();
          when(() => mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
          when(() => mockFile.path).thenReturn('/path/to/image$ext');

          await fakeFirestore.collection('users').doc(uid).set({
            'fullName': 'Test User',
            'email': 'test@example.com',
            'role': 'murid',
          });

          final photoUrl = await repository.uploadProfilePhoto(mockFile, uid);
          await repository.updateProfilePhotoUrl(uid, photoUrl);

          final doc = await fakeFirestore.collection('users').doc(uid).get();
          expect(doc.exists, isTrue);
          expect(doc.data()!['photoUrl'], equals(photoUrl));
          expect(photoUrl, isA<String>());
        });
      }
    });

    // Property 25: Validasi file foto menolak ukuran dan format tidak valid
    group('Property 25: Validasi file foto menolak ukuran dan format tidak valid', () {
      test('file > 5MB ditolak', () {
        final mockFile = MockFile();
        when(() => mockFile.lengthSync()).thenReturn(6 * 1024 * 1024); // 6MB
        when(() => mockFile.path).thenReturn('/path/to/image.jpg');

        expect(
          () => repository.uploadProfilePhoto(mockFile, 'uid'),
          throwsA(isA<AppException>().having(
            (e) => e.message, 'message', 'Ukuran file terlalu besar. Maksimal 5 MB.',
          )),
        );
      });

      for (final ext in ['.pdf', '.doc', '.txt', '.mp4', '.zip']) {
        test('format $ext ditolak', () {
          final mockFile = MockFile();
          when(() => mockFile.lengthSync()).thenReturn(1024 * 1024);
          when(() => mockFile.path).thenReturn('/path/to/file$ext');

          expect(
            () => repository.uploadProfilePhoto(mockFile, 'uid'),
            throwsA(isA<AppException>().having(
              (e) => e.message, 'message', 'Format file tidak didukung. Gunakan JPEG, PNG, atau WebP.',
            )),
          );
        });
      }

      test('photoUrl tidak berubah setelah upload gagal', () async {
        const uid = 'test-uid';
        await fakeFirestore.collection('users').doc(uid).set({
          'fullName': 'Test User',
          'email': 'test@example.com',
          'role': 'murid',
          'photoUrl': 'https://existing-url.com/photo.jpg',
        });

        final mockFile = MockFile();
        when(() => mockFile.lengthSync()).thenReturn(10 * 1024 * 1024); // 10MB
        when(() => mockFile.path).thenReturn('/path/to/image.jpg');

        try {
          await repository.uploadProfilePhoto(mockFile, uid);
        } catch (_) {}

        final doc = await fakeFirestore.collection('users').doc(uid).get();
        expect(doc.data()!['photoUrl'], equals('https://existing-url.com/photo.jpg'));
      });
    });

    // Property: Update foto profil di semua pesan chat
    group('Property: Update foto profil di semua pesan chat', () {
      test('update foto hanya mempengaruhi pesan dari user yang bersangkutan', () async {
        const uid = 'user-123';
        const photoUrl = 'https://example.com/new-photo.jpg';
        const userName = 'Updated Name';

        // Tambah pesan dari user ini
        for (int i = 0; i < 3; i++) {
          await fakeFirestore.collection('class_messages').add({
            'senderId': uid,
            'senderName': 'Old Name',
            'senderPhotoUrl': 'old-url',
            'content': 'Message $i',
            'isDeleted': false,
            'sentAt': DateTime.now(),
          });
        }

        // Tambah pesan dari user lain
        await fakeFirestore.collection('class_messages').add({
          'senderId': 'other-uid',
          'senderName': 'Other User',
          'senderPhotoUrl': 'other-url',
          'content': 'Other message',
          'isDeleted': false,
          'sentAt': DateTime.now(),
        });

        await repository.updatePhotoInChatMessages(uid, photoUrl, userName);

        final updatedMessages = await fakeFirestore
            .collection('class_messages')
            .where('senderId', isEqualTo: uid)
            .get();

        for (final doc in updatedMessages.docs) {
          expect(doc.data()['senderPhotoUrl'], equals(photoUrl));
          expect(doc.data()['senderName'], equals(userName));
        }

        final otherMessages = await fakeFirestore
            .collection('class_messages')
            .where('senderId', isEqualTo: 'other-uid')
            .get();

        for (final doc in otherMessages.docs) {
          expect(doc.data()['senderPhotoUrl'], equals('other-url'));
        }
      });
    });

    // Property: Profile update round-trip consistency
    group('Property: Profile update round-trip consistency', () {
      test('data profil tersimpan dan bisa diambil kembali dengan benar', () async {
        const uid = 'round-trip-uid';
        const name = 'Test User';
        const email = 'test@example.com';
        const role = 'guru';
        const photoUrl = 'https://example.com/photo.jpg';

        final user = UserModel(
          uid: uid,
          fullName: name,
          email: email,
          role: role,
          photoUrl: photoUrl,
        );

        await repository.updateProfile(user);

        final doc = await fakeFirestore.collection('users').doc(uid).get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['fullName'], equals(name));
        expect(doc.data()!['email'], equals(email));
        expect(doc.data()!['role'], equals(role));
        expect(doc.data()!['photoUrl'], equals(photoUrl));
      });
    });
  });
}
