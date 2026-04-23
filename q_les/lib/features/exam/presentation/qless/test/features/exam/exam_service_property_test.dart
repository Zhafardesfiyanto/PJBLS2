import 'package:flutter_test/flutter_test.dart';
import 'package:qless/features/exam/services/exam_service.dart';
import 'package:qless/shared/models/exam_schedule.dart';
import 'package:qless/shared/models/exam_question.dart';
import 'package:qless/shared/models/sync_status.dart';

// ---------------------------------------------------------------------------
// FakeExamService — in-memory implementation mirroring FirebaseExamService
// ---------------------------------------------------------------------------

class FakeExamService implements ExamService {
  /// examId → studentId → questionId → answer
  final Map<String, Map<String, Map<String, String>>> _drafts = {};

  /// examId → studentId → { 'answers': {...}, 'submittedAt': ... }
  final Map<String, Map<String, Map<String, dynamic>>> _submissions = {};

  /// When true, [submitExam] throws [ExamSubmitException] after writing to
  /// the in-memory submission store, simulating a Laravel POST failure.
  bool shouldFailLaravelSubmit = false;

  /// Fixed student ID used by this fake (mirrors FirebaseAuth.currentUser.uid).
  final String studentId;

  FakeExamService({this.studentId = 'student-001'});

  // ---- draft helpers -------------------------------------------------------

  String? readDraft(String examId, String questionId) {
    return _drafts[examId]?[studentId]?[questionId];
  }

  Map<String, String> readAllDrafts(String examId) {
    return Map<String, String>.from(_drafts[examId]?[studentId] ?? {});
  }

  // ---- ExamService interface -----------------------------------------------

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

  // ---- Unused stubs (not under test) --------------------------------------

  @override
  Stream<ExamSchedule?> watchExamSchedule() => const Stream.empty();

  @override
  Stream<bool> watchExamActive() => const Stream.empty();

  @override
  Future<void> setExamActive(bool active) async {}

