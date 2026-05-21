import 'package:flutter/material.dart';

import '../controller/workout_runner.dart';
import '../models/workout_exercise.dart';
import '../theme/workout_runner_theme.dart';
import 'internals/rest_overlay.dart';
import 'internals/runner_card.dart';
import 'internals/runner_pill_button.dart';
import 'internals/section_label.dart';
import 'internals/timer_text.dart';
import 'set_view.dart';
import 'runner_scope.dart';

/// The headline workout view: plan header, exercise carousel, finish CTA and
/// a full-bleed rest overlay that drops in while the user is resting.
class RunnerPanel extends StatefulWidget {
  /// Called after the workout finishes (button press → result emitted).
  final ValueChanged<bool>? onFinished;

  /// When `true` (default) the carousel auto-scrolls to the active exercise.
  final bool followActiveExercise;

  /// Header content shown above the plan/timer block. `null` → hidden.
  ///
  /// Takes precedence over [headerBuilder] when both are set.
  final Widget? header;

  /// Builder variant of [header]. Receives the active [WorkoutRunner] so the
  /// header can react to runner state (timer, elapsed, paused) without an
  /// external rebuild trigger. Ignored when [header] is non-null.
  final Widget Function(BuildContext context, WorkoutRunner runner)?
      headerBuilder;

  /// Replaces the bundled "Finish workout" CTA at the bottom of the panel.
  /// Receives the active [WorkoutRunner] so the builder can drive its own
  /// disabled / loading state. When `null` the default `_FinishBar` is used.
  final Widget Function(BuildContext context, WorkoutRunner runner)?
      finishButtonBuilder;

  /// When `true` (default) confirms before finishing if there are pending
  /// sets, and disables the *Finish* button when zero sets are done.
  final bool confirmFinish;

  const RunnerPanel({
    super.key,
    this.onFinished,
    this.followActiveExercise = true,
    this.header,
    this.headerBuilder,
    this.finishButtonBuilder,
    this.confirmFinish = true,
  });

  @override
  State<RunnerPanel> createState() => _RunnerPanelState();
}

class _RunnerPanelState extends State<RunnerPanel> {
  late final PageController _pageController = PageController(
    viewportFraction: 0.94,
  );

