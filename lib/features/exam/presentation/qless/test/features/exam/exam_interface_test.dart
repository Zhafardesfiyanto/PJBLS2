import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qless/features/exam/providers/exam_providers.dart';
import 'package:qless/features/exam/screens/exam_interface.dart';
import 'package:qless/features/exam/services/anti_cheat_monitor.dart';
import 'package:qless/features/exam/services/exam_service.dart';
import 'package:qless/features/student/providers/student_providers.dart';
import 'package:qless/features/teacher/providers/teacher_providers.dart'
    hide currentExamIdProvider;
import 'package:qless/shared/models/audit_entry.dart';
import 'package:qless/shared/models/cheat_event.dart';
import 'package:qless/shared/models/exam_question.dart';
import 'package:qless/shared/models/exam_schedule.dart';
import 'package:qless/shared/models/sync_status.dart';
import 'package:qless/shared/services/audit_log_service.dart';

// ---------------------------------------------------------------------------
// Fake implementations
// ---------------------------------------------------------------------------

/// A controllable [AntiCheatMonitor] that exposes a [StreamController] so
/// tests can manually emit violations.
class FakeAntiCheatMonitor implements AntiCheatMonitor {
  final StreamController<CheatEvent> _controller =
      StreamController<CheatEvent>.broadcast();

  @override
  Stream<CheatEvent> get violations => _controller.stream;

  @override
  void startMonitoring() {}

  @override
  void stopMonitoring() {}

  /// Emit a violation event from the test.
  void emitViolation(CheatEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}

/// A [ExamService] fake that records calls and can be configured to throw.
class FakeExamService implements ExamService {
  final List<Map<String, String>> submitCalls = [];
  bool shouldThrowOnSubmit = false;

  @override
  Stream<ExamSchedule?> watchExamSchedule() => Stream.value(null);

  @override
  Stream<bool> watchExamActive() => Stream.value(false);

  @override
  Future<void> setExamActive(bool active) async {}

  @override
  Future<List<ExamQuestion>> loadQuestions(String examId) async => [
        const ExamQuestion(id: 'q1', prompt: 'Describe photosynthesis.'),
        const ExamQuestion(id: 'q2', prompt: 'Explain Newton\'s laws.'),
      ];

  @override
  Future<void> autoSaveDraft(
      String examId, String questionId, String answer) async {}

  @override
  Future<void> submitExam(String examId, Map<String, String> answers) async {
    if (shouldThrowOnSubmit) {
      throw ExamSubmitException(
        'Laravel unreachable',
        syncStatus: SyncStatus.failed,
      );
    }
    submitCalls.add(answers);
  }
}

/// A no-op [AuditLogService] fake.
class FakeAuditLogService implements AuditLogService {
  final List<AuditEntry> recordedEntries = [];

  @override
  Stream<List<AuditEntry>> watchAuditLog(String examId, {int limit = 50}) =>
      Stream.value([]);

