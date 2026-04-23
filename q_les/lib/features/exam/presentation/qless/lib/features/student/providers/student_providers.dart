import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qless/features/exam/services/exam_service.dart';
import 'package:qless/shared/models/class_model.dart';
import 'package:qless/shared/models/exam_schedule.dart';
import 'package:qless/shared/services/class_service.dart';

/// Provides the [ClassService] implementation.
final classServiceProvider = Provider<ClassService>((ref) {
  return HttpClassService();
});

/// Fetches the authenticated student's joined classes from the Laravel API.
/// Reads the current user's UID from [FirebaseAuth.instance.currentUser].
/// Satisfies Requirements 3.1.
final classListProvider = FutureProvider<List<ClassModel>>((ref) async {
  final classService = ref.watch(classServiceProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return classService.fetchStudentClasses(uid);
});

/// Provides the [ExamService] implementation.
final examServiceProvider = Provider<ExamService>((ref) {
  return FirebaseExamService();
});

/// Watches the active exam schedule from Firebase Realtime Database.
/// Emits [ExamSchedule] when an exam is scheduled, or `null` when none is active.
/// Satisfies Requirements 4.1.
final examCountdownProvider = StreamProvider<ExamSchedule?>((ref) {
  final examService = ref.watch(examServiceProvider);
  return examService.watchExamSchedule();
});
