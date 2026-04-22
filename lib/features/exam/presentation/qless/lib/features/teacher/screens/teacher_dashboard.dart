import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/audit_entry.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../student/providers/student_providers.dart';
import '../providers/teacher_providers.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _onToggleExam(bool value) async {
    final examService = ref.read(examServiceProvider);
    final auditLogService = ref.read(auditLogServiceProvider);
    final examId = ref.read(currentExamIdProvider);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await examService.setExamActive(value);
      await auditLogService.recordEntry(
        examId,
        AuditEntry(
          actorId: user?.uid ?? 'unknown',
          actorName: user?.displayName ?? user?.email ?? 'Teacher',
          action: value ? 'exam_activated' : 'exam_deactivated',
          timestampUtc: DateTime.now().toUtc(),
        ),
      );
    } catch (e) {
      _showError('Failed to update exam state: $e');
    }
  }

  Future<void> _onVerifyStudent(String studentId) async {
    final classService = ref.read(classServiceProvider);
    try {
      await classService.verifyStudent(studentId);
      ref.invalidate(studentRosterProvider);
    } catch (e) {
      _showError('Verify failed: $e');
    }
  }

  Future<void> _onRemoveStudent(String studentId) async {
    final classService = ref.read(classServiceProvider);
    final classId = ref.read(currentClassIdProvider);
    try {
      await classService.removeStudent(classId, studentId);
      ref.invalidate(studentRosterProvider);
    } catch (e) {
      _showError('Remove failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                title: const Text(
                  'Teacher Dashboard',
                  style: TextStyle(
                    color: AppTheme.cobaltBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    key: const Key('sign_out_button'),
                    icon: const Icon(Icons.logout, color: AppTheme.cobaltBlue),
                    onPressed: () async {
                      final authService = ref.read(authServiceProvider);
                      final router = GoRouter.of(context);
                      await authService.signOut();
                      router.go('/auth');
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ExamToggleSection(onToggle: _onToggleExam),
                    const SizedBox(height: 24),
                    _StudentListSection(
                      onVerify: _onVerifyStudent,
                      onRemove: _onRemoveStudent,
                    ),
                    const SizedBox(height: 24),
                    const _AuditLogSection(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Exam Toggle Section
// =============================================================================

class _ExamToggleSection extends ConsumerWidget {
  const _ExamToggleSection({required this.onToggle});

  final Future<void> Function(bool) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examToggleAsync = ref.watch(examToggleProvider);

    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Master Exam Toggle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.cobaltBlue,
            ),
          ),
          examToggleAsync.when(
            data: (isActive) => Switch(
              key: const Key('exam_toggle'),
              value: isActive,
              onChanged: onToggle,
              activeThumbColor: AppTheme.cobaltBlue,
              activeTrackColor: AppTheme.cobaltBlue.withValues(alpha: 0.4),
            ),
            loading: () => const SizedBox(
              width: 48,
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.cobaltBlue,
                  ),
                ),
              ),
            ),
            error: (_, e) => Switch(
              key: const Key('exam_toggle'),
              value: false,
              onChanged: onToggle,
              activeThumbColor: AppTheme.cobaltBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Student List Section
// =============================================================================

class _StudentListSection extends ConsumerWidget {
  const _StudentListSection({
    required this.onVerify,
    required this.onRemove,
  });

  final Future<void> Function(String studentId) onVerify;
  final Future<void> Function(String studentId) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(studentRosterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Students',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.cobaltBlue,
          ),
        ),
        const SizedBox(height: 12),
        rosterAsync.when(
          data: (students) => students.isEmpty
              ? const GlassCard(
                  child: Center(
                    child: Text(
                      'No students enrolled.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    key: const Key('student_list'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _StudentTile(
                        student: student,
                        onVerify: () => onVerify(student.id),
                        onRemove: () => onRemove(student.id),
                      );
                    },
                  ),
                ),
          loading: () => const GlassCard(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.cobaltBlue),
            ),
          ),
          error: (_, e) => GlassCard(
            child: Text(
              'Failed to load students: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.student,
    required this.onVerify,
    required this.onRemove,
  });

  final StudentModel student;
  final VoidCallback onVerify;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('student_tile_${student.id}'),
      title: Text(
        student.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.email),
          const SizedBox(height: 4),
          _VerificationBadge(isVerified: student.isVerified),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!student.isVerified)
            TextButton(
              key: Key('verify_button_${student.id}'),
              onPressed: onVerify,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.cobaltBlue,
              ),
              child: const Text('Verify'),
            ),
          TextButton(
            key: Key('remove_button_${student.id}'),
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Text(
        isVerified ? 'Verified' : 'Unverified',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}

// =============================================================================
// Audit Log Section
// =============================================================================

class _AuditLogSection extends ConsumerWidget {
  const _AuditLogSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogAsync = ref.watch(auditLogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audit Log',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.cobaltBlue,
          ),
        ),
        const SizedBox(height: 12),
        auditLogAsync.when(
          data: (entries) => GlassCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 320,
              child: ListView.separated(
                key: const Key('audit_log_list'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: entries.length,
                separatorBuilder: (_, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _AuditLogEntry(
                    key: Key('audit_log_entry_$index'),
                    entry: entry,
                  );
                },
              ),
            ),
          ),
          loading: () => const GlassCard(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.cobaltBlue),
            ),
          ),
          error: (_, e) => GlassCard(
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.sync_problem, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Reconnecting...',
                      key: Key('reconnecting_indicator'),
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuditLogEntry extends StatelessWidget {
  const _AuditLogEntry({super.key, required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatUtc(entry.timestampUtc);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.actorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.action,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatUtc(DateTime dt) {
    final utc = dt.toUtc();
    final h = utc.hour.toString().padLeft(2, '0');
    final m = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} $h:$m:$s UTC';
  }
}
