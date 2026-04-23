import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qless/core/theme/app_theme.dart';
import 'package:qless/features/auth/providers/auth_provider.dart';
import 'package:qless/features/student/providers/student_providers.dart';
import 'package:qless/shared/models/class_model.dart';
import 'package:qless/shared/models/exam_schedule.dart';
import 'package:qless/shared/widgets/glass_card.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime scheduledAt) {
    _countdownTimer?.cancel();
    _updateRemaining(scheduledAt);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(scheduledAt);
    });
  }

  void _updateRemaining(DateTime scheduledAt) {
    final now = DateTime.now();
    final diff = scheduledAt.difference(now);
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classListAsync = ref.watch(classListProvider);
    final examAsync = ref.watch(examCountdownProvider);

    examAsync.whenData((exam) {
      if (exam != null && exam.scheduledAt.isAfter(DateTime.now())) {
        if (_countdownTimer == null || !_countdownTimer!.isActive) {
          _startCountdown(exam.scheduledAt);
        }
      } else {
        _countdownTimer?.cancel();
        _countdownTimer = null;
      }
    });

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
            const Text('Student Dashboard',
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('My Classes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
            ),
          ),
          _buildClassList(classListAsync),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Upcoming Exam',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildExamSection(examAsync),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildClassList(AsyncValue<List<ClassModel>> classListAsync) {
    return classListAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _LoadingSkeleton(key: const Key('loading_skeleton')),
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ErrorState(
            key: const Key('error_state'),
            message: error.toString(),
            onRetry: () => ref.refresh(classListProvider),
          ),
        ),
      ),
      data: (classes) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          key: const Key('class_list'),
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClassCard(
                key: Key('class_card_${classes[index].id}'),
                classModel: classes[index],
              ),
            ),
            childCount: classes.length,
          ),
        ),
      ),
    );
  }

  Widget _buildExamSection(AsyncValue<ExamSchedule?> examAsync) {
    return examAsync.when(
      loading: () => const _ExamSectionSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (exam) {
        if (exam == null) {
          return const _NoExamPlaceholder(key: Key('no_exam_placeholder'));
        }
        if (_remaining == Duration.zero) {
          return _EnterExamButton(key: const Key('enter_exam_button'));
        }
        return _CountdownTimer(
          key: const Key('countdown_timer'),
          remaining: _remaining,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Class Card
// ---------------------------------------------------------------------------

class _ClassCard extends StatelessWidget {
  const _ClassCard({super.key, required this.classModel});
  final ClassModel classModel;

  @override
  Widget build(BuildContext context) {
    final progress = classModel.progressPercent;
    final percent = (progress * 100).toStringAsFixed(0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.class_outlined,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classModel.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark)),
                    Text(classModel.subject,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Teacher: ${classModel.teacherName}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surface,
                    color: AppTheme.primary,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$percent%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeletons
// ---------------------------------------------------------------------------

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamSectionSkeleton extends StatelessWidget {
  const _ExamSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Text(message,
              style: TextStyle(color: Colors.red.shade600, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('retry_button'),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Countdown
// ---------------------------------------------------------------------------

class _CountdownTimer extends StatelessWidget {
  const _CountdownTimer({super.key, required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TimeUnit(value: days, label: 'Days'),
          _Sep(),
          _TimeUnit(value: hours, label: 'Hours'),
          _Sep(),
          _TimeUnit(value: minutes, label: 'Min'),
          _Sep(),
          _TimeUnit(value: seconds, label: 'Sec'),
        ],
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(':',
        style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary));
  }
}

// ---------------------------------------------------------------------------
// Enter Exam / No Exam
// ---------------------------------------------------------------------------

class _EnterExamButton extends StatelessWidget {
  const _EnterExamButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.go('/exam'),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Enter Exam',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _NoExamPlaceholder extends StatelessWidget {
  const _NoExamPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_available_outlined,
                color: AppTheme.textMuted),
          ),
          const SizedBox(width: 12),
          const Text('No upcoming exams',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
