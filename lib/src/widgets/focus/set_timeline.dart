import 'package:flutter/material.dart';

import '../../controller/workout_runner.dart';
import '../../models/set_type.dart';
import '../../theme/workout_runner_theme.dart';
import '../runner_scope.dart';

/// Compact horizontal timeline of an exercise's sets. Each dot is small but
/// reflects state via color (done/active/pending/locked) and shape (square
/// vs circle vs ring) so a glance tells you "where am I in this exercise".
class SetTimeline extends StatelessWidget {
  final int? exerciseIndexOverride;
  final ValueChanged<int>? onSetTap;

  const SetTimeline({super.key, this.exerciseIndexOverride, this.onSetTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final plan = runner.plan;
    if (plan == null) return const SizedBox.shrink();
    final exerciseIndex =
        exerciseIndexOverride ??
        runner.activeExerciseIndex ??
        runner.currentExerciseIndex;
    if (exerciseIndex >= plan.exercises.length) return const SizedBox.shrink();
    final sets = plan.exercises[exerciseIndex].sets;
    if (sets.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: 'Set timeline',
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space2),
        child: Row(
          children: [
            for (var i = 0; i < sets.length; i++) ...[
              if (i > 0) SizedBox(width: t.space2),
              _Dot(
                index: i,
                state: _stateFor(runner, exerciseIndex, i),
                setType: sets[i].type,
                onTap: onSetTap == null ? null : () => onSetTap!(i),
                t: t,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static _DotState _stateFor(
    WorkoutRunner runner,
    int exerciseIndex,
    int setIndex,
  ) {
    if (runner.getPerformedSet(exerciseIndex, setIndex) != null) {
      return _DotState.done;
    }
    if (runner.activeSetExerciseIndex == exerciseIndex &&
        runner.activeSetIndex == setIndex) {
      return _DotState.active;
    }
    return _DotState.pending;
  }
}

enum _DotState { pending, active, done }

class _Dot extends StatelessWidget {
  final int index;
  final _DotState state;
  final SetType setType;
  final VoidCallback? onTap;
  final WorkoutRunnerThemeData t;

  const _Dot({
    required this.index,
    required this.state,
    required this.setType,
    required this.t,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = setType == SetType.working ? t.accent : t.accentFor(setType);
    final Color bg;
    final Color border;
    final Widget? child;
    switch (state) {
      case _DotState.done:
        bg = accent;
        border = Colors.transparent;
        child = Icon(Icons.check_rounded, size: 16, color: t.onAccent);
        break;
      case _DotState.active:
        bg = accent.withValues(alpha: 0.18);
        border = accent;
        child = Text(
          '${index + 1}',
          style: t.title.copyWith(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        );
        break;
      case _DotState.pending:
        bg = Colors.transparent;
        border = t.textDim;
        child = Text(
          '${index + 1}',
          style: t.caption.copyWith(color: t.textMuted),
        );
        break;
    }
    final dot = AnimatedContainer(
      duration:
          MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : t.motionFast,
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: t.radiusSmall,
        border: Border.all(color: border, width: 1.5),
      ),
      child: child,
    );
    if (onTap == null) return dot;
    return Semantics(
      button: true,
      label: 'Set ${index + 1}',
      child: GestureDetector(onTap: onTap, child: dot),
    );
  }
}
