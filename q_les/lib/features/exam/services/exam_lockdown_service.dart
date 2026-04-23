import '../domain/suspicious_gesture.dart';

/// Abstract service for exam lockdown functionality
abstract class ExamLockdownService {
  /// Start lockdown mode for exam
  Future<void> startLockdown(String examId, String studentId);

  /// Stop lockdown mode
  Future<void> stopLockdown();

  /// Stream of suspicious gestures during exam
  Stream<SuspiciousGesture> get suspiciousGestureStream;
}