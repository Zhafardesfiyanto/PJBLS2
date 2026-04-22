import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qless/features/exam/services/exam_service.dart';
import 'package:qless/shared/models/exam_question.dart';
import 'package:qless/shared/models/exam_schedule.dart';
import 'package:qless/shared/models/sync_status.dart';

// ---------------------------------------------------------------------------
// Extended FakeExamService — in-memory, supports watchExamActive / setExamActive
// ---------------------------------------------------------------------------

class FakeExamService implements ExamService {
  /// examId → studentId → questionId → answer (draft store)
  final Map<String, Map<String, Map<String, String>>> _drafts = {};

  /// examId → studentId → submission payload
  final Map<String, Map<String, Map<String, dynamic>>> _submissions = {};

  /// Current exam-active flag, broadcast to [watchExamActive] listeners.
  bool _examActive = false;

  /// StreamController backing [watchExamActive].
  final StreamController<bool> _activeController =
      StreamController<bool>.broadcast();

  /// When true, [submitExam] throws [ExamSubmitException] after writing to
  /// the in-memory submission store, simulating a Laravel POST failure.
  bool shouldFailLaravelSubmit = false;

  /// Fixed student ID used by this fake (mirrors FirebaseAuth.currentUser.uid).
  final String studentId;

  FakeExamService({this.studentId = 'student-001'});

  // ---- draft helpers -------------------------------------------------------

  String? readDraft(String examId, String questionId) =>
      _drafts[examId]?[studentId]?[questionId];

  Map<String, String> readAllDrafts(String examId) =>
      Map<String, String>.from(_drafts[examId]?[studentId] ?? {});

  Map<String, dynamic>? readSubmission(String examId) =>
      _submissions[examId]?[studentId];

  // ---- ExamService interface -----------------------------------------------

  @override
  Stream<bool> watchExamActive() async* {
    // Emit the current value immediately, then follow the broadcast stream.
    yield _examActive;
    yield* _activeController.stream;
  }

  @override
  Future<void> setExamActive(bool active) async {
    _examActive = active;
    _activeController.add(active);
  }

  @override
  Future<void> autoSaveDraft(
    String examId,
    String questionId,
    String answer,
  ) async {
    _drafts.putIfAbsent(examId, () => {});
    _drafts[examId]!.putIfAbsent(studentId, () => {});
    _drafts[examId]![studentId]![questionId] = answer;
  }

  @override
  Future<void> submitExam(String examId, Map<String, String> answers) async {
    // Step 1: write to in-memory "Firebase" store (always succeeds).
    _submissions.putIfAbsent(examId, () => {});
    _submissions[examId]![studentId] = {
      'answers': Map<String, String>.from(answers),
      'submittedAt': DateTime.now().toUtc().toIso8601String(),
    };

    // Step 2: simulate Laravel POST failure if configured.
    if (shouldFailLaravelSubmit) {
      throw ExamSubmitException(
        'Laravel submission failed (500): Internal Server Error',
        syncStatus: SyncStatus.failed,
      );
    }
  }

  // ---- Unused stubs --------------------------------------------------------

  @override
  Stream<ExamSchedule?> watchExamSchedule() => const Stream.empty();

  @override
  Future<List<ExamQuestion>> loadQuestions(String examId) async => [];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExamService unit tests', () {
    late FakeExamService service;

    setUp(() {
      service = FakeExamService();
    });

    // -----------------------------------------------------------------------
    // watchExamActive
    // -----------------------------------------------------------------------

    group('watchExamActive', () {
      /// Test 1: emits false when no exam is active (default state).
      test('emits false when no exam is active', () async {
        expect(await service.watchExamActive().first, isFalse);
      });

      /// Test 2: emits true after setExamActive(true) is called.
      test('emits true when an exam is active', () async {
        await service.setExamActive(true);
        // The stream yields the current value first, so the latest value is true.
        expect(await service.watchExamActive().first, isTrue);
      });

      /// Additional: stream reflects multiple state changes in order.
      test('stream reflects state changes in order', () async {
        final emitted = <bool>[];
        // Subscribe before triggering changes so we capture all emissions.
        final sub = service.watchExamActive().listen(emitted.add);
        // Allow the initial yield (false) to be delivered.
        await Future<void>.delayed(Duration.zero);

        await service.setExamActive(true);
        await Future<void>.delayed(Duration.zero);
        await service.setExamActive(false);
        await Future<void>.delayed(Duration.zero);
        await service.setExamActive(true);
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();

        expect(emitted, containsAllInOrder([false, true, false, true]));
      });
    });

