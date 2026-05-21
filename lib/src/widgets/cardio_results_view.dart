import 'package:flutter/material.dart';

import '../l10n/workout_runner_localizations.dart';
import '../models/cardio/cardio_lap.dart';
import '../models/cardio/cardio_result.dart';
import '../theme/workout_runner_theme.dart';
import 'internals/runner_card.dart';
import 'internals/runner_pill_button.dart';
import 'internals/section_label.dart';
import 'internals/timer_text.dart';

/// Build the row of stat tiles shown in a [CardioResultsView]. Use the
/// bundled [CardioResultsStatTile] for consistent visuals.
typedef CardioStatBuilder = List<Widget> Function(
  BuildContext context,
  CardioResult result,
);

/// Stand-alone result summary for a finished cardio session.
class CardioResultsView extends StatelessWidget {
  final CardioResult result;
  final VoidCallback? onClose;
  final String closeLabel;

  /// Replaces the default stat tiles (Laps / Work time / Distance / Avg pace).
  /// When `null` the bundled tiles are shown.
  final CardioStatBuilder? statBuilder;

  const CardioResultsView({
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
              _StatsGrid(result: result, builder: statBuilder),
              SizedBox(height: t.space5),
              SectionLabel('${l.statLaps}  ·  ${result.laps.length}'),
              SizedBox(height: t.space3),
              for (var i = 0; i < result.laps.length; i++) ...[
                _LapCard(lap: result.laps[i], number: i + 1),
                SizedBox(height: t.space2),
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
  final CardioResult result;
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
              Icon(Icons.directions_run_rounded, color: t.accent, size: 28),
              SizedBox(width: t.space2),
              Text(l.cardioComplete, style: t.title.copyWith(color: t.accent)),
            ],
          ),
          SizedBox(height: t.space3),
          TimerText(duration: result.duration),
          SizedBox(height: t.space1),
          Text(
            result.planName.isEmpty ? result.planId : result.planName,
            style: t.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final CardioResult result;
  final CardioStatBuilder? builder;
  const _StatsGrid({required this.result, this.builder});

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
    CardioResult result,
    WorkoutRunnerLocalizations l,
  ) {
    final distance = result.totalDistanceMeters;
    final pace = result.avgPacePerKm;
    final work = result.totalWorkTime;
    return [
      CardioResultsStatTile(label: l.statLaps, value: '${result.totalLaps}'),
      CardioResultsStatTile(
        label: l.statWorkTime,
        value: TimerText.format(work),
      ),
      if (distance > 0)
        CardioResultsStatTile(
          label: l.statDistance,
          value: (distance / 1000).toStringAsFixed(2),
          suffix: l.unitKm,
        ),
      if (pace != null)
        CardioResultsStatTile(
          label: l.statAvgPace,
          value: TimerText.format(pace),
          suffix: l.unitPerKm,
        ),
    ];
  }
}

/// Reusable stat-tile in the same look as the default tiles inside
/// [CardioResultsView]. Exposed so custom [CardioStatBuilder]s can mix in
/// extra tiles without rebuilding the visual style.
class CardioResultsStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  const CardioResultsStatTile({
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: t.titleLarge.copyWith(fontSize: 22)),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(suffix!, style: t.caption),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LapCard extends StatelessWidget {
  final CardioLap lap;
  final int number;
  const _LapCard({required this.lap, required this.number});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerCard(
      padding: EdgeInsets.symmetric(horizontal: t.space4, vertical: t.space3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.accentMuted,
              borderRadius: t.radiusSmall,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: t.title.copyWith(color: t.accent, fontSize: 14),
            ),
          ),
          SizedBox(width: t.space3),
          Expanded(
            child: Wrap(
              spacing: t.space3,
              children: [
                Text(TimerText.format(lap.duration), style: t.body),
                if (lap.distanceMeters != null)
                  Text(
                    '${(lap.distanceMeters! / 1000).toStringAsFixed(2)} km',
                    style: t.body,
                  ),
                if (lap.avgPacePerKm != null)
                  Text(
                    '${TimerText.format(lap.avgPacePerKm!)} /km',
                    style: t.caption,
                  ),
                if (lap.avgHeartRate != null)
                  Text('${lap.avgHeartRate} bpm', style: t.caption),
                if (lap.rpe != null)
                  Text(
                    'RPE ${lap.rpe}',
                    style: t.caption.copyWith(color: t.hot),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
