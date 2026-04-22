import 'package:flutter_test/flutter_test.dart';
import 'package:q_les/features/auth/domain/user_model.dart';

void main() {
  group('UserModel', () {
    const testUserData = {
      'uid': 'test-uid-123',
      'fullName': 'John Doe',
      'email': 'john@example.com',
      'role': 'murid',
      'photoUrl': 'https://example.com/photo.jpg',
      'fcmToken': 'fcm-token-123',
      'verificationStatus': null,
    };

    const testUser = UserModel(
      uid: 'test-uid-123',
      fullName: 'John Doe',
      email: 'john@example.com',
      role: 'murid',
      photoUrl: 'https://example.com/photo.jpg',
      fcmToken: 'fcm-token-123',
      verificationStatus: null,
    );

    test('should create UserModel from JSON', () {
      final user = UserModel.fromJson(testUserData);
      
      expect(user.uid, equals('test-uid-123'));
      expect(user.fullName, equals('John Doe'));
      expect(user.email, equals('john@example.com'));
      expect(user.role, equals('murid'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      expect(user.fcmToken, equals('fcm-token-123'));
      expect(user.verificationStatus, isNull);
    });

    test('should convert UserModel to JSON', () {
      final json = testUser.toJson();
      
      expect(json['uid'], equals('test-uid-123'));
      expect(json['fullName'], equals('John Doe'));
      expect(json['email'], equals('john@example.com'));
      expect(json['role'], equals('murid'));
      expect(json['photoUrl'], equals('https://example.com/photo.jpg'));
      expect(json['fcmToken'], equals('fcm-token-123'));
      expect(json['verificationStatus'], isNull);
    });

    test('should convert to Firestore format (without uid)', () {
      final firestoreData = testUser.toFirestore();
      
      expect(firestoreData.containsKey('uid'), isFalse);
      expect(firestoreData['fullName'], equals('John Doe'));
      expect(firestoreData['email'], equals('john@example.com'));
      expect(firestoreData['role'], equals('murid'));
    });

    group('Role helpers', () {
      test('should identify murid correctly', () {
        const murid = UserModel(
          uid: 'uid',
          fullName: 'Murid Test',
          email: 'murid@test.com',
          role: 'murid',
        );
        
        expect(murid.isMurid, isTrue);
        expect(murid.isGuru, isFalse);
        expect(murid.isAdmin, isFalse);
      });

      test('should identify guru correctly', () {
        const guru = UserModel(
          uid: 'uid',
          fullName: 'Guru Test',
          email: 'guru@test.com',
          role: 'guru',
          verificationStatus: 'verified',
        );
        
        expect(guru.isGuru, isTrue);
        expect(guru.isMurid, isFalse);
        expect(guru.isAdmin, isFalse);
      });

      test('should identify admin correctly', () {
        const admin = UserModel(
          uid: 'uid',
          fullName: 'Admin Test',
          email: 'admin@test.com',
          role: 'admin',
        );
        
        expect(admin.isAdmin, isTrue);
        expect(admin.isGuru, isFalse);
        expect(admin.isMurid, isFalse);
      });
    });

    group('Verification status helpers', () {
      test('should identify verified guru', () {
        const verifiedGuru = UserModel(
          uid: 'uid',
          fullName: 'Verified Guru',
          email: 'verified@test.com',
          role: 'guru',
          verificationStatus: 'verified',
        );
        
        expect(verifiedGuru.isVerified, isTrue);
        expect(verifiedGuru.isPending, isFalse);
        expect(verifiedGuru.isRejected, isFalse);
        expect(verifiedGuru.canCreateContent, isTrue);
      });

      test('should identify pending guru', () {
        const pendingGuru = UserModel(
          uid: 'uid',
          fullName: 'Pending Guru',
          email: 'pending@test.com',
          role: 'guru',
          verificationStatus: 'pending',
        );
        
        expect(pendingGuru.isPending, isTrue);
        expect(pendingGuru.isVerified, isFalse);
        expect(pendingGuru.isRejected, isFalse);
        expect(pendingGuru.canCreateContent, isFalse);
      });

      test('should identify rejected guru', () {
        const rejectedGuru = UserModel(
          uid: 'uid',
          fullName: 'Rejected Guru',
          email: 'rejected@test.com',
          role: 'guru',
          verificationStatus: 'rejected',
        );
        
        expect(rejectedGuru.isRejected, isTrue);
        expect(rejectedGuru.isVerified, isFalse);
        expect(rejectedGuru.isPending, isFalse);
        expect(rejectedGuru.canCreateContent, isFalse);
      });

      test('should allow murid to create content (no verification needed)', () {
        const murid = UserModel(
          uid: 'uid',
          fullName: 'Murid Test',
          email: 'murid@test.com',
          role: 'murid',
        );
        
        expect(murid.canCreateContent, isTrue);
      });
    });
  });
}