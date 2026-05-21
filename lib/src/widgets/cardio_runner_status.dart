import 'package:flutter/material.dart';

import '../theme/workout_runner_theme.dart';
import 'cardio_runner_scope.dart';
import 'internals/runner_pill_button.dart';
import 'internals/timer_text.dart';

/// Tiny pill that surfaces a running cardio session. Renders nothing while
/// idle, so it is safe to drop unconditionally into an AppBar.
class CardioRunnerStatusChip extends StatelessWidget {
  final VoidCallback? onTap;
  const CardioRunnerStatusChip({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);
    if (runner.plan == null) return const SizedBox.shrink();
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
            Icon(Icons.directions_run_rounded, size: 14, color: t.accent),
            const SizedBox(width: 6),
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

/// Inline banner — drop under your AppBar / hero block. Empty SizedBox when
/// idle.
class CardioRunnerStatusBanner extends StatelessWidget {
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const CardioRunnerStatusBanner({super.key, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);
    if (runner.plan == null) return const SizedBox.shrink();
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
              Icon(Icons.directions_run_rounded, color: t.accent, size: 18),
              SizedBox(width: t.space2),
              Expanded(
                child: Text(
                  'Cardio · ${plan.name}',
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

/// Bottom-attached *continue cardio* CTA. Empty when idle.
class CardioRunnerStatusBottomBar extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  const CardioRunnerStatusBottomBar({
    super.key,
    this.onTap,
    this.label = 'Continue cardio',
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);
    if (runner.plan == null) return const SizedBox.shrink();
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
                child: Icon(Icons.directions_run_rounded, color: t.onAccent),
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

/// Drops a [CardioRunnerStatusChip] into an `AppBar.actions:` slot with the
/// expected horizontal padding. Renders nothing while no cardio session is
/// active, so it's safe to mount unconditionally.
class CardioRunnerStatusAppBarAction extends StatelessWidget {
  final VoidCallback? onTap;
  const CardioRunnerStatusAppBarAction({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space2),
      child: Center(child: CardioRunnerStatusChip(onTap: onTap)),
    );
  }
}
