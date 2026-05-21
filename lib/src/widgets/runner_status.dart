import 'package:flutter/material.dart';

import '../theme/workout_runner_theme.dart';
import 'internals/runner_pill_button.dart';
import 'internals/timer_text.dart';
import 'runner_scope.dart';

/// Compact chip that surfaces a running workout. Renders nothing while no
/// workout is active, so it is safe to drop unconditionally into an AppBar.
class RunnerStatusChip extends StatelessWidget {
  final VoidCallback? onTap;
  const RunnerStatusChip({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    if (!runner.isRunning) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: t.accentMuted,
          borderRadius: t.radiusPill,
          border: Border.all(color: t.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            TimerText(
              duration: runner.elapsed,
              style: t.title.copyWith(
                fontSize: 13,
                color: t.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim banner suitable for `bottomNavigationBar` slot when you want a tappable
/// "continue workout" surface. Renders nothing when idle.
class RunnerStatusBottomBar extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  const RunnerStatusBottomBar({
    super.key,
    this.onTap,
    this.label = 'Continue workout',
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    if (!runner.isRunning) return const SizedBox.shrink();
    final plan = runner.plan!;
    return SafeArea(
      top: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(t.space4, t.space3, t.space4, t.space3),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border(
              top: BorderSide(color: t.accent.withValues(alpha: 0.4)),
            ),
            boxShadow: [
              BoxShadow(
                color: t.accent.withValues(alpha: 0.16),
                blurRadius: 24,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: t.radiusMedium,
                ),
                child: Icon(Icons.bolt_rounded, color: t.onAccent),
              ),
              SizedBox(width: t.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.name,
                      style: t.title.copyWith(color: t.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: t.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        TimerText(
                          duration: runner.elapsed,
                          style: t.caption.copyWith(color: t.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              RunnerPillButton(label: label, onPressed: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline banner you can place under your AppBar or hero block. Renders an
/// empty SizedBox when idle.
class RunnerStatusBanner extends StatelessWidget {
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const RunnerStatusBanner({super.key, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    if (!runner.isRunning) return const SizedBox.shrink();
    final plan = runner.plan!;
    return Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.space4,
            vertical: t.space3,
          ),
          decoration: BoxDecoration(
            color: t.accentMuted,
            borderRadius: t.radiusLarge,
            border: Border.all(color: t.accent.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: t.accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: t.space2),
              Expanded(
                child: Text(
                  'Active · ${plan.name}',
                  style: t.title.copyWith(color: t.accent, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: t.space2),
              TimerText(
                duration: runner.elapsed,
                style: t.title.copyWith(color: t.accent, fontSize: 14),
              ),
              Icon(Icons.chevron_right_rounded, color: t.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience wrapper that puts a [RunnerStatusChip] into an existing AppBar
/// `actions:` list — call it from your AppBar.
class RunnerStatusAppBarAction extends StatelessWidget {
  final VoidCallback? onTap;
  const RunnerStatusAppBarAction({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space2),
      child: Center(child: RunnerStatusChip(onTap: onTap)),
    );
  }
}
