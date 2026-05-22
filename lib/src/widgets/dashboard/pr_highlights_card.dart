import 'package:flutter/widgets.dart';

import '../../stats/personal_records.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/section_label.dart';

/// Compact "recent PRs" card — pure data input.
///
/// Sorts [prs] by [PersonalRecord.achievedAt] descending and caps the rendered
/// rows at [maxItems]. Shows an empty-state row when [prs] is empty.
class PrHighlightsCard extends StatelessWidget {
  final List<PersonalRecord> prs;
  final VoidCallback? onTap;
  final int maxItems;

  const PrHighlightsCard({
    super.key,
    required this.prs,
    this.onTap,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final sorted = [...prs]
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    final visible = sorted.take(maxItems).toList(growable: false);

    return RunnerCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionLabel('Recent PRs'),
          SizedBox(height: t.space3),
          if (visible.isEmpty)
            _EmptyRow(theme: t)
          else
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) SizedBox(height: t.space2),
              _PrRow(record: visible[i]),
            ],
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final WorkoutRunnerThemeData theme;
  const _EmptyRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.space2),
      child: Text('No personal records yet.', style: theme.bodyMuted),
    );
  }
}

class _PrRow extends StatelessWidget {
  final PersonalRecord record;
  const _PrRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TypeChip(type: record.type),
        SizedBox(width: t.space3),
        Expanded(
          child: Text(
            record.exerciseId ?? _categoryLabel(record.type),
            style: t.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: t.space2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatValue(record),
              style: t.title.copyWith(color: t.accent),
            ),
            const SizedBox(width: 4),
            Text(record.unit, style: t.caption),
          ],
        ),
      ],
    );
  }

  static String _categoryLabel(PrType type) {
    switch (type) {
      case PrType.longestDistance:
        return 'Longest distance';
      case PrType.fastestPace:
        return 'Fastest pace';
      case PrType.longestWorkTime:
        return 'Longest work time';
      case PrType.maxWeight:
      case PrType.maxReps:
      case PrType.estimated1RM:
      case PrType.bestVolumeSet:
        return 'Strength PR';
    }
  }

  static String _formatValue(PersonalRecord r) {
    final v = r.value;
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _TypeChip extends StatelessWidget {
  final PrType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final label = _shortLabel(type);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space2, vertical: 4),
      decoration: BoxDecoration(
        color: t.accentMuted,
        borderRadius: t.radiusPill,
        border: Border.all(color: t.accent.withValues(alpha: 0.6)),
      ),
      child: Text(label, style: t.caption.copyWith(color: t.accent)),
    );
  }

  static String _shortLabel(PrType type) {
    switch (type) {
      case PrType.maxWeight:
        return 'MAX WEIGHT';
      case PrType.maxReps:
        return 'MAX REPS';
      case PrType.estimated1RM:
        return 'E1RM';
      case PrType.bestVolumeSet:
        return 'BEST SET';
      case PrType.longestDistance:
        return 'DISTANCE';
      case PrType.fastestPace:
        return 'PACE';
      case PrType.longestWorkTime:
        return 'WORK TIME';
    }
  }
}
