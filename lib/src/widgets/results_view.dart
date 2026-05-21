import 'package:flutter/material.dart';

import '../l10n/workout_runner_localizations.dart';
import '../models/workout_result.dart';
import '../theme/workout_runner_theme.dart';
import 'internals/runner_card.dart';
import 'internals/runner_pill_button.dart';
import 'internals/section_label.dart';
import 'internals/timer_text.dart';

/// Build the row of stat tiles shown in a [ResultsView]. Return whatever
/// widgets you want — the bundled `ResultsStatTile` is exposed publicly so you
/// can mix custom values in with the defaults without rebuilding the visual
/// style from scratch.
typedef WorkoutStatBuilder = List<Widget> Function(
  BuildContext context,
  WorkoutResult result,
);

/// Stand-alone result summary, ready to push as a destination after
/// `runner.finish()`. Looks the same as the in-app `RunnerScreen` summary.
class ResultsView extends StatelessWidget {
  final WorkoutResult result;
  final VoidCallback? onClose;
  final String closeLabel;

  /// Replaces the default stat-tile row (Exercises / Sets / Reps / Volume).
  /// When `null` the bundled tiles are shown.
  final WorkoutStatBuilder? statBuilder;

  const ResultsView({
    super.key,
    required this.result,
    this.onClose,
    this.closeLabel = 'Close',
    this.statBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    return Container(
      color: t.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(t.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(result: result),
              SizedBox(height: t.space4),
              _StatsRow(result: result, builder: statBuilder),
              SizedBox(height: t.space5),
              SectionLabel(l.performedExercises),
              SizedBox(height: t.space3),
              for (final ex in result.exercises) ...[
                _ExerciseSummary(ex: ex),
                SizedBox(height: t.space3),
              ],
              if (onClose != null) ...[
                SizedBox(height: t.space4),
                RunnerPillButton(
                  label: closeLabel,
                  icon: Icons.check_circle_outline_rounded,
                  expand: true,
                  onPressed: onClose,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final WorkoutResult result;
  const _Hero({required this.result});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    return Container(
      padding: EdgeInsets.all(t.space5),
      decoration: BoxDecoration(
        borderRadius: t.radiusHero,
        border: Border.all(color: t.accent.withValues(alpha: 0.55)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.accent.withValues(alpha: 0.18), t.surface],
        ),
        boxShadow: t.shadowGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration_rounded, color: t.accent, size: 28),
              SizedBox(width: t.space2),
              Text(
                l.workoutComplete,
                style: t.title.copyWith(color: t.accent),
              ),
            ],
          ),
          SizedBox(height: t.space3),
          TimerText(duration: result.duration),
          SizedBox(height: t.space1),
          Text('Plan ${result.planId}', style: t.bodyMuted),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final WorkoutResult result;
  final WorkoutStatBuilder? builder;
  const _StatsRow({required this.result, this.builder});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final tiles = builder != null
        ? builder!(context, result)
        : _defaultTiles(result, l);
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(width: t.space3),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  static List<Widget> _defaultTiles(
    WorkoutResult result,
    WorkoutRunnerLocalizations l,
  ) {
    final volume = result.totalVolume;
    return [
      ResultsStatTile(
        label: l.statExercises,
        value: '${result.exercises.length}',
      ),
      ResultsStatTile(label: l.statSets, value: '${result.totalSets}'),
      ResultsStatTile(label: l.statReps, value: '${result.totalReps}'),
      if (volume > 0)
        ResultsStatTile(
          label: l.statVolume,
          value: volume.toStringAsFixed(0),
          suffix: l.unitKg,
        ),
    ];
  }
}

/// Reusable stat-tile in the same look as the default tiles inside
/// [ResultsView]. Exposed so custom [WorkoutStatBuilder]s can mix in extra
/// tiles without rebuilding the visual style.
class ResultsStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;

  const ResultsStatTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerCard(
      elevated: true,
      padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: t.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.caption),
          SizedBox(height: t.space1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: t.titleLarge.copyWith(fontSize: 26)),
                if (suffix != null) ...[
                  const SizedBox(width: 4),
                  Text(suffix!, style: t.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSummary extends StatelessWidget {
  final PerformedExerciseDetails ex;
  const _ExerciseSummary({required this.ex});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ex.exerciseName, style: t.title),
          SizedBox(height: t.space2),
          Wrap(
            spacing: t.space2,
            runSpacing: t.space1,
            children: [
              for (var i = 0; i < ex.sets.length; i++)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.space2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: t.surfaceElevated,
                    borderRadius: t.radiusSmall,
                    border: Border.all(color: t.border),
                  ),
                  child: Text(
                    _setLine(ex.sets[i]),
                    style: t.caption.copyWith(color: t.textPrimary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _setLine(set) {
    final w = set.actualWeight;
    if (w == null) return '${set.actualReps} reps';
    final wStr = w == w.roundToDouble() ? w.toInt().toString() : w.toString();
    return '${set.actualReps} × $wStr kg';
  }
}
