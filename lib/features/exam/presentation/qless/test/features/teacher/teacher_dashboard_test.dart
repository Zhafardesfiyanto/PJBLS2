import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qless/features/student/providers/student_providers.dart';
import 'package:qless/features/teacher/providers/teacher_providers.dart';
import 'package:qless/features/teacher/screens/teacher_dashboard.dart';
import 'package:qless/shared/models/audit_entry.dart';
import 'package:qless/shared/models/class_model.dart';
import 'package:qless/shared/models/exam_schedule.dart';
import 'package:qless/shared/models/student_model.dart';
import 'package:qless/shared/services/audit_log_service.dart';
import 'package:qless/shared/services/class_service.dart';
import 'package:qless/features/exam/services/exam_service.dart';
import 'package:qless/shared/models/exam_question.dart';

// ---------------------------------------------------------------------------
// Fake service implementations
// ---------------------------------------------------------------------------

class FakeClassService implements ClassService {
  @override
  Future<List<ClassModel>> fetchStudentClasses(String studentId) async => [];

  @override
  Future<List<StudentModel>> fetchClassRoster(String classId) async => [];

  @override
  Future<void> verifyStudent(String studentId) async {}

  @override
  Future<void> removeStudent(String classId, String studentId) async {}
}

class FakeExamService implements ExamService {
  @override
  Stream<ExamSchedule?> watchExamSchedule() => Stream.value(null);

  @override
  Stream<bool> watchExamActive() => Stream.value(false);

  @override
  Future<void> setExamActive(bool active) async {}

  @override
  Future<List<ExamQuestion>> loadQuestions(String examId) async => [];

  @override
  Future<void> autoSaveDraft(
      String examId, String questionId, String answer) async {}

  @override
  Future<void> submitExam(String examId, Map<String, String> answers) async {}
}

class FakeAuditLogService implements AuditLogService {
  @override
  Stream<List<AuditEntry>> watchAuditLog(String examId, {int limit = 50}) =>
      Stream.value([]);

  @override
  Future<void> recordEntry(String examId, AuditEntry entry) async {}
}

// ---------------------------------------------------------------------------
// Helper — builds TeacherDashboard wrapped in ProviderScope
// ---------------------------------------------------------------------------

Widget buildDashboard({
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: TeacherDashboard(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Convenience override builders
// ---------------------------------------------------------------------------

Override examToggleOverride(Stream<bool> stream) =>
    examToggleProvider.overrideWith((_) => stream);

Override studentRosterOverride(Future<List<StudentModel>> future) =>
    studentRosterProvider.overrideWith((_) => future);

Override auditLogOverride(Stream<List<AuditEntry>> stream) =>
    auditLogProvider.overrideWith((_) => stream);

List<Override> baseOverrides({
  Stream<bool>? examToggle,
  Future<List<StudentModel>>? roster,
  Stream<List<AuditEntry>>? auditLog,
}) {
  return [
    examToggleOverride(examToggle ?? Stream.value(false)),
    studentRosterOverride(roster ?? Future.value([])),
    auditLogOverride(auditLog ?? Stream.value([])),
    classServiceProvider.overrideWithValue(FakeClassService()),
    examServiceProvider.overrideWithValue(FakeExamService()),
    auditLogServiceProvider.overrideWithValue(FakeAuditLogService()),
  ];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TeacherDashboard — exam toggle', () {
    testWidgets('renders toggle in OFF state when examToggleProvider is false',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        overrides: baseOverrides(examToggle: Stream.value(false)),
      ));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byKey(const Key('exam_toggle')));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('renders toggle in ON state when examToggleProvider is true',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        overrides: baseOverrides(examToggle: Stream.value(true)),
      ));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byKey(const Key('exam_toggle')));
      expect(switchWidget.value, isTrue);
    });
  });

  group('TeacherDashboard — student list', () {
    final students = [
      const StudentModel(
        id: 's1',
        name: 'Alice Johnson',
        email: 'alice@example.com',
        isVerified: false,
      ),
      const StudentModel(
        id: 's2',
        name: 'Bob Smith',
        email: 'bob@example.com',
        isVerified: true,
      ),
    ];

    testWidgets('renders student list with name and email', (tester) async {
      await tester.pumpWidget(buildDashboard(
        overrides: baseOverrides(roster: Future.value(students)),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('student_list')), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text('Bob Smith'), findsOneWidget);
      expect(find.text('bob@example.com'), findsOneWidget);
    });

    testWidgets('verify button is shown for unverified students',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        overrides: baseOverrides(roster: Future.value(students)),
      ));
      await tester.pumpAndSettle();

      // s1 is unverified — verify button should appear
      expect(find.byKey(const Key('verify_button_s1')), findsOneWidget);
    });

    testWidgets('verify button is NOT shown for verified students',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        overrides: baseOverrides(roster: Future.value(students)),
      ));
      await tester.pumpAndSettle();

      // s2 is verified — verify button should NOT appear
      expect(find.byKey(const Key('verify_button_s2')), findsNothing);
    });

    testWidgets('remove button is shown for all students', (tester) async {
      await tester.pumpWidget(buildDashboard(
        overrides: baseOverrides(roster: Future.value(students)),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('remove_button_s1')), findsOneWidget);
      expect(find.byKey(const Key('remove_button_s2')), findsOneWidget);
    });
  });

  group('TeacherDashboard — audit log', () {
    final entries = [
      AuditEntry(
        actorId: 'u1',
        actorName: 'Mr. Teacher',
        action: 'exam_activated',
        timestampUtc: DateTime.utc(2024, 6, 1, 10, 0, 0),
      ),
      AuditEntry(
        actorId: 'u2',
        actorName: 'Alice Johnson',
        action: 'answer_submitted',
        timestampUtc: DateTime.utc(2024, 6, 1, 10, 5, 0),
      ),
    ];

    testWidgets('renders audit log entries with actorName and action',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        overrides: baseOverrides(auditLog: Stream.value(entries)),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('audit_log_list')), findsOneWidget);
      expect(find.byKey(const Key('audit_log_entry_0')), findsOneWidget);
      expect(find.byKey(const Key('audit_log_entry_1')), findsOneWidget);

      expect(find.text('Mr. Teacher'), findsOneWidget);
      expect(find.text('exam_activated'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('answer_submitted'), findsOneWidget);
    });

    testWidgets(
        '"Reconnecting..." indicator shown when audit log stream has an error',
        (tester) async {
      final errorStream = Stream<List<AuditEntry>>.error(
        Exception('Firebase connection lost'),
      );

      await tester.pumpWidget(buildDashboard(
        overrides: baseOverrides(auditLog: errorStream),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reconnecting_indicator')), findsOneWidget);
      expect(find.text('Reconnecting...'), findsOneWidget);
    });
  });
}
