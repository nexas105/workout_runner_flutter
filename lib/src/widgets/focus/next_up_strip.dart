import 'package:flutter/material.dart';

import '../../theme/workout_runner_theme.dart';
import '../runner_scope.dart';

/// Slim horizontal preview of what comes after the current focus. Reads from
/// the ambient [WorkoutRunner] and renders the next exercise (or "Final
/// exercise") so users always know where the session is heading.
class NextUpStrip extends StatelessWidget {
  const NextUpStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final plan = runner.plan;
    if (plan == null) return const SizedBox.shrink();
    final current = runner.activeExerciseIndex ?? runner.currentExerciseIndex;
    final nextIndex = current + 1;
    if (nextIndex >= plan.exercises.length) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space2),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, color: t.textDim, size: 16),
            SizedBox(width: t.space2),
            Text('Last exercise', style: t.caption),
          ],
        ),
      );
    }
    final next = plan.exercises[nextIndex];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space2),
      child: Row(
        children: [
          Text('NEXT', style: t.eyebrow.copyWith(color: t.textMuted)),
          SizedBox(width: t.space2),
          Expanded(
            child: Text(
              next.name,
              style: t.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (next.sets.isNotEmpty)
            Text('${next.sets.length} sets', style: t.caption),
        ],
      ),
    );
  }
}
