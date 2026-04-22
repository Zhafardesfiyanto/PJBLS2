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
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final classListAsync = ref.watch(classListProvider);
    final examAsync = ref.watch(examCountdownProvider);

    // Manage countdown timer based on exam schedule
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Student Dashboard',
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'My Classes',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _buildClassList(classListAsync),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Upcoming Exam',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
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
        ),
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

        final isCountdownZero = _remaining == Duration.zero;

        if (isCountdownZero) {
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
          Text(
            classModel.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            classModel.subject,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'Teacher: ${classModel.teacherName}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.black12,
                  color: AppTheme.cobaltBlue,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.cobaltBlue,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading Skeleton
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
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
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
        color: Colors.grey.shade300,
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
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('retry_button'),
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cobaltBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Countdown Timer
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
          _Divider(),
          _TimeUnit(value: hours, label: 'Hours'),
          _Divider(),
          _TimeUnit(value: minutes, label: 'Min'),
          _Divider(),
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
        Text(
          value.toString().padLeft(2, '0'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.cobaltBlue,
              ),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      ':',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.cobaltBlue,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Enter Exam Button
// ---------------------------------------------------------------------------

class _EnterExamButton extends StatelessWidget {
  const _EnterExamButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go('/exam'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cobaltBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Enter Exam',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No Exam Placeholder
// ---------------------------------------------------------------------------

class _NoExamPlaceholder extends StatelessWidget {
  const _NoExamPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Center(
        child: Text(
          'No upcoming exams',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.black54),
        ),
      ),
    );
  }
}