    // -----------------------------------------------------------------------
    // setExamActive
    // -----------------------------------------------------------------------

    group('setExamActive', () {
      /// Test 3: setExamActive(true) sets the active flag to true.
      test('setExamActive(true) sets the active flag to true', () async {
        await service.setExamActive(true);
        expect(await service.watchExamActive().first, isTrue);
      });

      /// Test 4: setExamActive(false) sets the active flag to false.
      test('setExamActive(false) sets the active flag to false', () async {
        // First activate, then deactivate.
        await service.setExamActive(true);
        await service.setExamActive(false);
        expect(await service.watchExamActive().first, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // submitExam
    // -----------------------------------------------------------------------

    group('submitExam', () {
      const examId = 'exam-001';
      const answers = {'q-001': 'My answer', 'q-002': 'Another answer'};

      /// Test 5: submitExam succeeds when Laravel returns 200 (no exception).
      test('succeeds when Laravel returns 200', () async {
        service.shouldFailLaravelSubmit = false;
        // Should complete without throwing.
        await expectLater(
          service.submitExam(examId, answers),
          completes,
        );
      });

      /// Test 6: submitExam throws ExamSubmitException with SyncStatus.failed
      ///         when Laravel returns non-2xx.
      test(
          'throws ExamSubmitException with SyncStatus.failed when Laravel '
          'returns non-2xx', () async {
        service.shouldFailLaravelSubmit = true;

        ExamSubmitException? caught;
        try {
          await service.submitExam(examId, answers);
        } on ExamSubmitException catch (e) {
          caught = e;
        }

        expect(caught, isNotNull,
            reason: 'submitExam must throw ExamSubmitException on failure');
        expect(caught!.syncStatus, SyncStatus.failed);
      });

      /// Test 7: submitExam retains Firebase data (submission) even when
      ///         Laravel fails.
      test('retains Firebase data even when Laravel fails', () async {
        service.shouldFailLaravelSubmit = true;

        try {
          await service.submitExam(examId, answers);
        } on ExamSubmitException {
          // Expected — swallow.
        }

        final submission = service.readSubmission(examId);
        expect(submission, isNotNull,
            reason: 'Submission must be written to Firebase before Laravel call');
        expect(
          submission!['answers'],
          equals(answers),
          reason: 'Answers in Firebase must match submitted answers',
        );
      });

      /// Test 7b: draft written before submit is also retained after failure.
      test('retains draft data after Laravel failure', () async {
        service.shouldFailLaravelSubmit = true;

        await service.autoSaveDraft(examId, 'q-001', 'My answer');

        try {
          await service.submitExam(examId, answers);
        } on ExamSubmitException {
          // Expected.
        }

        expect(service.readDraft(examId, 'q-001'), equals('My answer'));
      });
    });

    // -----------------------------------------------------------------------
    // autoSaveDraft
    // -----------------------------------------------------------------------

    group('autoSaveDraft', () {
      /// Test 8: autoSaveDraft writes the answer to the correct path.
      test('writes the answer to the correct path', () async {
        const examId = 'exam-draft';
        const questionId = 'q-001';
        const answer = 'Draft answer text';

        await service.autoSaveDraft(examId, questionId, answer);

        expect(service.readDraft(examId, questionId), equals(answer));
      });

      test('overwrites an existing draft with the latest value', () async {
        const examId = 'exam-draft';
        const questionId = 'q-001';

        await service.autoSaveDraft(examId, questionId, 'First draft');
        await service.autoSaveDraft(examId, questionId, 'Updated draft');

        expect(service.readDraft(examId, questionId), equals('Updated draft'));
      });

      test('stores drafts for multiple questions independently', () async {
        const examId = 'exam-multi';

        await service.autoSaveDraft(examId, 'q-001', 'Answer 1');
        await service.autoSaveDraft(examId, 'q-002', 'Answer 2');

        expect(service.readDraft(examId, 'q-001'), equals('Answer 1'));
        expect(service.readDraft(examId, 'q-002'), equals('Answer 2'));
      });
    });
  });
}
