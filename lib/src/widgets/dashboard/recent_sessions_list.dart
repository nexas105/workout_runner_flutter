import 'package:flutter/widgets.dart';

import '../../models/workout_result.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/section_label.dart';

/// Vertical list of recent strength sessions.
///
/// Caller passes already-filtered [results] (typically the most recent first
/// — but the widget does not re-sort to keep behaviour predictable). Each row
/// is a tappable `RunnerCard` with plan name, finished-at date and a compact
/// `sets · volume` summary.
class RecentSessionsList extends StatelessWidget {
  final List<WorkoutResult> results;
  final ValueChanged<WorkoutResult>? onTap;
  final int maxItems;

  const RecentSessionsList({
    super.key,
    required this.results,
    this.onTap,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final visible = results.take(maxItems).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.space1),
          child: const SectionLabel('Recent sessions'),
        ),
        SizedBox(height: t.space3),
        if (visible.isEmpty)
          RunnerCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: t.space2),
              child: Text('No sessions yet.', style: t.bodyMuted),
            ),
          )
        else
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) SizedBox(height: t.space2),
            _SessionRow(
              result: visible[i],
              onTap: onTap == null ? null : () => onTap!(visible[i]),
            ),
          ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  final WorkoutResult result;
  final VoidCallback? onTap;
  const _SessionRow({required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final volume = result.totalVolume;
    final subtitle =
        volume > 0
            ? '${result.totalSets} sets · ${volume.toStringAsFixed(0)} kg'
            : '${result.totalSets} sets';
    return RunnerCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.planId,
                  style: t.title,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: t.space1),
                Text(
                  '${_formatDate(result.finishedAt)} · $subtitle',
                  style: t.bodyMuted,
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: t.space2),
            Icon(_chevron, size: 18, color: t.textMuted),
          ],
        ],
      ),
    );
  }

  static const _chevron = IconData(0xe5cc, fontFamily: 'MaterialIcons');

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

  static String _formatDate(DateTime d) {
    final m = _months[(d.month - 1).clamp(0, 11)];
    return '$m ${d.day}, ${d.year}';
  }
}
