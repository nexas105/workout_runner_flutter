import 'package:flutter/widgets.dart';

import '../../theme/workout_runner_theme.dart';

/// Uppercase "eyebrow" caption used on cards.
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final label = Text(
      text.toUpperCase(),
      style: t.eyebrow.copyWith(color: color ?? t.textMuted),
    );
    if (trailing == null) return label;
    return Row(children: [Expanded(child: label), trailing!]);
  }
}
