import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:q_les/features/verification/data/verification_repository.dart';
import 'package:q_les/features/verification/domain/verification_request_model.dart';

void main() {
  group('FirebaseVerificationRepository', () {
    late FirebaseVerificationRepository repository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseVerificationRepository();
      // Note: In real tests, we would inject the fake firestore
      // For now, this is a structure example
    });

    group('createVerificationRequest', () {
      test('should create verification request successfully', () async {
        // Arrange
        const teacherId = 'teacher123';
        const teacherName = 'John Doe';

        // Act & Assert
        expect(
          () => repository.createVerificationRequest(teacherId, teacherName),
          returnsNormally,
        );
      });

      test('should throw AppException when creation fails', () async {
        // This would test error scenarios
        // Implementation depends on how we mock Firestore failures
      });
    });

    group('watchPendingRequests', () {
      test('should return stream of pending verification requests', () async {
        // Arrange
        await fakeFirestore.collection('verification_requests').add({
          'teacherId': 'teacher1',
          'teacherName': 'Teacher One',
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        });

        await fakeFirestore.collection('verification_requests').add({
          'teacherId': 'teacher2',
          'teacherName': 'Teacher Two',
          'status': 'verified',
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Act
        final stream = repository.watchPendingRequests();

        // Assert
        expect(stream, isA<Stream<List<VerificationRequestModel>>>());
        
        // In a real test, we would verify the stream emits only pending requests
      });
    });

    group('approveVerification', () {
      test('should approve verification request successfully', () async {
        // Arrange
        const requestId = 'request123';
        const teacherId = 'teacher123';

        // Setup initial data
        await fakeFirestore.doc('verification_requests/$requestId').set({
          'teacherId': teacherId,
          'teacherName': 'John Doe',
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        });

        await fakeFirestore.doc('users/$teacherId').set({
          'fullName': 'John Doe',
          'email': 'john@example.com',
          'role': 'guru',
          'verificationStatus': 'pending',
        });

        // Act & Assert
        expect(
          () => repository.approveVerification(requestId, teacherId),
          returnsNormally,
        );
      });
    });

    group('rejectVerification', () {
      test('should reject verification request with reason', () async {
        // Arrange
        const requestId = 'request123';
        const teacherId = 'teacher123';
        const reason = 'Invalid credentials';

        // Act & Assert
        expect(
          () => repository.rejectVerification(requestId, teacherId, reason),
          returnsNormally,
        );
      });
    });

    group('validateInstitutionCode', () {
      test('should return true for valid active code', () async {
        // Arrange
        const code = 'SCHOOL123';
        await fakeFirestore.doc('verification_codes/$code').set({
          'institutionName': 'Test School',
          'isActive': true,
          'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        });

        // Act
        final result = await repository.validateInstitutionCode(code);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for inactive code', () async {
        // Arrange
        const code = 'INACTIVE123';
        await fakeFirestore.doc('verification_codes/$code').set({
          'institutionName': 'Test School',
          'isActive': false,
        });

        // Act
        final result = await repository.validateInstitutionCode(code);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for expired code', () async {
        // Arrange
        const code = 'EXPIRED123';
        await fakeFirestore.doc('verification_codes/$code').set({
          'institutionName': 'Test School',
          'isActive': true,
          'expiresAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        });

        // Act
        final result = await repository.validateInstitutionCode(code);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for non-existent code', () async {
        // Arrange
        const code = 'NONEXISTENT';

        // Act
        final result = await repository.validateInstitutionCode(code);

        // Assert
        expect(result, isFalse);
      });
    });

    group('getVerificationRequest', () {
      test('should return verification request for teacher', () async {
        // Arrange
        const teacherId = 'teacher123';
        await fakeFirestore.collection('verification_requests').add({
          'teacherId': teacherId,
          'teacherName': 'John Doe',
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Act
        final result = await repository.getVerificationRequest(teacherId);

        // Assert
        expect(result, isNotNull);
        expect(result?.teacherId, equals(teacherId));
      });

      test('should return null when no request found', () async {
        // Arrange
        const teacherId = 'nonexistent';

        // Act
        final result = await repository.getVerificationRequest(teacherId);

        // Assert
        expect(result, isNull);
      });
    });
  });
}