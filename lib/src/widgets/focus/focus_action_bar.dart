import 'package:flutter/material.dart';

import '../../theme/workout_runner_theme.dart';
import '../internals/runner_pill_button.dart';

/// Sticky bottom action bar for the focus runner. Always shows exactly one
/// primary CTA (Start Set / Finish Set / Continue / Finish Workout) and
/// optional secondary actions on the right (e.g. Skip / Edit).
///
/// Apps drive what the buttons do — this widget is purely visual. Use it
/// inside a `Stack` or under `Column`'s last slot to keep it pinned.
class FocusActionBar extends StatelessWidget {
  final String primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;
  final RunnerButtonStyle primaryStyle;
  final List<FocusSecondaryAction> secondary;

  const FocusActionBar({
    super.key,
    required this.primaryLabel,
    this.primaryIcon,
    this.onPrimary,
    this.primaryStyle = RunnerButtonStyle.accent,
    this.secondary = const [],
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(t.space4, t.space3, t.space4, t.space5),
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final action in secondary) ...[
              _SecondaryButton(action: action),
              SizedBox(width: t.space2),
            ],
            Expanded(
              child: RunnerPillButton(
                label: primaryLabel,
                icon: primaryIcon,
                style: primaryStyle,
                expand: true,
                onPressed: onPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusSecondaryAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const FocusSecondaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class _SecondaryButton extends StatelessWidget {
  final FocusSecondaryAction action;

  const _SecondaryButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Semantics(
      button: true,
      label: action.label,
      child: GestureDetector(
        onTap: action.onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: t.surfaceElevated,
            borderRadius: t.radiusMedium,
            border: Border.all(color: t.border),
          ),
          child: Icon(action.icon, color: t.textPrimary, size: 22),
        ),
      ),
    );
  }
}
