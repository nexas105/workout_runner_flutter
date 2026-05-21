import 'package:flutter/material.dart';

import '../controller/workout_runner.dart';
import '../models/workout_exercise.dart';
import '../theme/workout_runner_theme.dart';
import 'internals/runner_card.dart';
import 'internals/runner_pill_button.dart';
import 'internals/section_label.dart';
import 'internals/timer_text.dart';
import 'set_view.dart';
import 'workout_runner_scope.dart';

/// The headline workout view: plan header, exercise carousel, rest indicator,
/// finish CTA. Drop it into any `body:` slot — the only requirement is a
/// [WorkoutRunnerScope] ancestor.
class RunnerPanel extends StatefulWidget {
  /// Called when the user presses the bottom *Finish workout* button after
  /// the workout result is generated. Use this to navigate away.
  final ValueChanged<bool>? onFinished;

  /// When `true` (default) the carousel auto-scrolls to the active exercise.
  final bool followActiveExercise;

  /// Header content shown above the plan/timer block. `null` → hidden.
  final Widget? header;

  const RunnerPanel({
    super.key,
    this.onFinished,
    this.followActiveExercise = true,
    this.header,
  });

  @override
  State<RunnerPanel> createState() => _RunnerPanelState();
}

class _RunnerPanelState extends State<RunnerPanel> {
  late final PageController _pageController =
      PageController(viewportFraction: 0.92);

  int? _lastFollowed;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = WorkoutRunnerScope.of(context);

    if (runner.plan == null) {
      return _EmptyState();
    }

    _maybeFollowActiveExercise(runner);

    return Container(
      color: t.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (widget.header != null) widget.header!,
            _WorkoutSummary(),
            Expanded(
              child: _ExerciseCarousel(controller: _pageController),
            ),
            _RestStrip(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                t.space5,
                t.space2,
                t.space5,
                t.space5,
              ),
              child: _FinishBar(onFinished: widget.onFinished),
            ),
          ],
        ),
      ),
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
    final runner = WorkoutRunnerScope.of(context);
    final plan = runner.plan!;

    final totalSets =
        plan.exercises.fold<int>(0, (acc, e) => acc + e.sets.length);
    final doneSets = (runner.state?.performed ?? const [])
        .fold<int>(0, (acc, e) => acc + e.sets.length);
    final progress = totalSets == 0 ? 0.0 : doneSets / totalSets;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space5, t.space5, t.space5, t.space3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: t.radiusHero,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.surface,
              t.surfaceElevated,
            ],
          ),
          border: Border.all(color: t.border),
          boxShadow: t.shadowCard,
        ),
        padding: EdgeInsets.all(t.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(
              'Workout in progress',
              color: t.accent,
              trailing: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: t.accent,
                  shape: BoxShape.circle,
                  boxShadow: t.shadowGlow,
                ),
              ),
            ),
            SizedBox(height: t.space3),
            Text(plan.name, style: t.titleLarge),
            SizedBox(height: t.space4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TimerText(duration: runner.elapsed),
                SizedBox(width: t.space4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$doneSets / $totalSets',
                        style: t.title.copyWith(color: t.accent, fontSize: 18),
                      ),
                      Text('sets done', style: t.caption),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space4),
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

