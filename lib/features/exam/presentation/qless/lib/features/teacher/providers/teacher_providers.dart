import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qless/features/exam/providers/exam_providers.dart';
import 'package:qless/features/student/providers/student_providers.dart';
import 'package:qless/shared/models/audit_entry.dart';
import 'package:qless/shared/models/student_model.dart';
import 'package:qless/shared/services/audit_log_service.dart';

export 'package:qless/features/exam/providers/exam_providers.dart'
    show currentExamIdProvider;

/// Provides the [AuditLogService] implementation.
/// Satisfies Requirements 7.1.
final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  return FirebaseAuditLogService();
});

/// Holds the current class ID used by [studentRosterProvider].
/// Defaults to `'default'` and can be overridden at runtime.
final currentClassIdProvider = StateProvider<String>((ref) => 'default');

/// Fetches the student roster for the teacher's current class.
/// Reads [currentClassIdProvider] for the class ID and calls
/// [ClassService.fetchClassRoster].
/// Satisfies Requirements 6.1.
final studentRosterProvider = FutureProvider<List<StudentModel>>((ref) async {
  final classService = ref.watch(classServiceProvider);
  final classId = ref.watch(currentClassIdProvider);
  return classService.fetchClassRoster(classId);
});

/// Streams the 50 most recent audit log entries for the current exam.
/// Watches [auditLogServiceProvider] and [currentExamIdProvider].
/// Satisfies Requirements 7.1.
final auditLogProvider = StreamProvider<List<AuditEntry>>((ref) {
  final auditLogService = ref.watch(auditLogServiceProvider);
  final examId = ref.watch(currentExamIdProvider);
  return auditLogService.watchAuditLog(examId, limit: 50);
});

/// Streams the current exam active state from Firebase.
/// Watches [examServiceProvider] and calls [ExamService.watchExamActive].
/// Satisfies Requirements 5.1.
final examToggleProvider = StreamProvider<bool>((ref) {
  final examService = ref.watch(examServiceProvider);
  return examService.watchExamActive();
});
