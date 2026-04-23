import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qless/features/student/providers/student_providers.dart';
import 'package:qless/features/student/screens/student_dashboard.dart';
import 'package:qless/shared/models/class_model.dart';
import 'package:qless/shared/models/exam_schedule.dart';

// ---------------------------------------------------------------------------
// Fake data
// ---------------------------------------------------------------------------

final _fakeClasses = [
  const ClassModel(
    id: 'c1',
    name: 'Mathematics',
    subject: 'Algebra',
    teacherName: 'Mr. Smith',
    completedAssignments: 3,
    totalAssignments: 5,
  ),
  const ClassModel(
    id: 'c2',
    name: 'Physics',
    subject: 'Mechanics',
    teacherName: 'Ms. Jones',
    completedAssignments: 1,
    totalAssignments: 4,
  ),
];

ExamSchedule _futureExam() => ExamSchedule(
      examId: 'exam1',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      duration: const Duration(hours: 1),
      isActive: true,
    );

ExamSchedule _pastExam() => ExamSchedule(
      examId: 'exam1',
      scheduledAt: DateTime.now().subtract(const Duration(minutes: 5)),
      duration: const Duration(hours: 1),
      isActive: true,
    );

// ---------------------------------------------------------------------------
// Helper — builds StudentDashboard wrapped in ProviderScope + GoRouter
// ---------------------------------------------------------------------------

Widget buildDashboard({
  required Override classListOverride,
  required Override examOverride,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/exam',
        builder: (_, _) => const Scaffold(body: Text('Exam')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [classListOverride, examOverride],
    child: MaterialApp.router(routerConfig: router),
  );
}

// Convenience overrides
Override classListLoading() => classListProvider.overrideWith(
      (_) => Completer<List<ClassModel>>().future, // never completes
    );

Override classListError(Object error) => classListProvider.overrideWith(
      (_) => Future<List<ClassModel>>.error(error),
    );

Override classListData(List<ClassModel> data) => classListProvider.overrideWith(
      (_) async => data,
    );

Override examData(ExamSchedule? exam) => examCountdownProvider.overrideWith(
      (_) => Stream.value(exam),
    );

Override examLoading() => examCountdownProvider.overrideWith(
      (_) => StreamController<ExamSchedule?>().stream, // never emits
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('StudentDashboard — loading state', () {
    testWidgets('shows loading skeleton while classListProvider is loading',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListLoading(),
        examOverride: examData(null),
      ));
      // Let GoRouter navigate to '/' and render the widget tree.
      // The Completer future never completes, so FutureProvider stays loading.
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('loading_skeleton')), findsOneWidget);
      expect(find.byKey(const Key('class_list')), findsNothing);
      expect(find.byKey(const Key('error_state')), findsNothing);
    });
  });

  group('StudentDashboard — error state', () {
    testWidgets(
        'shows error state with retry button when classListProvider fails',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListError(Exception('Network error')),
        examOverride: examData(null),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error_state')), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
      expect(find.byKey(const Key('loading_skeleton')), findsNothing);
      expect(find.byKey(const Key('class_list')), findsNothing);
    });

    testWidgets('error state contains an error message', (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListError(Exception('Network error')),
        examOverride: examData(null),
      ));
      await tester.pumpAndSettle();

      // The error widget is present; message text is rendered inside it
      expect(find.byKey(const Key('error_state')), findsOneWidget);
    });
  });

  group('StudentDashboard — class cards', () {
    testWidgets(
        'shows class cards with correct data when classListProvider succeeds',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListData(_fakeClasses),
        examOverride: examData(null),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('class_list')), findsOneWidget);
      expect(find.byKey(const Key('class_card_c1')), findsOneWidget);
      expect(find.byKey(const Key('class_card_c2')), findsOneWidget);
    });

    testWidgets('class card displays class name, subject, and teacher name',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListData(_fakeClasses),
        examOverride: examData(null),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Teacher: Mr. Smith'), findsOneWidget);
    });

    testWidgets('class card shows progress percentage', (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListData(_fakeClasses),
        examOverride: examData(null),
      ));
      await tester.pumpAndSettle();

      // 3/5 = 60%
      expect(find.text('60%'), findsOneWidget);
      // 1/4 = 25%
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('no loading skeleton or error state when data is loaded',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListData(_fakeClasses),
        examOverride: examData(null),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loading_skeleton')), findsNothing);
      expect(find.byKey(const Key('error_state')), findsNothing);
    });
  });

  group('StudentDashboard — exam section', () {
    testWidgets('shows "No upcoming exams" placeholder when exam is null',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListData(_fakeClasses),
        examOverride: examData(null),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no_exam_placeholder')), findsOneWidget);
      expect(find.text('No upcoming exams'), findsOneWidget);
      expect(find.byKey(const Key('countdown_timer')), findsNothing);
      expect(find.byKey(const Key('enter_exam_button')), findsNothing);
    });

    testWidgets('shows countdown timer when exam is scheduled in the future',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListData(_fakeClasses),
        examOverride: examData(_futureExam()),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('countdown_timer')), findsOneWidget);
      expect(find.byKey(const Key('no_exam_placeholder')), findsNothing);
      expect(find.byKey(const Key('enter_exam_button')), findsNothing);
    });

    testWidgets('countdown timer displays time unit labels', (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListData(_fakeClasses),
        examOverride: examData(_futureExam()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Days'), findsOneWidget);
      expect(find.text('Hours'), findsOneWidget);
      expect(find.text('Min'), findsOneWidget);
      expect(find.text('Sec'), findsOneWidget);
    });

    testWidgets(
        'shows "Enter Exam" button when exam scheduledAt is in the past',
        (tester) async {
      await tester.pumpWidget(buildDashboard(
        classListOverride: classListData(_fakeClasses),
        examOverride: examData(_pastExam()),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('enter_exam_button')), findsOneWidget);
      expect(find.text('Enter Exam'), findsOneWidget);
      expect(find.byKey(const Key('countdown_timer')), findsNothing);
      expect(find.byKey(const Key('no_exam_placeholder')), findsNothing);
    });
  });
}
