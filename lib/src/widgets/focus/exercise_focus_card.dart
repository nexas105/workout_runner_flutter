import 'package:flutter/material.dart';

import '../../controller/workout_runner.dart';
import '../../l10n/workout_runner_localizations.dart';
import '../../models/set_type.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/timer_text.dart';
import '../runner_scope.dart';

/// Big-focus card for the *currently active* exercise in the focus runner.
///
/// State-driven visuals:
///   - **Pending** — exercise selected, no set running. Shows target line for
///     the next set, big "Start" CTA hint.
///   - **Running** — set is ticking. Big countdown (timed) or stopwatch (rep)
///     with target reps/weight underneath.
///   - **Resting** — rest countdown front and center (delegated to the
///     `RestOverlay` typically, but this card still echoes "Rest 1:30").
///   - **Empty** — no active exercise yet; soft placeholder.
///
/// This widget does NOT trigger state changes — it reads from
/// [WorkoutRunner] via [RunnerScope] and renders. Pair with [FocusActionBar]
/// to drive Start / Finish actions.
class ExerciseFocusCard extends StatelessWidget {
  final int? exerciseIndexOverride;

  const ExerciseFocusCard({super.key, this.exerciseIndexOverride});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final runner = RunnerScope.of(context);
    final plan = runner.plan;
    if (plan == null) return _EmptyFocus(message: 'No active workout');

    final exerciseIndex =
        exerciseIndexOverride ??
        runner.activeExerciseIndex ??
        runner.currentExerciseIndex;
    if (exerciseIndex >= plan.exercises.length) {
      return _EmptyFocus(message: 'Workout complete');
    }
    final exercise = plan.exercises[exerciseIndex];
    final nextSetIndex = _nextSetIndex(runner, exerciseIndex, exercise);

    final isRunning =
        runner.activeSetExerciseIndex == exerciseIndex &&
        runner.activeSetIndex != null;
    final isResting = runner.isResting;

    return RunnerCard(
      padding: EdgeInsets.all(t.space5),
      borderRadius: t.radiusHero,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            exercise.name,
            style: t.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (exercise.muscles.isNotEmpty) ...[
            SizedBox(height: t.space1),
            Text(
              exercise.muscles.map((m) => m.name).join(' · '),
              style: t.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: t.space4),
          if (isResting)
            _RestFocus(t: t, l: l, runner: runner)
          else if (isRunning)
            _RunningFocus(
              t: t,
              runner: runner,
              exercise: exercise,
              setIndex: runner.activeSetIndex!,
            )
          else if (nextSetIndex != null)
            _PendingFocus(
              t: t,
              l: l,
              exercise: exercise,
              setIndex: nextSetIndex,
              totalSets: exercise.sets.length,
            )
          else
            _EmptyFocus(message: 'All sets done', inline: true),
        ],
      ),
    );
  }

  static int? _nextSetIndex(
    WorkoutRunner runner,
    int exerciseIndex,
    WorkoutExercise exercise,
  ) {
    for (var i = 0; i < exercise.sets.length; i++) {
      if (runner.getPerformedSet(exerciseIndex, i) == null) return i;
    }
    return null;
  }
}

class _PendingFocus extends StatelessWidget {
  final WorkoutRunnerThemeData t;
  final WorkoutRunnerLocalizations l;
  final WorkoutExercise exercise;
  final int setIndex;
  final int totalSets;

  const _PendingFocus({
    required this.t,
    required this.l,
    required this.exercise,
    required this.setIndex,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    final set = exercise.sets[setIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Up next', style: t.eyebrow.copyWith(color: t.accent)),
        SizedBox(height: t.space2),
        Text('${l.setIndexLabel(setIndex + 1)} of $totalSets', style: t.title),
        SizedBox(height: t.space2),
        _TargetLine(t: t, l: l, set: set),
      ],
    );
  }
}

class _RunningFocus extends StatelessWidget {
  final WorkoutRunnerThemeData t;
  final WorkoutRunner runner;
  final WorkoutExercise exercise;
  final int setIndex;

  const _RunningFocus({
    required this.t,
    required this.runner,
    required this.exercise,
    required this.setIndex,
  });

  @override
  Widget build(BuildContext context) {
    final set = exercise.sets[setIndex];
    final isTimed = set.isTimed && set.targetDuration != null;
    final shown =
        isTimed ? runner.currentSetRemaining : runner.currentSetElapsed;
    final hitTarget =
        isTimed && runner.currentSetElapsed >= set.targetDuration!;
    final color = hitTarget ? t.success : t.hot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTimed ? 'TIMED' : 'WORKING',
          style: t.eyebrow.copyWith(color: color),
        ),
        SizedBox(height: t.space2),
        TimerText(duration: shown, style: t.heroNumber.copyWith(color: color)),
        SizedBox(height: t.space2),
        _TargetLine(
          t: t,
          l: WorkoutRunnerLocalizationsScope.of(context),
          set: set,
        ),
      ],
    );
  }
}

class _RestFocus extends StatelessWidget {
  final WorkoutRunnerThemeData t;
  final WorkoutRunnerLocalizations l;
  final WorkoutRunner runner;

  const _RestFocus({required this.t, required this.l, required this.runner});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.restHeader, style: t.eyebrow.copyWith(color: t.hot)),
        SizedBox(height: t.space2),
        TimerText(
          duration: runner.restRemaining,
          style: t.heroNumber.copyWith(color: t.hot),
        ),
        SizedBox(height: t.space2),
        Text(l.restRemainingTrailing, style: t.bodyMuted),
      ],
    );
  }
}

class _TargetLine extends StatelessWidget {
  final WorkoutRunnerThemeData t;
  final WorkoutRunnerLocalizations l;
  final WorkoutSet set;

  const _TargetLine({required this.t, required this.l, required this.set});

  @override
  Widget build(BuildContext context) {
    String line;
    if (set.type == SetType.amrap && set.targetDuration != null) {
      line =
          '${l.labelForSetType(SetType.amrap)} — '
          '${TimerText.format(set.targetDuration!)}';
    } else if (set.type == SetType.timed && set.targetDuration != null) {
      line = 'Hold ${TimerText.format(set.targetDuration!)}';
    } else if (set.targetWeight != null) {
      line =
          '${set.targetReps} × ${l.formatWeight(set.targetWeight!)} ${l.unitKg}';
    } else {
      line = '${set.targetReps} ${l.repsLabel.toLowerCase()}';
    }
    return Text(line, style: t.body);
  }
}

class _EmptyFocus extends StatelessWidget {
  final String message;
  final bool inline;

  const _EmptyFocus({required this.message, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    if (inline) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: t.space3),
        child: Text(message, style: t.bodyMuted),
      );
    }
    return RunnerCard(
      padding: EdgeInsets.all(t.space5),
      borderRadius: t.radiusHero,
      child: Center(child: Text(message, style: t.bodyMuted)),
    );
  }
}
