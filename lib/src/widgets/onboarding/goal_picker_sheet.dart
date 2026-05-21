import 'package:flutter/material.dart';

import '../../intelligence/plan_generator.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';

/// Modal bottom-sheet that asks the user to pick one of the four
/// [TrainingGoal] presets. Renders each option as a large [RunnerCard] tile
/// with icon + label + 1-line description.
///
/// Use [GoalPickerSheet.show] to display it; the static helper returns the
/// picked [TrainingGoal] (or `null` if the user dismisses the sheet).
class GoalPickerSheet extends StatelessWidget {
  /// Pre-selected goal to highlight when the sheet opens. `null` means no
  /// option is highlighted.
  final TrainingGoal? initial;

  /// Callback fired with the user's pick before the sheet is popped.
  final ValueChanged<TrainingGoal> onPick;

  const GoalPickerSheet({super.key, this.initial, required this.onPick});

  /// Opens the sheet via [showModalBottomSheet] and resolves with the picked
  /// goal (or `null` on dismiss).
  static Future<TrainingGoal?> show(
    BuildContext context, {
    TrainingGoal? initial,
  }) {
    return showModalBottomSheet<TrainingGoal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoalPickerSheet(
        initial: initial,
        onPick: (g) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedPadding(
      duration: reduceMotion ? Duration.zero : t.motionFast,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.border)),
        ),
        padding: EdgeInsets.fromLTRB(
          t.space4,
          t.space3,
          t.space4,
          t.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: EdgeInsets.only(bottom: t.space3),
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Pick a training goal', style: t.titleLarge),
            SizedBox(height: t.space2),
            Text(
              'Used to pick rep ranges and rest defaults for generated plans.',
              style: t.bodyMuted,
            ),
            SizedBox(height: t.space4),
            for (final goal in TrainingGoal.values) ...[
              _GoalTile(
                goal: goal,
                selected: goal == initial,
                onTap: () {
                  onPick(goal);
                  Navigator.of(context).pop(goal);
                },
              ),
              if (goal != TrainingGoal.values.last)
                SizedBox(height: t.space3),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final TrainingGoal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalTile({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final info = _goalInfo(goal);
    return RunnerCard(
      onTap: onTap,
      borderColor: selected ? t.accent : t.border,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? t.accent : t.accentMuted,
              borderRadius: t.radiusMedium,
            ),
            alignment: Alignment.center,
            child: Icon(
              info.icon,
              size: 24,
              color: selected ? t.onAccent : t.accent,
            ),
          ),
          SizedBox(width: t.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(info.label, style: t.title),
                SizedBox(height: t.space1),
                Text(
                  info.description,
                  style: t.bodyMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (selected)
            Padding(
              padding: EdgeInsets.only(left: t.space2),
              child: Icon(
                Icons.check_circle_rounded,
                color: t.accent,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalInfo {
  final IconData icon;
  final String label;
  final String description;

  const _GoalInfo({
    required this.icon,
    required this.label,
    required this.description,
  });
}

_GoalInfo _goalInfo(TrainingGoal goal) {
  switch (goal) {
    case TrainingGoal.strength:
      return const _GoalInfo(
        icon: Icons.fitness_center_rounded,
        label: 'Strength',
        description: 'Heavy compounds, low reps, long rests',
      );
    case TrainingGoal.hypertrophy:
      return const _GoalInfo(
        icon: Icons.bolt_rounded,
        label: 'Hypertrophy',
        description: 'Moderate reps, controlled tempo, mass focus',
      );
    case TrainingGoal.conditioning:
      return const _GoalInfo(
        icon: Icons.directions_run_rounded,
        label: 'Conditioning',
        description: 'Higher reps, shorter rests, work capacity',
      );
    case TrainingGoal.general:
      return const _GoalInfo(
        icon: Icons.favorite_rounded,
        label: 'General fitness',
        description: 'Balanced mix for everyday health',
      );
  }
}
