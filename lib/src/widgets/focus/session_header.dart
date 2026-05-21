import 'package:flutter/material.dart';

import '../../controller/workout_runner.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/timer_text.dart';
import '../runner_scope.dart';

/// Compact header block for the focus runner. Shows plan name, elapsed timer,
/// progress (`done sets / total sets`), and pause/resume + finish actions.
///
/// Doesn't own state — reads from the ambient [WorkoutRunner] via
/// [RunnerScope]. Wrap in a custom `WorkoutRunnerThemeData` to restyle.
class SessionHeader extends StatelessWidget {
  final VoidCallback? onPauseToggle;
  final VoidCallback? onFinish;
  final String? titleOverride;

  const SessionHeader({
    super.key,
    this.onPauseToggle,
    this.onFinish,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final plan = runner.plan;
    final title =
        titleOverride ?? plan?.name ?? (plan?.id ?? 'Workout');

    final totalSets = plan?.totalTargetSets ?? 0;
    final doneSets =
        runner.state?.performed
            .fold<int>(0, (sum, e) => sum + e.sets.length) ??
        0;
    final progress = totalSets == 0 ? 0.0 : (doneSets / totalSets).clamp(0, 1).toDouble();

    return Container(
      padding: EdgeInsets.fromLTRB(t.space5, t.space4, t.space5, t.space3),
      color: t.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: t.space1),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TimerText(
                          duration: runner.elapsed,
                          style: t.title.copyWith(
                            color: t.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: t.space2),
                        Text(
                          '$doneSets / $totalSets',
                          style: t.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onPauseToggle != null)
                _IconChip(
                  icon: runner.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  semanticLabel: runner.isPaused ? 'Resume' : 'Pause',
                  onTap: onPauseToggle!,
                ),
              if (onFinish != null) ...[
                SizedBox(width: t.space2),
                _IconChip(
                  icon: Icons.check_rounded,
                  semanticLabel: 'Finish workout',
                  accent: true,
                  onTap: onFinish!,
                ),
              ],
            ],
          ),
          SizedBox(height: t.space3),
          ClipRRect(
            borderRadius: t.radiusPill,
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: t.surfaceElevated,
                valueColor: AlwaysStoppedAnimation(t.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final bool accent;
  final VoidCallback onTap;

  const _IconChip({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent ? t.accent : t.surfaceElevated,
            borderRadius: t.radiusMedium,
            border: Border.all(color: accent ? Colors.transparent : t.border),
          ),
          child: Icon(icon, color: accent ? t.onAccent : t.textPrimary, size: 22),
        ),
      ),
    );
  }
}
