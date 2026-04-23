import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'verification_repository.dart';
import '../domain/verification_request_model.dart';

part 'verification_provider.g.dart';

/// Provider untuk VerificationRepository
@riverpod
VerificationRepository verificationRepository(VerificationRepositoryRef ref) {
  return FirebaseVerificationRepository();
}

/// Provider untuk stream pending verification requests (admin)
@riverpod
Stream<List<VerificationRequestModel>> pendingVerificationRequests(
  PendingVerificationRequestsRef ref,
) {
  final repository = ref.watch(verificationRepositoryProvider);
  return repository.watchPendingRequests();
}

/// Provider untuk verification request by teacher ID
@riverpod
Future<VerificationRequestModel?> verificationRequest(
  VerificationRequestRef ref,
  String teacherId,
) {
  final repository = ref.watch(verificationRepositoryProvider);
  return repository.getVerificationRequest(teacherId);
}

/// Controller untuk verification operations
@riverpod
class VerificationController extends _$VerificationController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  /// Create verification request for teacher
  Future<void> createVerificationRequest(String teacherId, String teacherName) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(verificationRepositoryProvider);
      await repository.createVerificationRequest(teacherId, teacherName);
      
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Approve verification request
  Future<void> approveVerification(String requestId, String teacherId) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(verificationRepositoryProvider);
      await repository.approveVerification(requestId, teacherId);
      
      // Invalidate related providers to refresh UI
      ref.invalidate(pendingVerificationRequestsProvider);
      
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Reject verification request
  Future<void> rejectVerification(String requestId, String teacherId, String reason) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(verificationRepositoryProvider);
      await repository.rejectVerification(requestId, teacherId, reason);
      
      // Invalidate related providers to refresh UI
      ref.invalidate(pendingVerificationRequestsProvider);
      
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Validate institution code
  Future<bool> validateInstitutionCode(String code) async {
    try {
      final repository = ref.read(verificationRepositoryProvider);
      return await repository.validateInstitutionCode(code);
    } catch (e) {
      return false;
    }
  }
}