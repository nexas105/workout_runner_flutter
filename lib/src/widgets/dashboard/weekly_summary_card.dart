import 'package:flutter/widgets.dart';

import '../../stats/weekly_workout_summary.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/section_label.dart';
import '../internals/timer_text.dart';

/// Big "this week" summary card. Pure data-input — the caller provides a
/// pre-computed [WeeklyWorkoutSummary] (see `WorkoutStats.weeklySummary`).
///
/// Renders:
///   * Eyebrow `THIS WEEK` plus the date range (`Jan 5 – Jan 11`).
///   * Hero workout count.
///   * Stat grid: sets / reps / volume / duration.
///
/// The card is non-interactive unless [onTap] is provided.
class WeeklySummaryCard extends StatelessWidget {
  final WeeklyWorkoutSummary summary;
  final VoidCallback? onTap;

  const WeeklySummaryCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final volume = summary.totalVolume;
    return RunnerCard(
      onTap: onTap,
      padding: EdgeInsets.all(t.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionLabel(
            'This week',
            trailing: Text(
              _formatRange(summary.start, summary.end),
              style: t.caption,
            ),
          ),
          SizedBox(height: t.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${summary.workoutCount}',
                style: t.heroNumber.copyWith(fontSize: 48),
              ),
              SizedBox(width: t.space2),
              Padding(
                padding: EdgeInsets.only(bottom: t.space2),
                child: Text(
                  summary.workoutCount == 1 ? 'workout' : 'workouts',
                  style: t.bodyMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: t.space4),
          Row(
            children: [
              Expanded(
                child: _Stat(label: 'Sets', value: '${summary.totalSets}'),
              ),
              SizedBox(width: t.space3),
              Expanded(
                child: _Stat(label: 'Reps', value: '${summary.totalReps}'),
              ),
            ],
          ),
          SizedBox(height: t.space3),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Volume',
                  value: volume > 0 ? volume.toStringAsFixed(0) : '0',
                  suffix: 'kg',
                ),
              ),
              SizedBox(width: t.space3),
              Expanded(
                child: _Stat(
                  label: 'Duration',
                  value: TimerText.format(summary.totalDuration),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRange(DateTime start, DateTime end) {
    // Inclusive range, but the stat helper stores end as the start of the
    // following week. Show the displayable last day (end - 1).
    final lastDay =
        end.isAfter(start) ? end.subtract(const Duration(days: 1)) : end;
    final s = _shortDate(start);
    final e = _shortDate(lastDay);
    if (s == e) return s;
    return '$s – $e';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _shortDate(DateTime d) {
    final m = _months[(d.month - 1).clamp(0, 11)];
    return '$m ${d.day}';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;

  const _Stat({required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: t.space3),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: t.radiusMedium,
        border: Border.all(color: t.border),
      ),
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
                Text(value, style: t.titleLarge.copyWith(fontSize: 22)),
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
