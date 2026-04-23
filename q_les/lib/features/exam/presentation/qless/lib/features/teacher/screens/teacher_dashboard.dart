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
    try {
      await ref.read(classServiceProvider).verifyStudent(studentId);
      ref.invalidate(studentRosterProvider);
    } catch (e) {
      _showError('Verify failed: $e');
    }
  }

  Future<void> _onRemoveStudent(String studentId) async {
    try {
      final classId = ref.read(currentClassIdProvider);
      await ref.read(classServiceProvider).removeStudent(classId, studentId);
      ref.invalidate(studentRosterProvider);
    } catch (e) {
      _showError('Remove failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF4FC3F7), AppTheme.primary],
                ),
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
            const Text('Teacher Dashboard',
                style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primary),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            key: const Key('sign_out_button'),
            icon: const Icon(Icons.logout, color: AppTheme.primary),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              final router = GoRouter.of(context);
              await authService.signOut();
              router.go('/auth');
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ExamToggleSection(onToggle: _onToggleExam),
                const SizedBox(height: 20),
                _StudentListSection(
                  onVerify: _onVerifyStudent,
                  onRemove: _onRemoveStudent,
                ),
                const SizedBox(height: 20),
                const _AuditLogSection(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Exam Toggle
// =============================================================================

class _ExamToggleSection extends ConsumerWidget {
  const _ExamToggleSection({required this.onToggle});
  final Future<void> Function(bool) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examToggleAsync = ref.watch(examToggleProvider);

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.toggle_on_outlined,
                color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Master Exam Toggle',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textDark)),
                Text('Enable or disable exam for all students',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          examToggleAsync.when(
            data: (isActive) => Switch(
              key: const Key('exam_toggle'),
              value: isActive,
              onChanged: onToggle,
            ),
            loading: () => const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, s) => Switch(
              key: const Key('exam_toggle'),
              value: false,
              onChanged: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Student List
// =============================================================================

class _StudentListSection extends ConsumerWidget {
  const _StudentListSection(
      {required this.onVerify, required this.onRemove});
  final Future<void> Function(String) onVerify;
  final Future<void> Function(String) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(studentRosterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Students',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
        const SizedBox(height: 10),
        rosterAsync.when(
          data: (students) => students.isEmpty
              ? GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline,
                          color: AppTheme.textMuted),
                      const SizedBox(width: 10),
                      Text('No students enrolled.',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    key: const Key('student_list'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    separatorBuilder: (p, i) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return _StudentTile(
                        student: s,
                        onVerify: () => onVerify(s.id),
                        onRemove: () => onRemove(s.id),
                      );
                    },
                  ),
                ),
          loading: () => const GlassCard(
            child: Center(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
          ),
          error: (e, s) => GlassCard(
            child: Text('Failed to load students',
                style: TextStyle(color: Colors.red.shade600)),
          ),
        ),
      ],
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile(
      {required this.student,
      required this.onVerify,
      required this.onRemove});
  final StudentModel student;
  final VoidCallback onVerify;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('student_tile_${student.id}'),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        child: Text(
          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(student.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.email,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          _VerificationBadge(isVerified: student.isVerified),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!student.isVerified)
            _ActionChip(
              key: Key('verify_button_${student.id}'),
              label: 'Verify',
              color: AppTheme.primary,
              onTap: onVerify,
            ),
          const SizedBox(width: 4),
          _ActionChip(
            key: Key('remove_button_${student.id}'),
            label: 'Remove',
            color: Colors.red.shade400,
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {super.key,
      required this.label,
      required this.color,
      required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.isVerified});
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isVerified ? '✓ Verified' : '⏳ Unverified',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isVerified ? Colors.green.shade700 : Colors.orange.shade700),
      ),
    );
  }
}

// =============================================================================
// Audit Log
// =============================================================================

class _AuditLogSection extends ConsumerWidget {
  const _AuditLogSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogAsync = ref.watch(auditLogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Audit Log',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
        const SizedBox(height: 10),
        auditLogAsync.when(
          data: (entries) => GlassCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 300,
              child: ListView.separated(
                key: const Key('audit_log_list'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: entries.length,
                separatorBuilder: (p, i) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) => _AuditLogEntry(
                  key: Key('audit_log_entry_$index'),
                  entry: entries[index],
                ),
              ),
            ),
          ),
          loading: () => const GlassCard(
            child: Center(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
          ),
          error: (e, s) => GlassCard(
            child: const Row(
              children: [
                Icon(Icons.sync_problem, color: Colors.orange),
                SizedBox(width: 8),
                Text('Reconnecting...',
                    key: Key('reconnecting_indicator'),
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.w600)),
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
    final utc = entry.timestampUtc.toUtc();
    final timeStr =
        '${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history, color: AppTheme.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.actorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(entry.action,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(timeStr,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}


