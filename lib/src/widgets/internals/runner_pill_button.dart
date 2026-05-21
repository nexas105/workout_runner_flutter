import 'package:flutter/material.dart';

import '../../theme/workout_runner_theme.dart';

enum RunnerButtonStyle { filled, accent, hot, danger, outline, ghost }

/// Compact pill-shaped button used across the package. Falls back to nicer
/// system defaults than [ElevatedButton] inside dark surfaces.
class RunnerPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final RunnerButtonStyle style;
  final bool expand;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const RunnerPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.style = RunnerButtonStyle.accent,
    this.expand = false,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final disabled = onPressed == null;

    final (bg, fg, border) = switch (style) {
      RunnerButtonStyle.accent => (t.accent, t.onAccent, Colors.transparent),
      RunnerButtonStyle.hot => (t.hot, t.onAccent, Colors.transparent),
      RunnerButtonStyle.danger => (t.danger, Colors.white, Colors.transparent),
      RunnerButtonStyle.filled => (t.surfaceElevated, t.textPrimary, t.border),
      RunnerButtonStyle.outline => (
        Colors.transparent,
        t.textPrimary,
        t.textMuted.withValues(alpha: 0.4),
      ),
      RunnerButtonStyle.ghost => (
        Colors.transparent,
        t.textPrimary,
        Colors.transparent,
      ),
    };

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          SizedBox(width: t.space2),
        ],
        Text(
          label,
          style: t.title.copyWith(
            fontSize: fontSize ?? 14,
            color: fg,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    final pad =
        padding ??
        EdgeInsets.symmetric(horizontal: t.space4, vertical: t.space3);

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : t.motionFast,
        decoration: BoxDecoration(
          color: disabled ? bg.withValues(alpha: 0.4) : bg,
          borderRadius: t.radiusPill,
          border: Border.all(color: border),
        ),
        padding: pad,
        alignment: Alignment.center,
        child: content,
      ),
    );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: body,
        ),
      ),
    );
  }
}
