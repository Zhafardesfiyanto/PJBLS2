import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/audit_entry.dart';
import '../../../shared/models/cheat_event.dart';
import '../../../shared/models/exam_question.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../student/providers/student_providers.dart';
import '../../teacher/providers/teacher_providers.dart';
import '../providers/exam_providers.dart';

class ExamInterface extends ConsumerStatefulWidget {
  const ExamInterface({super.key});

  @override
  ConsumerState<ExamInterface> createState() => _ExamInterfaceState();
}

class _ExamInterfaceState extends ConsumerState<ExamInterface> {
  /// Answer text controllers keyed by question ID.
  final Map<String, TextEditingController> _controllers = {};

  /// otomaswtis save setiap 30 detik sekali
  Timer? _autoSaveTimer;

  /// Auto-submit timer fires when the exam duration elapses.
  Timer? _autoSubmitTimer;

  /// Violation overlay subscription.
  StreamSubscription? _violationSubscription;

  /// Whether the violation overlay is currently visible.
  bool _showViolationOverlay = false;

  /// Whether the exam has been submitted (prevents double-submit).
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _startAutoSave();
    _startAntiCheatMonitoring();
    _scheduleAutoSubmit();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _autoSaveTimer?.cancel();
    _autoSubmitTimer?.cancel();
    _violationSubscription?.cancel();
    super.dispose();
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    final examService = ref.read(examServiceProvider);
    final examId = ref.read(currentExamIdProvider);
    for (final entry in _controllers.entries) {
      await examService.autoSaveDraft(examId, entry.key, entry.value.text);
    }
  }

  // ---------------------------------------------------------------------------
  // Anti-cheat monitoring
  // ---------------------------------------------------------------------------

  void _startAntiCheatMonitoring() {
    final monitor = ref.read(antiCheatMonitorProvider);
    monitor.startMonitoring();
    _violationSubscription = monitor.violations.listen(_onViolation);
  }

  Future<void> _onViolation(CheatEvent event) async {
    if (!mounted) return;
    setState(() => _showViolationOverlay = true);

    // Record via AuditLogService. Guard against Firebase not being available
    // (e.g. in widget tests where Firebase is not initialised).
    try {
      final auditLogService = ref.read(auditLogServiceProvider);
      final examId = ref.read(currentExamIdProvider);
      final user = FirebaseAuth.instance.currentUser;
      await auditLogService.recordEntry(
        examId,
        AuditEntry(
          actorId: user?.uid ?? '',
          actorName: user?.displayName ?? user?.email ?? 'Student',
          action:
              'Violation detected: ${event.type.name} at ${event.timestampUtc.toIso8601String()}',
          timestampUtc: event.timestampUtc,
        ),
      );
    } catch (_) {
      // Audit recording failure must not suppress the violation overlay.
    }
  }

  void _dismissViolationOverlay() {
    setState(() => _showViolationOverlay = false);
  }

  // ---------------------------------------------------------------------------
  // Auto-submit on time expiry
  // ---------------------------------------------------------------------------

  void _scheduleAutoSubmit() {
    // Listen once to the exam schedule to get the duration.
    final examService = ref.read(examServiceProvider);
    examService.watchExamSchedule().first.then((schedule) {
      if (schedule == null || !mounted) return;
      final remaining = schedule.scheduledAt
          .add(schedule.duration)
          .difference(DateTime.now());
      if (remaining.isNegative) {
        _submitExam();
      } else {
        _autoSubmitTimer = Timer(remaining, _submitExam);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submitExam() async {
    if (_submitted || !mounted) return;
    _submitted = true;

    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    final examService = ref.read(examServiceProvider);
    final examId = ref.read(currentExamIdProvider);
    final answers = {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };

    try {
      await examService.submitExam(examId, answers);
      if (mounted) {
        ref.read(syncStatusProvider.notifier).state = SyncStatus.synced;
      }
    } catch (_) {
      if (mounted) {
        ref.read(syncStatusProvider.notifier).state = SyncStatus.failed;
        _submitted = false; // allow retry
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(examQuestionsProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(color: AppTheme.surface),

          // Main content.
          SafeArea(
            child: Column(
              children: [
                _buildHeader(syncStatus),
                Expanded(
                  child: questionsAsync.when(
                    data: (questions) => _buildQuestionList(questions),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Text('Failed to load questions: $e'),
                    ),
                  ),
                ),
                _buildFooter(syncStatus),
              ],
            ),
          ),

          // Violation overlay.
          if (_showViolationOverlay) _buildViolationOverlay(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header: title + sync status indicator
  // ---------------------------------------------------------------------------

  Widget _buildHeader(SyncStatus syncStatus) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xFF4FC3F7), AppTheme.primary]),
            ),
            child: const Center(
              child: Text('Q',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Exam',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
          ),
          _buildSyncStatusIndicator(syncStatus),
        ],
      ),
    );
  }

  Widget _buildSyncStatusIndicator(SyncStatus syncStatus) {
    final (label, color) = switch (syncStatus) {
      SyncStatus.synced => ('Synced', Colors.green),
      SyncStatus.syncing => ('Syncing...', Colors.blue),
      SyncStatus.failed => ('Sync Failed', Colors.red),
    };

    return Row(
      key: const Key('sync_status_indicator'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Question list
  // ---------------------------------------------------------------------------

  Widget _buildQuestionList(List<ExamQuestion> questions) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: questions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final ExamQuestion question = questions[index];
        _controllers.putIfAbsent(
          question.id,
          () => TextEditingController(),
        );
        return _buildQuestionCard(question);
      },
    );
  }

  Widget _buildQuestionCard(ExamQuestion question) {
    final controller = _controllers[question.id]!;
    final maxChars =
        question.maxCharacters < 2000 ? 2000 : question.maxCharacters;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.prompt,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: Key('question_field_${question.id}'),
            controller: controller,
            maxLines: null,
            maxLength: maxChars,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Type your answer here...',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer: submit / retry button
  // ---------------------------------------------------------------------------

  Widget _buildFooter(SyncStatus syncStatus) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncStatus == SyncStatus.failed) ...[
            ElevatedButton.icon(
              key: const Key('retry_button'),
              onPressed: _submitExam,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Sync'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            key: const Key('submit_button'),
            onPressed: syncStatus == SyncStatus.syncing ? null : _submitExam,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              syncStatus == SyncStatus.syncing
                  ? 'Submitting...'
                  : 'Submit Exam',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Violation overlay
  // ---------------------------------------------------------------------------

  Widget _buildViolationOverlay() {
    return GestureDetector(
      onTap: _dismissViolationOverlay,
      child: Container(
        key: const Key('violation_overlay'),
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Integrity Violation Detected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Leaving the exam app has been recorded. '
                    'Further violations may result in disqualification.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _dismissViolationOverlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('I Understand'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
