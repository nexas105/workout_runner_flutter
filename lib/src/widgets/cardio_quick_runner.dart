import 'package:flutter/material.dart';

import '../models/cardio/cardio_plan.dart';
import '../theme/workout_runner_theme.dart';
import 'cardio_runner_scope.dart';
import 'internals/runner_card.dart';
import 'internals/section_label.dart';
import 'internals/timer_text.dart';

/// Cardio counterpart of `QuickRunner`. Surfaces the running cardio session
/// (or a horizontal plan picker when idle).
class CardioQuickRunner extends StatelessWidget {
  final List<CardioPlan> plans;
  final void Function(CardioPlan plan)? onOpen;

  const CardioQuickRunner({super.key, required this.plans, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space3),
      child:
          runner.plan != null
              ? _ActiveCard(onOpen: () => onOpen?.call(runner.plan!))
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
    final runner = CardioRunnerScope.of(context);
    final plan = runner.plan!;
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
            child: Icon(
              Icons.directions_run_rounded,
              color: t.onAccent,
              size: 28,
            ),
          ),
          SizedBox(width: t.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionLabel('Cardio running', color: t.accent),
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
                    Text(
                      'Interval ${runner.currentIntervalIndex + 1}/${runner.intervals.length}',
                      style: t.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textMuted),
        ],
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  final List<CardioPlan> plans;
  final void Function(CardioPlan plan)? onOpen;

  const _PickerCard({required this.plans, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);
    if (plans.isEmpty) return const SizedBox.shrink();

    return RunnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Start cardio'),
          SizedBox(height: t.space3),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plans.length,
              separatorBuilder: (_, __) => SizedBox(width: t.space3),
              itemBuilder: (context, i) {
                final plan = plans[i];
                return GestureDetector(
                  onTap: () async {
                    await runner.start(plan);
                    onOpen?.call(plan);
                  },
                  child: Container(
                    width: 200,
                    padding: EdgeInsets.all(t.space3),
                    decoration: BoxDecoration(
                      color: t.surfaceElevated,
                      borderRadius: t.radiusMedium,
                      border: Border.all(color: t.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _disciplineIcon(plan.discipline),
                              size: 14,
                              color: t.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              plan.discipline.name,
                              style: t.eyebrow.copyWith(color: t.accent),
                            ),
                          ],
                        ),
                        SizedBox(height: t.space2),
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
                              Icons.timer_outlined,
                              size: 14,
                              color: t.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${plan.intervals.length} int · ${TimerText.format(plan.plannedDuration)}',
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

  IconData _disciplineIcon(CardioDiscipline d) {
    switch (d) {
      case CardioDiscipline.running:
        return Icons.directions_run_rounded;
      case CardioDiscipline.cycling:
        return Icons.directions_bike_rounded;
      case CardioDiscipline.rowing:
        return Icons.rowing_rounded;
      case CardioDiscipline.swimming:
        return Icons.pool_rounded;
      case CardioDiscipline.jumpRope:
        return Icons.bolt_rounded;
      case CardioDiscipline.walk:
        return Icons.directions_walk_rounded;
      case CardioDiscipline.mixed:
        return Icons.flash_on_rounded;
    }
  }
}
