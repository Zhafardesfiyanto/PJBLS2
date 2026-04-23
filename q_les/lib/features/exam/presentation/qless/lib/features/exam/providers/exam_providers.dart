import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/exam_question.dart';
import '../../../shared/models/sync_status.dart';
import '../../student/providers/student_providers.dart';
import '../services/anti_cheat_monitor.dart';

/// The active exam ID used to load questions.
/// Defaults to `'current'` and can be overridden when navigating to the exam.
final currentExamIdProvider = StateProvider<String>((ref) => 'current');

/// Loads the list of [ExamQuestion]s for the current exam from Firebase.
/// Watches [examServiceProvider] and [currentExamIdProvider].
/// Satisfies Requirements 8.1.
final examQuestionsProvider = FutureProvider<List<ExamQuestion>>((ref) async {
  final examService = ref.watch(examServiceProvider);
  final examId = ref.watch(currentExamIdProvider);
  return examService.loadQuestions(examId);
});

/// Tracks the current cloud sync status for the exam interface.
/// Defaults to [SyncStatus.synced].
/// Satisfies Requirements 8.5.
final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.synced);

/// Provides an [AntiCheatMonitor] scoped to the current student session.
/// Reads the student ID from [FirebaseAuth.instance.currentUser?.uid].
/// Disposes the monitor when the provider is no longer used.
final antiCheatMonitorProvider = Provider<AntiCheatMonitor>((ref) {
  final studentId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final monitor = WidgetsBindingObserverAntiCheatMonitor(studentId: studentId);
  ref.onDispose(() => monitor.dispose());
  return monitor;
});
