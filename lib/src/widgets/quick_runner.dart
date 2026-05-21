import 'package:flutter/material.dart';

import '../models/workout_plan.dart';
import '../theme/workout_runner_theme.dart';
import 'internals/runner_card.dart';
import 'internals/section_label.dart';
import 'internals/timer_text.dart';
import 'runner_scope.dart';

/// Compact card that either advertises a running workout (with a *Continue*
/// CTA) or lets the user pick from a list of plans to start one.
///
/// Drop it on a home screen or above a workout list. Tap the card / hit
/// *Continue* and the runner navigates back to the workout. Choose a plan to
/// start a fresh workout — `WorkoutRunner.start` is called for you.
class QuickRunner extends StatelessWidget {
  /// Plans to offer when no workout is active.
  final List<WorkoutPlan> plans;

  /// Called when the user wants to open the running workout, or after
  /// choosing a plan to start it. Provide a navigation callback that pushes
  /// your screen, e.g. one wrapping `RunnerScreen`.
  final void Function(WorkoutPlan plan)? onOpen;

  const QuickRunner({super.key, required this.plans, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final activePlan = runner.plan;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space3),
      child:
          activePlan != null
              ? _ActiveCard(onOpen: () => onOpen?.call(activePlan))
              : _PickerCard(plans: plans, onOpen: onOpen),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final VoidCallback onOpen;
  const _ActiveCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final plan = runner.plan!;
    final totalSets = plan.exercises.fold<int>(
      0,
      (acc, e) => acc + e.sets.length,
    );
    final doneSets = (runner.state?.performed ?? const []).fold<int>(
      0,
      (acc, e) => acc + e.sets.length,
    );

    return RunnerCard(
      borderColor: t.accent.withValues(alpha: 0.45),
      shadow: t.shadowGlow,
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: t.accent,
              borderRadius: t.radiusMedium,
            ),
            child: Icon(Icons.bolt_rounded, color: t.onAccent, size: 30),
          ),
          SizedBox(width: t.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionLabel('Workout running', color: t.accent),
                SizedBox(height: t.space1),
                Text(
                  plan.name,
                  style: t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: t.space1),
                Row(
                  children: [
                    TimerText(
                      duration: runner.elapsed,
                      style: t.title.copyWith(fontSize: 16),
                      color: t.textPrimary,
                    ),
                    SizedBox(width: t.space3),
                    Text('$doneSets / $totalSets sets', style: t.caption),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: t.space2),
          Icon(Icons.chevron_right_rounded, color: t.textMuted),
        ],
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  final List<WorkoutPlan> plans;
  final void Function(WorkoutPlan plan)? onOpen;

  const _PickerCard({required this.plans, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    if (plans.isEmpty) return const SizedBox.shrink();

    return RunnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Start workout'),
          SizedBox(height: t.space3),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plans.length,
              separatorBuilder: (_, __) => SizedBox(width: t.space3),
              itemBuilder: (context, i) {
                final plan = plans[i];
                final totalSets = plan.exercises.fold<int>(
                  0,
                  (acc, e) => acc + e.sets.length,
                );
                return GestureDetector(
                  onTap: () async {
                    await runner.start(plan);
                    onOpen?.call(plan);
                  },
                  child: Container(
                    width: 180,
                    padding: EdgeInsets.all(t.space3),
                    decoration: BoxDecoration(
                      color: t.surfaceElevated,
                      borderRadius: t.radiusMedium,
                      border: Border.all(color: t.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: t.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 14,
                              color: t.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${plan.exercises.length} ex · $totalSets sets',
                              style: t.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