  int? _lastFollowed;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);

    if (runner.plan == null) {
      return _EmptyState();
    }

    _maybeFollowActiveExercise(runner);

    return Stack(
      children: [
        Container(
          color: t.background,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (widget.header != null)
                  widget.header!
                else if (widget.headerBuilder != null)
                  widget.headerBuilder!(context, runner),
                _WorkoutSummary(),
                Expanded(child: _ExerciseCarousel(controller: _pageController)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    t.space5,
                    t.space2,
                    t.space5,
                    t.space5,
                  ),
                  child: widget.finishButtonBuilder != null
                      ? widget.finishButtonBuilder!(context, runner)
                      : _FinishBar(
                          onFinished: widget.onFinished,
                          confirmFinish: widget.confirmFinish,
                        ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: RestOverlay(
            visible: runner.isResting,
            remaining: runner.restRemaining,
            total:
                runner.restTotal == Duration.zero
                    ? runner.restRemaining
                    : runner.restTotal,
            onSkip: runner.skipRest,
          ),
        ),
      ],
    );
  }

  void _maybeFollowActiveExercise(WorkoutRunner runner) {
    if (!widget.followActiveExercise) return;
    final active = runner.activeExerciseIndex ?? runner.currentExerciseIndex;
    if (active == _lastFollowed) return;
    _lastFollowed = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      _pageController.animateToPage(
        active,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Container(
      color: t.background,
      alignment: Alignment.center,
      padding: EdgeInsets.all(t.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded, size: 48, color: t.textDim),
          SizedBox(height: t.space3),
          Text('No active workout', style: t.titleLarge),
          SizedBox(height: t.space2),
          Text(
            'Start a workout from your app to see it here.',
            textAlign: TextAlign.center,
            style: t.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _WorkoutSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final plan = runner.plan;
    if (plan == null) return const SizedBox.shrink();

    final totalSets = plan.exercises.fold<int>(
      0,
      (acc, e) => acc + e.sets.length,
    );
    final doneSets = (runner.state?.performed ?? const []).fold<int>(
      0,
      (acc, e) => acc + e.sets.length,
    );
    final progress = totalSets == 0 ? 0.0 : doneSets / totalSets;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space5, t.space4, t.space5, t.space3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: t.radiusHero,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.surface, t.surfaceElevated],
          ),
          border: Border.all(color: t.border),
          boxShadow: t.shadowCard,
        ),
        padding: EdgeInsets.all(t.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(
              'Workout in progress',
              color: t.accent,
              trailing: _LivePulse(color: t.accent),
            ),
            SizedBox(height: t.space2),
            Text(
              plan.name,
              style: t.title.copyWith(fontSize: 17),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: t.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TimerText(
                  duration: runner.elapsed,
                  style: t.heroNumber.copyWith(fontSize: 44),
                ),
                SizedBox(width: t.space3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$doneSets / $totalSets',
                        style: t.title.copyWith(color: t.accent, fontSize: 16),
                      ),
                      Text('sets done', style: t.caption),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space3),
            ClipRRect(
              borderRadius: t.radiusPill,
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress.clamp(0.0, 1.0),
                backgroundColor: t.surfaceElevated,
                valueColor: AlwaysStoppedAnimation(t.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  final Color color;
  const _LivePulse({required this.color});

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 0.85 + (0.3 * (1 - (_ctrl.value - 0.5).abs() * 2));
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.55),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExerciseCarousel extends StatelessWidget {
  final PageController controller;
  const _ExerciseCarousel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final plan = runner.plan;
    if (plan == null) return const SizedBox.shrink();
    final exercises = plan.exercises;
    if (exercises.isEmpty) return const SizedBox.shrink();
    final activePage = runner.currentExerciseIndex.clamp(
      0,
      exercises.length - 1,
    );

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: exercises.length,
            onPageChanged: runner.showExercise,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.space2,
                  vertical: t.space2,
                ),
                child: _ExerciseCard(
                  exercise: exercises[index],
                  exerciseIndex: index,
                ),
              );
            },
          ),
        ),
        SizedBox(height: t.space2),
        _PageDots(
          length: exercises.length,
          current: activePage,
          activeIndex: runner.activeExerciseIndex,
          performed: _performedCounts(runner),
        ),
        SizedBox(height: t.space3),
      ],
    );
  }

  Map<int, int> _performedCounts(WorkoutRunner runner) {
    final out = <int, int>{};
    for (final ex in (runner.state?.performed ?? const [])) {
      out[ex.exerciseIndex] = ex.sets.length;
    }
    return out;
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;

  const _ExerciseCard({required this.exercise, required this.exerciseIndex});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final isActive = runner.isExerciseActive(exerciseIndex);
    final hasOtherActive = runner.hasActiveExercise && !isActive;

    var doneCount = 0;
    for (final pe in runner.state?.performed ?? const []) {
      if (pe.exerciseIndex == exerciseIndex) {
        doneCount = pe.sets.length;
        break;
      }
    }
    final totalCount = exercise.sets.length;
    final allDone = totalCount > 0 && doneCount >= totalCount;

    return RunnerCard(
      padding: EdgeInsets.zero,
      borderColor:
          isActive
              ? t.accent.withValues(alpha: 0.65)
              : allDone
              ? t.success.withValues(alpha: 0.45)
              : t.border,
      shadow: isActive ? t.shadowGlow : t.shadowCard,
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.space4,
              t.space4,
              t.space4,
              t.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (exercise.category != null)
                      _CategoryPill(name: exercise.category!.name),
                    if (exercise.category != null) SizedBox(width: t.space2),
                    if (isActive) _Badge(label: 'ACTIVE', color: t.accent),
                    if (!isActive && allDone)
                      _Badge(label: 'DONE', color: t.success),
                    const Spacer(),
                    Text(
                      '${exerciseIndex + 1}/${runner.exercises.length}',
                      style: t.caption,
                    ),
                  ],
                ),
                SizedBox(height: t.space3),
                Text(exercise.name, style: t.titleLarge),
                if (exercise.muscles.isNotEmpty) ...[
                  SizedBox(height: t.space2),
                  Text(
                    exercise.muscles.map((m) => m.name).join(' · '),
                    style: t.caption.copyWith(color: t.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          // Sets
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                t.space4,
                t.space3,
                t.space4,
                t.space3,
              ),
              itemCount: exercise.sets.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: t.space2),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Row(
                    children: [
                      SectionLabel(
                        '$doneCount / $totalCount sets',
                        color: allDone ? t.success : t.textMuted,
                      ),
                      const Spacer(),
                      if (isActive)
                        GestureDetector(
                          onTap: runner.clearActiveExercise,
                          child: Text(
                            'Reset',
                            style: t.caption.copyWith(color: t.danger),
                          ),
                        ),
                    ],
                  );
                }
                final si = i - 1;
                return SetRow(
                  exerciseIndex: exerciseIndex,
                  setIndex: si,
                  target: exercise.sets[si],
                  performed: runner.getPerformedSet(exerciseIndex, si),
                );
              },
            ),
          ),
          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.space4,
              t.space2,
              t.space4,
              t.space4,
            ),
            child: _CardCta(
              isActive: isActive,
              allDone: allDone,
              hasOtherActive: hasOtherActive,
              exerciseIndex: exerciseIndex,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space2, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: t.radiusPill),
      child: Text(label, style: t.eyebrow.copyWith(color: t.onAccent)),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String name;
  const _CategoryPill({required this.name});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space2, vertical: 4),
      decoration: BoxDecoration(
        color: t.accentMuted,
        borderRadius: t.radiusPill,
      ),
      child: Text(
        name.toUpperCase(),
        style: t.eyebrow.copyWith(color: t.accent),
      ),
    );
  }
}

