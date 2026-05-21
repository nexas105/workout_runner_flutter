import 'package:flutter/material.dart';

import '../../intelligence/plan_generator.dart';
import '../../theme/workout_runner_theme.dart';

/// Three horizontally-arranged pill chips representing the three
/// [ExperienceLevel] values. The currently selected level gets the accent
/// fill; the others stay outlined.
///
/// Drop the widget anywhere — it sizes itself to a single row and reports
/// taps via [onChanged].
class ExperienceLevelPicker extends StatelessWidget {
  /// Currently selected level. `null` means no chip is highlighted.
  final ExperienceLevel? value;

  /// Fires whenever the user taps a chip (also fires when the same chip is
  /// tapped twice — re-selection still notifies so controllers can re-bind).
  final ValueChanged<ExperienceLevel> onChanged;

  const ExperienceLevelPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Row(
      children: [
        for (final level in ExperienceLevel.values) ...[
          Expanded(
            child: _LevelChip(
              level: level,
              selected: level == value,
              onTap: () => onChanged(level),
            ),
          ),
          if (level != ExperienceLevel.values.last)
            SizedBox(width: t.space2),
        ],
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  final ExperienceLevel level;
  final bool selected;
  final VoidCallback onTap;

  const _LevelChip({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: _labelOf(level),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : t.motionFast,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: selected ? t.accent : Colors.transparent,
            borderRadius: t.radiusPill,
            border: Border.all(
              color: selected ? t.accent : t.border,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: t.space3,
            vertical: t.space2,
          ),
          alignment: Alignment.center,
          child: Text(
            _labelOf(level),
            style: t.title.copyWith(
              fontSize: 14,
              color: selected ? t.onAccent : t.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

String _labelOf(ExperienceLevel level) {
  switch (level) {
    case ExperienceLevel.beginner:
      return 'Beginner';
    case ExperienceLevel.intermediate:
      return 'Intermediate';
    case ExperienceLevel.advanced:
      return 'Advanced';
  }
}
