import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/verification_request_model.dart';

/// Abstract repository for verification operations
abstract class VerificationRepository {
  /// Create verification request for teacher
  Future<void> createVerificationRequest(String teacherId, String teacherName);
  
  /// Get all pending verification requests (for admin)
  Stream<List<VerificationRequestModel>> watchPendingRequests();
  
  /// Approve verification request
  Future<void> approveVerification(String requestId, String teacherId);
  
  /// Reject verification request
  Future<void> rejectVerification(String requestId, String teacherId, String reason);
  
  /// Check if verification code is valid (optional feature)
  Future<bool> validateInstitutionCode(String code);
  
  /// Get verification request by teacher ID
  Future<VerificationRequestModel?> getVerificationRequest(String teacherId);
}

/// Firebase implementation of VerificationRepository
class FirebaseVerificationRepository implements VerificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createVerificationRequest(String teacherId, String teacherName) async {
    try {
      final requestId = _firestore.collection(FirestorePaths.verificationRequests).doc().id;
      
      final request = VerificationRequestModel(
        id: requestId,
        teacherId: teacherId,
        teacherName: teacherName,
        status: VerificationStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore
          .doc(FirestorePaths.verificationRequest(requestId))
          .set(request.toJson());
    } catch (e) {
      throw AppException('Gagal membuat permintaan verifikasi: ${e.toString()}');
    }
  }

  @override
  Stream<List<VerificationRequestModel>> watchPendingRequests() {
    return _firestore
        .collection(FirestorePaths.verificationRequests)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequestModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  @override
  Future<void> approveVerification(String requestId, String teacherId) async {
    try {
      final batch = _firestore.batch();
      
      // Update verification request status
      batch.update(
        _firestore.doc(FirestorePaths.verificationRequest(requestId)),
        {
          'status': 'verified',
          'reviewedAt': FieldValue.serverTimestamp(),
        },
      );
      
      // Update user verification status
      batch.update(
        _firestore.doc(FirestorePaths.user(teacherId)),
        {'verificationStatus': 'verified'},
      );
      
      await batch.commit();
    } catch (e) {
      throw AppException('Gagal menyetujui verifikasi: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectVerification(String requestId, String teacherId, String reason) async {
    try {
      final batch = _firestore.batch();
      
      // Update verification request status
      batch.update(
        _firestore.doc(FirestorePaths.verificationRequest(requestId)),
        {
          'status': 'rejected',
          'rejectionReason': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
        },
      );
      
      // Update user verification status
      batch.update(
        _firestore.doc(FirestorePaths.user(teacherId)),
        {'verificationStatus': 'rejected'},
      );
      
      await batch.commit();
    } catch (e) {
      throw AppException('Gagal menolak verifikasi: ${e.toString()}');
    }
  }

  @override
  Future<bool> validateInstitutionCode(String code) async {
    try {
      final doc = await _firestore
          .doc(FirestorePaths.verificationCode(code))
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final isActive = data['isActive'] as bool? ?? false;
      final expiresAt = data['expiresAt'] as Timestamp?;
      
      if (!isActive) return false;
      
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<VerificationRequestModel?> getVerificationRequest(String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.verificationRequests)
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      return VerificationRequestModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    } catch (e) {
      return null;
    }
  }
}