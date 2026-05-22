import 'package:flutter/material.dart';

import '../../l10n/workout_runner_localizations.dart';
import '../../theme/workout_runner_theme.dart';
import 'runner_pill_button.dart';
import 'timer_text.dart';

/// Full-bleed rest overlay. Drops in via a `Stack`, visible only when
/// `visible == true`. Calls [onSkip] when the user wants to bail out and
/// [onAdd] when they want to bump the timer by 30 s.
class RestOverlay extends StatelessWidget {
  final bool visible;
  final Duration remaining;
  final Duration total;
  final VoidCallback onSkip;
  final ValueChanged<Duration>? onAdd;

  const RestOverlay({
    super.key,
    required this.visible,
    required this.remaining,
    required this.total,
    required this.onSkip,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final progress =
        total.inSeconds == 0
            ? 0.0
            : (1 - remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);

    return IgnorePointer(
      ignoring: !visible,
      child: Semantics(
        liveRegion: visible,
        label:
            visible
                ? '${l.restHeader}, ${remaining.inSeconds} ${l.restRemainingTrailing}'
                : null,
        child: AnimatedOpacity(
          duration: reduceMotion ? Duration.zero : t.motionMedium,
          curve: Curves.easeOut,
          opacity: visible ? 1 : 0,
          child: Container(
            color: t.restBackdrop,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.space6,
                  vertical: t.space5,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    Text(l.restHeader, style: t.eyebrow.copyWith(color: t.hot)),
                    SizedBox(height: t.space3),
                    _RingTimer(progress: progress, remaining: remaining),
                    SizedBox(height: t.space3),
                    Text(
                      remaining.inSeconds <= 3 ? l.restGetReady : l.restBreathe,
                      style: t.bodyMuted,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: RunnerPillButton(
                            label: l.restAdd30,
                            icon: Icons.add_rounded,
                            style: RunnerButtonStyle.outline,
                            expand: true,
                            onPressed:
                                onAdd == null
                                    ? null
                                    : () => onAdd!(const Duration(seconds: 30)),
                          ),
                        ),
                        SizedBox(width: t.space2),
                        Expanded(
                          flex: 2,
                          child: RunnerPillButton(
                            label: l.restSkip,
                            icon: Icons.skip_next_rounded,
                            style: RunnerButtonStyle.hot,
                            expand: true,
                            onPressed: onSkip,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingTimer extends StatelessWidget {
  final double progress;
  final Duration remaining;

  const _RingTimer({required this.progress, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: t.restProgressTrackColor,
              valueColor: AlwaysStoppedAnimation(t.restProgressColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TimerText(
                duration: remaining,
                style: t.heroNumber.copyWith(
                  fontSize: 54,
                  color: t.textPrimary,
                ),
              ),
              SizedBox(height: t.space1),
              Text(
                WorkoutRunnerLocalizationsScope.of(
                  context,
                ).restRemainingTrailing,
                style: t.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