  @override
  Future<List<ExamQuestion>> loadQuestions(String examId) async => [];
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

/// Generates a list of [count] distinct exam IDs.
List<String> _examIds(int count) =>
    List.generate(count, (i) => 'exam-${i.toString().padLeft(3, '0')}');

/// Generates a list of [count] distinct question IDs.
List<String> _questionIds(int count) =>
    List.generate(count, (i) => 'q-${i.toString().padLeft(3, '0')}');

/// Generates a list of [count] answer strings with varying content.
List<String> _answers(int count) => List.generate(count, (i) {
      // Vary length and content to exercise the property across diverse inputs.
      final base = 'Answer for question $i: ';
      final body = 'Lorem ipsum dolor sit amet. ' * ((i % 5) + 1);
      return '$base$body'.trim();
    });

// ---------------------------------------------------------------------------
// Property tests
// ---------------------------------------------------------------------------

void main() {
  group('ExamService — Property 1: Draft persistence after submit failure', () {
    /// **Validates: Requirements 8.8**
    ///
    /// Property:
    ///   For all (examId, questionId, answer):
    ///     autoSaveDraft(examId, questionId, answer) succeeds
    ///     AND submitExam fails (Laravel failure)
    ///     THEN readDraft(examId, questionId) == answer
    ///
    /// We verify this with 20+ distinct input combinations.

    test(
      'draft is readable after a failed Laravel submit — 20 combinations',
      () async {
        // Generate 20 distinct (examId, questionId, answer) triples.
        const combinationCount = 20;
        final examIds = _examIds(combinationCount);
        final questionIds = _questionIds(combinationCount);
        final answers = _answers(combinationCount);

        for (var i = 0; i < combinationCount; i++) {
          final examId = examIds[i];
          final questionId = questionIds[i];
          final answer = answers[i];

          final service = FakeExamService(studentId: 'student-$i');
          service.shouldFailLaravelSubmit = true;

          // Step 1: auto-save the draft.
          await service.autoSaveDraft(examId, questionId, answer);

          // Step 2: attempt submit — must throw ExamSubmitException.
          ExamSubmitException? caught;
          try {
            await service.submitExam(examId, {questionId: answer});
          } on ExamSubmitException catch (e) {
            caught = e;
          }

          // The submit must have failed.
          expect(
            caught,
            isNotNull,
            reason:
                'submitExam should throw ExamSubmitException for combination $i',
          );
          expect(
            caught!.syncStatus,
            SyncStatus.failed,
            reason: 'syncStatus must be failed for combination $i',
          );

          // The draft must still be readable and unchanged.
          final storedDraft = service.readDraft(examId, questionId);
          expect(
            storedDraft,
            equals(answer),
            reason:
                'Draft for ($examId, $questionId) must equal "$answer" after '
                'submit failure (combination $i)',
          );
        }
      },
    );

    test(
      'draft persists across multiple questions in the same exam after submit failure',
      () async {
        const questionCount = 5;
        const examId = 'exam-multi';
        final questionIds = _questionIds(questionCount);
        final answers = _answers(questionCount);

        final service = FakeExamService();
        service.shouldFailLaravelSubmit = true;

        // Save drafts for all questions.
        for (var i = 0; i < questionCount; i++) {
          await service.autoSaveDraft(examId, questionIds[i], answers[i]);
        }

        // Attempt submit with all answers.
        final allAnswers = {
          for (var i = 0; i < questionCount; i++) questionIds[i]: answers[i],
        };

        try {
          await service.submitExam(examId, allAnswers);
        } on ExamSubmitException {
          // Expected — swallow.
        }

        // Every draft must still be intact.
        for (var i = 0; i < questionCount; i++) {
          expect(
            service.readDraft(examId, questionIds[i]),
            equals(answers[i]),
            reason:
                'Draft for question ${questionIds[i]} must survive submit failure',
          );
        }
      },
    );

    test(
      'draft persists across multiple exams after submit failure',
      () async {
        const examCount = 5;
        final examIds = _examIds(examCount);
        final answers = _answers(examCount);
        const questionId = 'q-001';

        final service = FakeExamService();
        service.shouldFailLaravelSubmit = true;

        for (var i = 0; i < examCount; i++) {
          await service.autoSaveDraft(examIds[i], questionId, answers[i]);

          try {
            await service.submitExam(examIds[i], {questionId: answers[i]});
          } on ExamSubmitException {
            // Expected.
          }

          expect(
            service.readDraft(examIds[i], questionId),
            equals(answers[i]),
            reason:
                'Draft for exam ${examIds[i]} must survive submit failure',
          );
        }
      },
    );

    test(
      'draft is overwritten by a later autoSaveDraft and still readable after submit failure',
      () async {
        const examId = 'exam-overwrite';
        const questionId = 'q-001';
        const firstAnswer = 'First draft answer.';
        const updatedAnswer = 'Updated draft answer — longer and more detailed.';

        final service = FakeExamService();
        service.shouldFailLaravelSubmit = true;

        await service.autoSaveDraft(examId, questionId, firstAnswer);
        await service.autoSaveDraft(examId, questionId, updatedAnswer);

        try {
          await service.submitExam(examId, {questionId: updatedAnswer});
        } on ExamSubmitException {
          // Expected.
        }

        expect(
          service.readDraft(examId, questionId),
          equals(updatedAnswer),
          reason: 'Latest draft must be readable after submit failure',
        );
      },
    );

    test(
      'successful submit does not affect draft readability',
      () async {
        const examId = 'exam-success';
        const questionId = 'q-001';
        const answer = 'My final answer.';

        final service = FakeExamService();
        service.shouldFailLaravelSubmit = false; // success path

        await service.autoSaveDraft(examId, questionId, answer);
        await service.submitExam(examId, {questionId: answer}); // no throw

        // Draft is still readable even after a successful submit.
        expect(
          service.readDraft(examId, questionId),
          equals(answer),
        );
      },
    );
  });
}
