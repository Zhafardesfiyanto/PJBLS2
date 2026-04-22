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
  group('FirebaseProfileRepository', () {
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

    group('updateProfile', () {
      test('should update user profile in Firestore', () async {
        // Arrange
        const user = UserModel(
          uid: 'test-uid',
          fullName: 'Test User',
          email: 'test@example.com',
          role: 'murid',
        );

        // Act
        await repository.updateProfile(user);

        // Assert
        final doc = await fakeFirestore.collection('users').doc('test-uid').get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['fullName'], equals('Test User'));
        expect(doc.data()!['email'], equals('test@example.com'));
        expect(doc.data()!['role'], equals('murid'));
      });
    });

    group('uploadProfilePhoto', () {
      test('should upload photo and return download URL for valid file', () async {
        // Arrange
        final mockFile = MockFile();
        when(() => mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
        when(() => mockFile.path).thenReturn('/path/to/image.jpg');

        // Act
        final result = await repository.uploadProfilePhoto(mockFile, 'test-uid');

        // Assert
        expect(result, isA<String>());
        expect(result.startsWith('https://'), isTrue);
      });

      test('should throw AppException for file size > 5MB', () async {
        // Arrange
        final mockFile = MockFile();
        when(() => mockFile.lengthSync()).thenReturn(6 * 1024 * 1024); // 6MB
        when(() => mockFile.path).thenReturn('/path/to/image.jpg');

        // Act & Assert
        expect(
          () => repository.uploadProfilePhoto(mockFile, 'test-uid'),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              'Ukuran file terlalu besar. Maksimal 5 MB.',
            ),
          ),
        );
      });

      test('should throw AppException for unsupported file format', () async {
        // Arrange
        final mockFile = MockFile();
        when(() => mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
        when(() => mockFile.path).thenReturn('/path/to/document.pdf');

        // Act & Assert
        expect(
          () => repository.uploadProfilePhoto(mockFile, 'test-uid'),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              'Format file tidak didukung. Gunakan JPEG, PNG, atau WebP.',
            ),
          ),
        );
      });

      test('should accept JPEG format', () async {
        // Arrange
        final mockFile = MockFile();
        when(() => mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
        when(() => mockFile.path).thenReturn('/path/to/image.jpeg');

        // Act
        final result = await repository.uploadProfilePhoto(mockFile, 'test-uid');

        // Assert
        expect(result, isA<String>());
      });

      test('should accept PNG format', () async {
        // Arrange
        final mockFile = MockFile();
        when(() => mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
        when(() => mockFile.path).thenReturn('/path/to/image.png');

        // Act
        final result = await repository.uploadProfilePhoto(mockFile, 'test-uid');

        // Assert
        expect(result, isA<String>());
      });

      test('should accept WebP format', () async {
        // Arrange
        final mockFile = MockFile();
        when(() => mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
        when(() => mockFile.path).thenReturn('/path/to/image.webp');

        // Act
        final result = await repository.uploadProfilePhoto(mockFile, 'test-uid');

        // Assert
        expect(result, isA<String>());
      });
    });

    group('updateProfilePhotoUrl', () {
      test('should update photoUrl in Firestore', () async {
        // Arrange
        const uid = 'test-uid';
        const photoUrl = 'https://example.com/photo.jpg';

        // Pre-populate user document
        await fakeFirestore.collection('users').doc(uid).set({
          'fullName': 'Test User',
          'email': 'test@example.com',
          'role': 'murid',
        });

        // Act
        await repository.updateProfilePhotoUrl(uid, photoUrl);

        // Assert
        final doc = await fakeFirestore.collection('users').doc(uid).get();
        expect(doc.data()!['photoUrl'], equals(photoUrl));
      });
    });

    group('updatePhotoInChatMessages', () {
      test('should update photo URL in class messages', () async {
        // Arrange
        const uid = 'test-uid';
        const photoUrl = 'https://example.com/photo.jpg';
        const userName = 'Test User';

        // Pre-populate class messages
        await fakeFirestore.collection('class_messages').add({
          'senderId': uid,
          'senderName': 'Old Name',
          'senderPhotoUrl': 'old-url',
          'content': 'Hello',
          'isDeleted': false,
          'sentAt': DateTime.now(),
        });

        await fakeFirestore.collection('class_messages').add({
          'senderId': 'other-uid',
          'senderName': 'Other User',
          'content': 'Hi',
          'isDeleted': false,
          'sentAt': DateTime.now(),
        });

        // Act
        await repository.updatePhotoInChatMessages(uid, photoUrl, userName);

        // Assert
        final messages = await fakeFirestore
            .collection('class_messages')
            .where('senderId', isEqualTo: uid)
            .get();

        expect(messages.docs.length, equals(1));
        expect(messages.docs.first.data()['senderPhotoUrl'], equals(photoUrl));
        expect(messages.docs.first.data()['senderName'], equals(userName));
      });

      test('should update name in assignment messages', () async {
        // Arrange
        const uid = 'test-uid';
        const photoUrl = 'https://example.com/photo.jpg';
        const userName = 'Test User';

        // Pre-populate assignment messages
        await fakeFirestore.collection('assignment_messages').add({
          'senderId': uid,
          'senderName': 'Old Name',
          'content': 'Question about assignment',
          'isDeleted': false,
          'sentAt': DateTime.now(),
        });

        // Act
        await repository.updatePhotoInChatMessages(uid, photoUrl, userName);

        // Assert
        final messages = await fakeFirestore
            .collection('assignment_messages')
            .where('senderId', isEqualTo: uid)
            .get();

        expect(messages.docs.length, equals(1));
        expect(messages.docs.first.data()['senderName'], equals(userName));
      });

      test('should not throw exception if chat message update fails', () async {
        // Arrange
        const uid = 'test-uid';
        const photoUrl = 'https://example.com/photo.jpg';
        const userName = 'Test User';

        // Act & Assert - should not throw
        await repository.updatePhotoInChatMessages(uid, photoUrl, userName);
      });
    });
  });
}