class _CardCta extends StatelessWidget {
  final bool isActive;
  final bool allDone;
  final bool hasOtherActive;
  final int exerciseIndex;

  const _CardCta({
    required this.isActive,
    required this.allDone,
    required this.hasOtherActive,
    required this.exerciseIndex,
  });

  @override
  Widget build(BuildContext context) {
    final runner = RunnerScope.of(context);

    if (allDone) {
      return RunnerPillButton(
        label: 'Exercise complete',
        icon: Icons.check_circle_rounded,
        style: RunnerButtonStyle.filled,
        expand: true,
        onPressed: null,
      );
    }

    if (!isActive) {
      return RunnerPillButton(
        label:
            hasOtherActive
                ? 'Another exercise is active'
                : 'Start this exercise',
        icon:
            hasOtherActive
                ? Icons.lock_outline_rounded
                : Icons.play_arrow_rounded,
        expand: true,
        style:
            hasOtherActive
                ? RunnerButtonStyle.outline
                : RunnerButtonStyle.accent,
        onPressed:
            hasOtherActive
                ? null
                : () => runner.setActiveExercise(exerciseIndex),
      );
    }

    // Active exercise — show the next pending set as a quick-start hero.
    final nextSet = _nextPendingSetIndex(runner, exerciseIndex);
    if (nextSet == null) {
      return RunnerPillButton(
        label: 'All sets complete',
        icon: Icons.check_circle_rounded,
        style: RunnerButtonStyle.filled,
        expand: true,
        onPressed: null,
      );
    }
    final isRunning =
        runner.activeSetExerciseIndex == exerciseIndex &&
        runner.activeSetIndex == nextSet;
    if (isRunning) {
      return RunnerPillButton(
        label: 'Tap the running set to finish',
        icon: Icons.timer_outlined,
        style: RunnerButtonStyle.outline,
        expand: true,
        onPressed: null,
      );
    }
    return RunnerPillButton(
      label: 'Start set ${nextSet + 1}',
      icon: Icons.play_arrow_rounded,
      style: RunnerButtonStyle.accent,
      expand: true,
      onPressed: () => runner.startSet(exerciseIndex, nextSet),
    );
  }

  int? _nextPendingSetIndex(WorkoutRunner runner, int exIdx) {
    final plan = runner.plan;
    if (plan == null || exIdx < 0 || exIdx >= plan.exercises.length) {
      return null;
    }
    final ex = plan.exercises[exIdx];
    for (var i = 0; i < ex.sets.length; i++) {
      if (runner.getPerformedSet(exIdx, i) == null) return i;
    }
    return null;
  }
}