class _ExerciseCarousel extends StatelessWidget {
  final PageController controller;
  const _ExerciseCarousel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = WorkoutRunnerScope.of(context);
    final plan = runner.plan!;
    final exercises = plan.exercises;
    final activePage = runner.currentExerciseIndex.clamp(0, exercises.length - 1);

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
        ),
        SizedBox(height: t.space3),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;

  const _ExerciseCard({required this.exercise, required this.exerciseIndex});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = WorkoutRunnerScope.of(context);
    final isActive = runner.isExerciseActive(exerciseIndex);
    final hasOtherActive =
        runner.hasActiveExercise && !isActive;

    return RunnerCard(
      padding: EdgeInsets.fromLTRB(t.space5, t.space5, t.space5, t.space4),
      borderColor: isActive ? t.accent.withValues(alpha: 0.6) : t.border,
      shadow: isActive ? t.shadowGlow : t.shadowCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (exercise.category != null) _CategoryPill(name: exercise.category!.name),
              if (exercise.category != null) SizedBox(width: t.space2),
              if (isActive)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: t.space2, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: t.radiusPill,
                  ),
                  child: Text(
                    'ACTIVE',
                    style: t.eyebrow.copyWith(color: t.onAccent),
                  ),
                ),
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
            Wrap(
              spacing: t.space2,
              runSpacing: t.space1,
              children: [
                for (final m in exercise.muscles)
                  Text(
                    m.name,
                    style: t.caption.copyWith(color: t.textMuted),
                  ),
              ],
            ),
          ],
          if (exercise.description != null) ...[
            SizedBox(height: t.space3),
            Text(
              exercise.description!,
              style: t.bodyMuted,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: t.space4),
          SectionLabel(
            '${exercise.sets.length} sets',
            trailing: isActive
                ? GestureDetector(
                    onTap: runner.clearActiveExercise,
                    child: Text(
                      'Reset',
                      style: t.caption.copyWith(color: t.danger),
                    ),
                  )
                : null,
          ),
          SizedBox(height: t.space3),
          Expanded(
            child: ListView.separated(
              itemCount: exercise.sets.length,
              separatorBuilder: (_, __) => SizedBox(height: t.space2),
              padding: EdgeInsets.zero,
              itemBuilder: (context, i) => SetRow(
                exerciseIndex: exerciseIndex,
                setIndex: i,
                target: exercise.sets[i],
                performed: runner.getPerformedSet(exerciseIndex, i),
              ),
            ),
          ),
          SizedBox(height: t.space3),
          if (!isActive)
            RunnerPillButton(
              label: hasOtherActive
                  ? 'Another exercise is active'
                  : 'Start this exercise',
              icon: hasOtherActive ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
              expand: true,
              style: hasOtherActive
                  ? RunnerButtonStyle.outline
                  : RunnerButtonStyle.accent,
              onPressed: hasOtherActive
                  ? null
                  : () => runner.setActiveExercise(exerciseIndex),
            )
          else
            RunnerPillButton(
              label: 'Exercise active',
              icon: Icons.check_rounded,
              expand: true,
              style: RunnerButtonStyle.filled,
              onPressed: null,
            ),
        ],
      ),
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

class _PageDots extends StatelessWidget {
  final int length;
  final int current;
  final int? activeIndex;

  const _PageDots({
    required this.length,
    required this.current,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < length; i++)
          AnimatedContainer(
            duration: t.motionFast,
            margin: EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == activeIndex
                  ? t.accent
                  : i == current
                      ? t.textPrimary
                      : t.textDim,
              borderRadius: t.radiusPill,
            ),
          ),
      ],
    );
  }
}

class _RestStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = WorkoutRunnerScope.of(context);
    if (!runner.isResting) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space2),
      child: RunnerCard(
        color: t.surfaceElevated,
        borderColor: t.hot.withValues(alpha: 0.45),
        shadow: [
          BoxShadow(
            color: t.hot.withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: -6,
          ),
        ],
        padding: EdgeInsets.symmetric(
          horizontal: t.space4,
          vertical: t.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.hotMuted,
                borderRadius: t.radiusSmall,
              ),
              child: Icon(Icons.hourglass_top_rounded, color: t.hot, size: 20),
            ),
            SizedBox(width: t.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rest', style: t.eyebrow),
                  Text(
                    TimerText.format(runner.restRemaining),
                    style: t.titleLarge
                        .copyWith(fontSize: 28, color: t.textPrimary),
                  ),
                ],
              ),
            ),
            RunnerPillButton(
              label: 'Skip',
              style: RunnerButtonStyle.outline,
              onPressed: runner.skipRest,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishBar extends StatelessWidget {
  final ValueChanged<bool>? onFinished;
  const _FinishBar({required this.onFinished});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = WorkoutRunnerScope.of(context);
    return Row(
      children: [
        Expanded(
          child: RunnerPillButton(
            label: 'Finish workout',
            icon: Icons.flag_circle_rounded,
            expand: true,
            style: RunnerButtonStyle.hot,
            onPressed: () async {
              final result = await runner.finish();
              onFinished?.call(result != null);
            },
          ),
        ),
      ],
    );
  }
}
