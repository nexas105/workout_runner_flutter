import 'package:flutter/widgets.dart';

import '../../theme/workout_runner_theme.dart';

/// Surface used by every bundled widget — fills with [WorkoutRunnerThemeData.surface]
/// and applies the standard border + drop shadow.
class RunnerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final bool elevated;

  const RunnerCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.shadow,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final radius = borderRadius ?? t.radiusLarge;
    final decoration = BoxDecoration(
      color: color ?? (elevated ? t.surfaceElevated : t.surface),
      borderRadius: radius,
      border: Border.all(color: borderColor ?? t.border, width: 1),
      boxShadow: shadow ?? t.shadowCard,
    );
    Widget body = Container(
      decoration: decoration,
      padding: padding ?? EdgeInsets.all(t.space4),
      child: child,
    );
    if (onTap != null) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: body,
      );
    }
    return body;
  }
}