class _PageDots extends StatelessWidget {
  final int length;
  final int current;
  final int? activeIndex;
  final Map<int, int> performed;

  const _PageDots({
    required this.length,
    required this.current,
    required this.activeIndex,
    required this.performed,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final exercises = runner.exercises;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < length; i++)
          _Dot(
            isCurrent: i == current,
            isActive: i == activeIndex,
            isDone:
                (performed[i] ?? 0) >= exercises[i].sets.length &&
                exercises[i].sets.isNotEmpty,
            t: t,
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool isCurrent;
  final bool isActive;
  final bool isDone;
  final WorkoutRunnerThemeData t;

  const _Dot({
    required this.isCurrent,
    required this.isActive,
    required this.isDone,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive
            ? t.accent
            : isDone
            ? t.success
            : isCurrent
            ? t.textPrimary
            : t.textDim;
    return AnimatedContainer(
      duration: t.motionFast,
      margin: EdgeInsets.symmetric(horizontal: 3),
      width: isCurrent ? 22 : 6,
      height: 6,
      decoration: BoxDecoration(color: color, borderRadius: t.radiusPill),
    );
  }
}

class _FinishBar extends StatelessWidget {
  final ValueChanged<bool>? onFinished;
  final bool confirmFinish;

  const _FinishBar({required this.onFinished, required this.confirmFinish});

  @override
  Widget build(BuildContext context) {
    final runner = RunnerScope.of(context);
    final plan = runner.plan;
    if (plan == null) return const SizedBox.shrink();
    final doneSets = (runner.state?.performed ?? const []).fold<int>(
      0,
      (acc, e) => acc + e.sets.length,
    );
    final totalSets = plan.exercises.fold<int>(
      0,
      (acc, e) => acc + e.sets.length,
    );

    return Row(
      children: [
        Expanded(
          child: RunnerPillButton(
            label:
                doneSets == 0
                    ? 'Cancel workout'
                    : doneSets >= totalSets
                    ? 'Finish workout'
                    : 'Finish workout ($doneSets/$totalSets)',
            icon:
                doneSets == 0 ? Icons.close_rounded : Icons.flag_circle_rounded,
            expand: true,
            style:
                doneSets == 0
                    ? RunnerButtonStyle.outline
                    : RunnerButtonStyle.hot,
            onPressed:
                () => _handleFinish(context, runner, doneSets, totalSets),
          ),
        ),
      ],
    );
  }

  Future<void> _handleFinish(
    BuildContext context,
    WorkoutRunner runner,
    int doneSets,
    int totalSets,
  ) async {
    if (doneSets == 0) {
      final cancel = await _confirm(
        context,
        title: 'Cancel workout?',
        body: 'No sets recorded yet — the workout will be discarded.',
        confirmLabel: 'Cancel workout',
        destructive: true,
      );
      if (cancel != true) return;
      await runner.cancel();
      onFinished?.call(false);
      return;
    }
    if (confirmFinish && doneSets < totalSets) {
      final go = await _confirm(
        context,
        title: 'Finish workout?',
        body:
            'You completed $doneSets of $totalSets sets. '
            'Remaining sets will be left unfinished.',
        confirmLabel: 'Finish',
        destructive: false,
      );
      if (go != true) return;
    }
    final result = await runner.finish();
    onFinished?.call(result != null);
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required bool destructive,
  }) {
    final t = WorkoutRunnerTheme.of(context);
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: t.surface,
            shape: RoundedRectangleBorder(borderRadius: t.radiusLarge),
            child: Padding(
              padding: EdgeInsets.all(t.space5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleLarge),
                  SizedBox(height: t.space2),
                  Text(body, style: t.bodyMuted),
                  SizedBox(height: t.space5),
                  Row(
                    children: [
                      Expanded(
                        child: RunnerPillButton(
                          label: 'Keep going',
                          style: RunnerButtonStyle.outline,
                          expand: true,
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                      ),
                      SizedBox(width: t.space2),
                      Expanded(
                        child: RunnerPillButton(
                          label: confirmLabel,
                          style:
                              destructive
                                  ? RunnerButtonStyle.danger
                                  : RunnerButtonStyle.hot,
                          expand: true,
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