  @override
  Future<void> recordEntry(String examId, AuditEntry entry) async {
    recordedEntries.add(entry);
  }
}

// ---------------------------------------------------------------------------
// Helper — builds ExamInterface wrapped in ProviderScope
// ---------------------------------------------------------------------------

Widget buildExamInterface({
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: ExamInterface(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Convenience override builder
// ---------------------------------------------------------------------------

List<Override> baseOverrides({
  FakeAntiCheatMonitor? antiCheat,
  FakeExamService? examService,
  FakeAuditLogService? auditLog,
  SyncStatus syncStatus = SyncStatus.synced,
  List<ExamQuestion>? questions,
}) {
  final fakeExam = examService ?? FakeExamService();
  final fakeAntiCheat = antiCheat ?? FakeAntiCheatMonitor();
  final fakeAudit = auditLog ?? FakeAuditLogService();

  return [
    examServiceProvider.overrideWithValue(fakeExam),
    antiCheatMonitorProvider.overrideWithValue(fakeAntiCheat),
    auditLogServiceProvider.overrideWithValue(fakeAudit),
    syncStatusProvider.overrideWith((ref) => syncStatus),
    if (questions != null)
      examQuestionsProvider.overrideWith((_) async => questions),
  ];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExamInterface — question rendering', () {
    testWidgets('renders a TextField for each question', (tester) async {
      await tester.pumpWidget(buildExamInterface(overrides: baseOverrides()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('question_field_q1')), findsOneWidget);
      expect(find.byKey(const Key('question_field_q2')), findsOneWidget);
    });

    testWidgets('renders question prompt text', (tester) async {
      await tester.pumpWidget(buildExamInterface(overrides: baseOverrides()));
      await tester.pumpAndSettle();

      expect(find.text('Describe photosynthesis.'), findsOneWidget);
      expect(find.text("Explain Newton's laws."), findsOneWidget);
    });
  });

  group('ExamInterface — sync status indicator', () {
    testWidgets('shows "Synced" by default', (tester) async {
      await tester.pumpWidget(buildExamInterface(overrides: baseOverrides()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sync_status_indicator')), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows "Sync Failed" when syncStatusProvider is failed',
        (tester) async {
      await tester.pumpWidget(buildExamInterface(
        overrides: baseOverrides(syncStatus: SyncStatus.failed),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sync_status_indicator')), findsOneWidget);
      expect(find.text('Sync Failed'), findsOneWidget);
    });

    testWidgets('shows retry button when syncStatusProvider is failed',
        (tester) async {
      await tester.pumpWidget(buildExamInterface(
        overrides: baseOverrides(syncStatus: SyncStatus.failed),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('does NOT show retry button when sync is synced',
        (tester) async {
      await tester.pumpWidget(buildExamInterface(overrides: baseOverrides()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('retry_button')), findsNothing);
    });
  });

  group('ExamInterface — violation overlay', () {
    testWidgets('violation overlay is NOT shown initially', (tester) async {
      await tester.pumpWidget(buildExamInterface(overrides: baseOverrides()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('violation_overlay')), findsNothing);
    });

    testWidgets('violation overlay IS shown when AntiCheatMonitor emits a violation',
        (tester) async {
      final fakeMonitor = FakeAntiCheatMonitor();

      await tester.pumpWidget(buildExamInterface(
        overrides: baseOverrides(antiCheat: fakeMonitor),
      ));
      await tester.pumpAndSettle();

      // Emit a violation.
      fakeMonitor.emitViolation(CheatEvent(
        type: CheatEventType.appSwitch,
        timestampUtc: DateTime.utc(2024, 6, 1, 10, 0, 0),
        studentId: 'student_1',
      ));

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('violation_overlay')), findsOneWidget);
    });

    testWidgets('violation overlay can be dismissed by tapping "I Understand"',
        (tester) async {
      final fakeMonitor = FakeAntiCheatMonitor();

      await tester.pumpWidget(buildExamInterface(
        overrides: baseOverrides(antiCheat: fakeMonitor),
      ));
      await tester.pumpAndSettle();

      fakeMonitor.emitViolation(CheatEvent(
        type: CheatEventType.appSwitch,
        timestampUtc: DateTime.utc(2024, 6, 1, 10, 0, 0),
        studentId: 'student_1',
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('violation_overlay')), findsOneWidget);

      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('violation_overlay')), findsNothing);
    });
  });

  group('ExamInterface — submit flow', () {
    testWidgets('submit button is present', (tester) async {
      await tester.pumpWidget(buildExamInterface(overrides: baseOverrides()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('submit_button')), findsOneWidget);
    });

    testWidgets('submit button is tappable and calls submitExam',
        (tester) async {
      final fakeExam = FakeExamService();

      await tester.pumpWidget(buildExamInterface(
        overrides: baseOverrides(examService: fakeExam),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      expect(fakeExam.submitCalls, hasLength(1));
    });

    testWidgets('shows "Sync Failed" status after submit failure',
        (tester) async {
      final fakeExam = FakeExamService()..shouldThrowOnSubmit = true;

      await tester.pumpWidget(buildExamInterface(
        overrides: baseOverrides(examService: fakeExam),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sync Failed'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });
  });
}
