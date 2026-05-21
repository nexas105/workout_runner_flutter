import 'package:flutter/widgets.dart';

import '../../theme/workout_runner_theme.dart';

/// Renders a [Duration] as `mm:ss` (or `hh:mm:ss` past 60min) with tabular
/// numbers so the digits don't dance while ticking.
class TimerText extends StatelessWidget {
  final Duration duration;
  final TextStyle? style;
  final Color? color;
  final bool compact;

  const TimerText({
    super.key,
    required this.duration,
    this.style,
    this.color,
    this.compact = false,
  });

  static String format(Duration d, {bool compact = false}) {
    final negative = d.isNegative;
    final v = d.abs();
    final h = v.inHours;
    final m = v.inMinutes.remainder(60);
    final s = v.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    final text =
        h > 0
            ? '${h.toString().padLeft(compact ? 1 : 2, '0')}:$mm:$ss'
            : '$mm:$ss';
    return negative ? '-$text' : text;
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final base = style ?? t.heroNumber;
    final v = duration.abs();
    final h = v.inHours;
    final m = v.inMinutes.remainder(60);
    final s = v.inSeconds.remainder(60);
    final spoken = h > 0
        ? '$h hours $m minutes $s seconds'
        : '$m minutes $s seconds';
    return Semantics(
      value: spoken,
      excludeSemantics: true,
      child: Text(
        format(duration, compact: compact),
        style: base.copyWith(color: color ?? base.color),
      ),
    );
  }
}
