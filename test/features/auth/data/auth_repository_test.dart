import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:q_les/features/auth/data/auth_repository.dart';
import 'package:q_les/core/errors/app_exception.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('FirebaseAuthRepository', () {
    late FirebaseAuthRepository repository;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseMessaging mockMessaging;
    late MockUserCredential mockUserCredential;
    late MockUser mockUser;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockDocumentSnapshot mockUserSnapshot;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockMessaging = MockFirebaseMessaging();
      mockUserCredential = MockUserCredential();
      mockUser = MockUser();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();
      mockUserSnapshot = MockDocumentSnapshot();

      repository = FirebaseAuthRepository(
        firebaseAuth: mockAuth,
        firestore: mockFirestore,
        messaging: mockMessaging,
      );

      // Setup common mocks
      when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
      when(() => mockMessaging.getToken()).thenAnswer((_) async => 'test-fcm-token');
    });

    group('register', () {
      test('should register murid successfully', () async {
        // Arrange
        const email = 'murid@test.com';
        const password = 'password123';
        const fullName = 'Test Murid';
        const role = 'murid';
        const uid = 'test-uid-123';

        when(() => mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockUserCredential);
        
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(uid);
        
        when(() => mockUserDoc.set(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.register(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
        );

        // Assert
        expect(result.uid, equals(uid));
        expect(result.fullName, equals(fullName));
        expect(result.email, equals(email));
        expect(result.role, equals(role));
        expect(result.fcmToken, equals('test-fcm-token'));
        expect(result.verificationStatus, isNull); // Murid tidak perlu verifikasi

        verify(() => mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).called(1);
        verify(() => mockUserDoc.set(any())).called(1);
      });

      test('should register guru with pending verification', () async {
        // Arrange
        const email = 'guru@test.com';
        const password = 'password123';
        const fullName = 'Test Guru';
        const role = 'guru';
        const uid = 'test-uid-456';

        when(() => mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockUserCredential);
        
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(uid);
        
        when(() => mockUserDoc.set(any())).thenAnswer((_) async {});
        
        // Mock verification request creation
        final mockVerificationCollection = MockCollectionReference();
        when(() => mockFirestore.collection('verification_requests'))
            .thenReturn(mockVerificationCollection);
        when(() => mockVerificationCollection.add(any())).thenAnswer((_) async => mockUserDoc);

        // Act
        final result = await repository.register(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
        );

        // Assert
        expect(result.uid, equals(uid));
        expect(result.fullName, equals(fullName));
        expect(result.email, equals(email));
        expect(result.role, equals(role));
        expect(result.verificationStatus, equals('pending')); // Guru perlu verifikasi

        verify(() => mockVerificationCollection.add(any())).called(1);
      });

      test('should throw AppException when Firebase Auth fails', () async {
        // Arrange
        when(() => mockAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use',
        ));

        // Act & Assert
        expect(
          () => repository.register(
            email: 'test@test.com',
            password: 'password',
            fullName: 'Test User',
            role: 'murid',
          ),
          throwsA(isA<AppException>().having(
            (e) => e.message,
            'message',
            'Email sudah digunakan',
          )),
        );
      });
    });

    group('login', () {
      test('should login successfully', () async {
        // Arrange
        const email = 'test@test.com';
        const password = 'password123';
        const uid = 'test-uid-123';
        
        final userData = {
          'fullName': 'Test User',
          'email': email,
          'role': 'murid',
          'photoUrl': null,
          'fcmToken': 'old-token',
          'verificationStatus': null,
        };

        when(() => mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockUserCredential);
        
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(uid);
        
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockUserSnapshot);
        when(() => mockUserSnapshot.exists).thenReturn(true);
        when(() => mockUserSnapshot.data()).thenReturn(userData);
        
        when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.login(email, password);

        // Assert
        expect(result.uid, equals(uid));
        expect(result.email, equals(email));
        expect(result.role, equals('murid'));
        
        verify(() => mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).called(1);
        verify(() => mockUserDoc.update({'fcmToken': 'test-fcm-token'})).called(1);
      });

      test('should throw AppException when user not found in Firestore', () async {
        // Arrange
        when(() => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockUserCredential);
        
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('test-uid');
        
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockUserSnapshot);
        when(() => mockUserSnapshot.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => repository.login('test@test.com', 'password'),
          throwsA(isA<AppException>().having(
            (e) => e.message,
            'message',
            'Data pengguna tidak ditemukan',
          )),
        );
      });

      test('should map Firebase Auth errors correctly', () async {
        // Arrange
        when(() => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Invalid credential',
        ));

        // Act & Assert
        expect(
          () => repository.login('test@test.com', 'wrongpassword'),
          throwsA(isA<AppException>().having(
            (e) => e.message,
            'message',
            'Email atau password tidak valid',
          )),
        );
      });
    });

    group('logout', () {
      test('should logout successfully', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await repository.logout();

        // Assert
        verify(() => mockAuth.signOut()).called(1);
      });

      test('should throw AppException when logout fails', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.logout(),
          throwsA(isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('Gagal keluar'),
          )),
        );
      });
    });
  });
}