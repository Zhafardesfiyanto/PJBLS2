import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

import '../../../shared/models/exam_question.dart';
import '../../../shared/models/exam_schedule.dart';
import '../../../shared/models/sync_status.dart';

/// Abstract interface for exam-related operations.
abstract class ExamService {
  /// Watches the active/upcoming exam schedule from Firebase.
  /// Emits [ExamSchedule] when an exam is found, or `null` when none exists.
  Stream<ExamSchedule?> watchExamSchedule();

  /// Watches the `active` flag for the current exam.
  Stream<bool> watchExamActive();

  /// Writes the `active` flag to Firebase for the current exam.
  Future<void> setExamActive(bool active);

  /// Reads all questions for [examId] once and returns them.
  Future<List<ExamQuestion>> loadQuestions(String examId);

  /// Writes a single answer draft to Firebase for the authenticated student.
  Future<void> autoSaveDraft(String examId, String questionId, String answer);

  /// Submits all answers: writes to Firebase then POSTs to Laravel.
  /// Throws [ExamSubmitException] with [SyncStatus.failed] if Laravel POST fails.
  Future<void> submitExam(String examId, Map<String, String> answers);
}

/// Exception thrown when the Laravel submission endpoint fails.
class ExamSubmitException implements Exception {
  const ExamSubmitException(this.message, {required this.syncStatus});

  final String message;
  final SyncStatus syncStatus;

  @override
  String toString() => 'ExamSubmitException(${syncStatus.name}): $message';
}

/// Full Firebase + Laravel implementation of [ExamService].
class FirebaseExamService implements ExamService {
  FirebaseExamService({
    String baseUrl = 'https://api.qles.app',
    String? authToken,
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    http.Client? client,
  })  : _baseUrl = baseUrl,
        _authToken = authToken,
        _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client();

  final String _baseUrl;
  final String? _authToken;
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  String? get _studentId => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // watchExamSchedule
  // ---------------------------------------------------------------------------

  @override
  Stream<ExamSchedule?> watchExamSchedule() {
    final ref = _database.ref('exams');
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;

      final examsMap = Map<String, dynamic>.from(data as Map);
      ExamSchedule? found;

      for (final entry in examsMap.entries) {
        final examId = entry.key;
        final examData = Map<String, dynamic>.from(entry.value as Map);

        final scheduledAtRaw = examData['scheduledAt'] as String?;
        final durationSeconds = examData['durationSeconds'] as int?;
        final isActive = examData['active'] as bool? ?? false;

        if (scheduledAtRaw == null || durationSeconds == null) continue;

        final scheduledAt = DateTime.tryParse(scheduledAtRaw);
        if (scheduledAt == null) continue;

        final schedule = ExamSchedule(
          examId: examId,
          scheduledAt: scheduledAt,
          duration: Duration(seconds: durationSeconds),
          isActive: isActive,
        );

        // Prefer the active exam; otherwise pick the earliest upcoming one.
        if (isActive) {
          found = schedule;
          break;
        }

        if (scheduledAt.isAfter(DateTime.now())) {
          if (found == null || scheduledAt.isBefore(found.scheduledAt)) {
            found = schedule;
          }
        }
      }

      return found;
    });
  }

  // ---------------------------------------------------------------------------
  // watchExamActive
  // ---------------------------------------------------------------------------

  @override
  Stream<bool> watchExamActive() {
    // Watch /exams for the current exam, then subscribe to its `active` flag.
    // Uses a StreamController to implement switchMap behaviour without rxdart.
    late StreamController<bool> controller;
    StreamSubscription<ExamSchedule?>? scheduleSubscription;
    StreamSubscription<DatabaseEvent>? activeSubscription;

    controller = StreamController<bool>(
      onListen: () {
        scheduleSubscription = watchExamSchedule().listen((schedule) {
          activeSubscription?.cancel();
          if (schedule == null) {
            controller.add(false);
            return;
          }
          final ref = _database.ref('exams/${schedule.examId}/active');
          activeSubscription = ref.onValue.listen(
            (event) =>
                controller.add(event.snapshot.value as bool? ?? false),
            onError: controller.addError,
          );
        }, onError: controller.addError);
      },
      onCancel: () {
        scheduleSubscription?.cancel();
        activeSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // setExamActive
  // ---------------------------------------------------------------------------

  @override
  Future<void> setExamActive(bool active) async {
    // Resolve the current exam id from a one-shot read.
    final schedule = await watchExamSchedule().first;
    if (schedule == null) {
      throw ExamSubmitException(
        'No active or upcoming exam found',
        syncStatus: SyncStatus.failed,
      );
    }
    await _database.ref('exams/${schedule.examId}/active').set(active);
  }

  // ---------------------------------------------------------------------------
  // loadQuestions
  // ---------------------------------------------------------------------------

  @override
  Future<List<ExamQuestion>> loadQuestions(String examId) async {
    final snapshot = await _database.ref('exams/$examId/questions').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final questionsMap = Map<String, dynamic>.from(snapshot.value as Map);
    return questionsMap.entries.map((entry) {
      final questionId = entry.key;
      final questionData = Map<String, dynamic>.from(entry.value as Map);
      return ExamQuestion.fromJson(questionId, questionData);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // autoSaveDraft
  // ---------------------------------------------------------------------------

  @override
  Future<void> autoSaveDraft(
    String examId,
    String questionId,
    String answer,
  ) async {
    final studentId = _studentId;
    if (studentId == null) return;
    await _database
        .ref('exams/$examId/drafts/$studentId/$questionId')
        .set(answer);
  }

  // ---------------------------------------------------------------------------
  // submitExam
  // ---------------------------------------------------------------------------

  @override
  Future<void> submitExam(String examId, Map<String, String> answers) async {
    final studentId = _studentId;
    if (studentId == null) {
      throw ExamSubmitException(
        'No authenticated student',
        syncStatus: SyncStatus.failed,
      );
    }

    // Step 1: Write answers to Firebase.
    final submittedAt = DateTime.now().toUtc().toIso8601String();
    final submissionRef = _database.ref('exams/$examId/submissions/$studentId');

    final answersPayload = {
      for (final entry in answers.entries) entry.key: entry.value,
    };

    await submissionRef.set({
      'answers': answersPayload,
      'submittedAt': submittedAt,
    });

    // Step 2: POST to Laravel.
    final uri = Uri.parse('$_baseUrl/exams/$examId/submit');
    try {
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode({'answers': answersPayload}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message;
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          message =
              body['message'] as String? ?? response.reasonPhrase ?? 'Unknown error';
        } catch (_) {
          message = response.reasonPhrase ?? 'Unknown error';
        }
        // Firebase data is already written — retain it and surface failure.
        throw ExamSubmitException(
          'Laravel submission failed (${response.statusCode}): $message',
          syncStatus: SyncStatus.failed,
        );
      }
    } on ExamSubmitException {
      rethrow;
    } catch (e) {
      // Network or other error — Firebase data retained.
      throw ExamSubmitException(
        'Laravel submission error: $e',
        syncStatus: SyncStatus.failed,
      );
    }
  }
}
