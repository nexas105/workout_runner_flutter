import 'package:flutter/material.dart';

import '../../controller/workout_runner.dart';
import '../../l10n/workout_runner_localizations.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/rest_overlay.dart';
import '../internals/runner_pill_button.dart';
import '../runner_scope.dart';
import '../set_view.dart' show SetInputSheet;
import 'exercise_focus_card.dart';
import 'focus_action_bar.dart';
import 'next_up_strip.dart';
import 'session_header.dart';
import 'set_timeline.dart';

/// Compose the new focus-mode runner UI from its building blocks:
///   - [SessionHeader] (top): plan name + elapsed + progress + pause/finish
///   - [ExerciseFocusCard] (body): focus on the active exercise
///   - [SetTimeline] + [NextUpStrip] (under the card)
///   - [FocusActionBar] (sticky bottom): one primary CTA per state
///   - [RestOverlay] (full-bleed): drops in while resting
///
/// Drop-in replacement for `RunnerPanel` when you want the premium-session
/// layout. The classic `RunnerPanel` stays available for apps that haven't
/// migrated yet.
class RunnerFocusPanel extends StatelessWidget {
  /// Called after the workout finishes (`true` = saved a result).
  final ValueChanged<bool>? onFinished;

  /// Optional builder for the header (replaces the bundled [SessionHeader]).
  final Widget Function(BuildContext, WorkoutRunner)? sessionHeaderBuilder;

  /// Optional builder for the action bar (replaces the bundled
  /// [FocusActionBar]). Receives the runner so the builder can decide the
  /// primary action based on current state.
  final Widget Function(BuildContext, WorkoutRunner)? focusActionBarBuilder;

  const RunnerFocusPanel({
    super.key,
    this.onFinished,
    this.sessionHeaderBuilder,
    this.focusActionBarBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);

    if (runner.plan == null) {
      return Container(
        color: t.background,
        alignment: Alignment.center,
        child: Text('No active workout', style: t.bodyMuted),
      );
    }

    final header =
        sessionHeaderBuilder != null
            ? sessionHeaderBuilder!(context, runner)
            : SessionHeader(
              onPauseToggle: runner.isPaused ? runner.resume : runner.pause,
              onFinish: () async {
                final result = await runner.finish();
                onFinished?.call(result != null);
              },
            );

    final actions =
        focusActionBarBuilder != null
            ? focusActionBarBuilder!(context, runner)
            : _defaultActionBar(context, runner);

    return Stack(
      children: [
        Container(
          color: t.background,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                header,
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.space5,
                      vertical: t.space2,
                    ),
                    child: const ExerciseFocusCard(),
                  ),
                ),
                const SetTimeline(),
                const NextUpStrip(),
                actions,
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: RestOverlay(
            visible: runner.isResting,
            remaining: runner.restRemaining,
            total:
                runner.restTotal == Duration.zero
                    ? runner.restRemaining
                    : runner.restTotal,
            onSkip: runner.skipRest,
            onAdd: runner.extendRest,
          ),
        ),
      ],
    );
  }

  Widget _defaultActionBar(BuildContext context, WorkoutRunner runner) {
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final plan = runner.plan;
    if (plan == null) return const SizedBox.shrink();
    final exerciseIndex =
        runner.activeExerciseIndex ?? runner.currentExerciseIndex;
    if (exerciseIndex >= plan.exercises.length) {
      return FocusActionBar(
        primaryLabel: 'Finish workout',
        primaryIcon: Icons.check_rounded,
        primaryStyle: RunnerButtonStyle.accent,
        onPrimary: () async {
          final result = await runner.finish();
          onFinished?.call(result != null);
        },
      );
    }

    final exercise = plan.exercises[exerciseIndex];
    if (runner.activeSetExerciseIndex == exerciseIndex &&
        runner.activeSetIndex != null) {
      // Running set → Finish CTA.
      final setIndex = runner.activeSetIndex!;
      return FocusActionBar(
        primaryLabel: l.saveSet,
        primaryIcon: Icons.check_rounded,
        primaryStyle: RunnerButtonStyle.hot,
        onPrimary: () async {
          final res = await SetInputSheet.show(
            context: context,
            target: exercise.sets[setIndex],
            elapsed: runner.currentSetElapsed,
            setIndex: setIndex,
          );
          if (res == null) return;
          await runner.finishCurrentSet(
            reps: res.reps,
            weight: res.weight,
            rir: res.rir,
            rest: res.rest,
          );
        },
      );
    }

    if (runner.isResting) {
      return FocusActionBar(
        primaryLabel: l.restSkip,
        primaryIcon: Icons.skip_next_rounded,
        primaryStyle: RunnerButtonStyle.hot,
        onPrimary: runner.skipRest,
        secondary: [
          FocusSecondaryAction(
            label: l.restAdd30,
            icon: Icons.add_rounded,
            onPressed: () => runner.extendRest(const Duration(seconds: 30)),
          ),
        ],
      );
    }

    // Pending: find the next unperformed set; otherwise the exercise is done.
    int? nextSetIndex;
    for (var i = 0; i < exercise.sets.length; i++) {
      if (runner.getPerformedSet(exerciseIndex, i) == null) {
        nextSetIndex = i;
        break;
      }
    }
    if (nextSetIndex == null) {
      // All sets done — advance to next exercise (no-op if last).
      final hasNext = exerciseIndex + 1 < plan.exercises.length;
      return FocusActionBar(
        primaryLabel: hasNext ? 'Next exercise' : 'Finish workout',
        primaryIcon: Icons.arrow_forward_rounded,
        primaryStyle: RunnerButtonStyle.accent,
        onPrimary: () async {
          if (hasNext) {
            runner.clearActiveExercise();
            runner.setActiveExercise(exerciseIndex + 1);
          } else {
            final result = await runner.finish();
            onFinished?.call(result != null);
          }
        },
      );
    }

    final pendingSetIndex = nextSetIndex;
    return FocusActionBar(
      primaryLabel: 'Start set',
      primaryIcon: Icons.play_arrow_rounded,
      primaryStyle: RunnerButtonStyle.accent,
      onPrimary: () {
        if (runner.activeExerciseIndex != exerciseIndex) {
          if (runner.activeExerciseIndex != null) runner.clearActiveExercise();
          runner.setActiveExercise(exerciseIndex);
        }
        runner.startSet(exerciseIndex, pendingSetIndex);
      },
    );
  }
}
