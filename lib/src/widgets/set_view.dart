import 'package:flutter/material.dart';

import '../controller/workout_runner.dart';
import '../l10n/workout_runner_localizations.dart';
import '../models/performed_set.dart';
import '../models/set_type.dart';
import '../models/workout_set.dart';
import '../theme/workout_runner_theme.dart';
import 'internals/hero_stepper.dart';
import 'internals/runner_card.dart';
import 'internals/runner_pill_button.dart';
import 'internals/timer_text.dart';
import 'runner_scope.dart';

String? _labelFor(SetType type, WorkoutRunnerLocalizations l) =>
    type == SetType.working ? null : l.labelForSetType(type);

/// Lifecycle state of a [SetRow], surfaced to custom trailing builders.
enum SetRowState { pending, running, done, locked }

/// Data passed to a [SetRow.trailingBuilder] override.
class SetRowSlotData {
  final WorkoutRunner runner;
  final WorkoutSet target;
  final PerformedSet? performed;
  final int exerciseIndex;
  final int setIndex;
  final SetRowState state;

  const SetRowSlotData({
    required this.runner,
    required this.target,
    required this.performed,
    required this.exerciseIndex,
    required this.setIndex,
    required this.state,
  });
}

/// Builder signature for [SetRow.trailingBuilder]. Return any widget — the
/// bundled trailing visuals are shown when the builder is `null`.
typedef SetTrailingBuilder = Widget Function(
  BuildContext context,
  SetRowSlotData data,
);

enum _SetMode { pending, running, done, locked }

/// A single set row inside an exercise card. Handles the start / running /
/// done visuals and opens the [SetInputSheet] when the user taps a running
/// set or a finished set (to edit it).
class SetRow extends StatelessWidget {
  final int exerciseIndex;
  final int setIndex;
  final WorkoutSet target;
  final PerformedSet? performed;

  /// Replaces the default trailing widget (play button / timer pill / edit
  /// icon / lock). Receives the current row state so builders can adapt.
  final SetTrailingBuilder? trailingBuilder;

  const SetRow({
    super.key,
    required this.exerciseIndex,
    required this.setIndex,
    required this.target,
    this.performed,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = RunnerScope.of(context);
    final mode = _modeFor(runner);

    final typeAccent =
        target.type == SetType.working ? null : t.accentFor(target.type);

    final accent = switch (mode) {
      _SetMode.running => t.hot,
      _SetMode.done => t.accent,
      _SetMode.pending => typeAccent ?? t.textPrimary,
      _ => t.textDim,
    };

    final isWarmup = target.type == SetType.warmup;

    return Opacity(
      opacity: isWarmup && mode != _SetMode.running && mode != _SetMode.done
          ? 0.85
          : 1,
      child: RunnerCard(
        padding: EdgeInsets.symmetric(horizontal: t.space4, vertical: t.space3),
        borderRadius: t.radiusMedium,
        color:
            mode == _SetMode.running
                ? t.hot.withValues(alpha: 0.08)
                : t.surfaceElevated,
        borderColor: mode == _SetMode.running
            ? t.hot
            : (typeAccent ?? t.border),
        shadow:
            mode == _SetMode.running
                ? [
                  BoxShadow(
                    color: t.hot.withValues(alpha: 0.25),
                    blurRadius: 18,
                    spreadRadius: -4,
                  ),
                ]
                : const <BoxShadow>[],
        onTap: () => _handleTap(context, runner, mode),
        child: Row(
          children: [
            _SetBadge(setIndex: setIndex + 1, accent: accent, mode: mode),
            SizedBox(width: t.space3),
            Expanded(child: _SetMeta(target: target, performed: performed)),
            SizedBox(width: t.space3),
            trailingBuilder != null
                ? trailingBuilder!(
                    context,
                    SetRowSlotData(
                      runner: runner,
                      target: target,
                      performed: performed,
                      exerciseIndex: exerciseIndex,
                      setIndex: setIndex,
                      state: _publicState(mode),
                    ),
                  )
                : _SetTrailing(mode: mode, runner: runner, target: target),
          ],
        ),
      ),
    );
  }

  SetRowState _publicState(_SetMode m) => switch (m) {
        _SetMode.pending => SetRowState.pending,
        _SetMode.running => SetRowState.running,
        _SetMode.done => SetRowState.done,
        _SetMode.locked => SetRowState.locked,
      };

  _SetMode _modeFor(WorkoutRunner runner) {
    if (performed != null) return _SetMode.done;
    if (runner.activeSetExerciseIndex == exerciseIndex &&
        runner.activeSetIndex == setIndex) {
      return _SetMode.running;
    }
    if (!runner.canActivateSet(exerciseIndex)) return _SetMode.locked;
    if (runner.activeSetExerciseIndex != null) return _SetMode.locked;
    return _SetMode.pending;
  }

  Future<void> _handleTap(
    BuildContext context,
    WorkoutRunner runner,
    _SetMode mode,
  ) async {
    switch (mode) {
      case _SetMode.pending:
        runner.startSet(exerciseIndex, setIndex);
        break;
      case _SetMode.running:
        await _finish(context, runner);
        break;
      case _SetMode.done:
        await _editDone(context, runner);
        break;
      case _SetMode.locked:
        break;
    }
  }

  Future<void> _finish(BuildContext context, WorkoutRunner runner) async {
    final result = await SetInputSheet.show(
      context: context,
      target: target,
      elapsed: runner.currentSetElapsed,
      setIndex: setIndex,
    );
    if (result == null) return;
    await runner.finishCurrentSet(
      reps: result.reps,
      weight: result.weight,
      rir: result.rir,
      rest: result.rest,
    );
  }

  Future<void> _editDone(BuildContext context, WorkoutRunner runner) async {
    final result = await SetInputSheet.show(
      context: context,
      target: target,
      elapsed: performed!.duration ?? Duration.zero,
      setIndex: setIndex,
      existing: performed,
    );
    if (result == null) return;
    await runner.updatePerformedSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      reps: result.reps,
      weight: result.weight,
      rir: result.rir,
    );
  }
}

class _SetBadge extends StatelessWidget {
  final int setIndex;
  final Color accent;
  final _SetMode mode;

  const _SetBadge({
    required this.setIndex,
    required this.accent,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDone = mode == _SetMode.done;
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : t.motionFast,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDone ? t.accent : Colors.transparent,
        borderRadius: t.radiusSmall,
        border: Border.all(
          color: isDone ? Colors.transparent : accent,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child:
          isDone
              ? Icon(Icons.check_rounded, color: t.onAccent, size: 20)
              : Text(
                '$setIndex',
                style: t.title.copyWith(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
    );
  }
}

class _SetMeta extends StatelessWidget {
  final WorkoutSet target;
  final PerformedSet? performed;

  const _SetMeta({required this.target, this.performed});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final p = performed;
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final typeLabel = _labelFor(target.type, l);
    final typeAccent =
        target.type == SetType.working ? null : t.accentFor(target.type);

    String targetLine;
    if (target.type == SetType.amrap && target.targetDuration != null) {
      targetLine = 'AMRAP — ${TimerText.format(target.targetDuration!)}';
    } else if (target.type == SetType.timed && target.targetDuration != null) {
      targetLine = 'Hold ${TimerText.format(target.targetDuration!)}';
    } else if (target.targetWeight != null) {
      targetLine =
          '${target.targetReps} × ${l.formatWeight(target.targetWeight!)} ${l.unitKg}';
    } else {
      targetLine = '${target.targetReps} ${l.repsLabel.toLowerCase()}';
    }

    final typePill = typeLabel == null
        ? null
        : Container(
            padding: EdgeInsets.symmetric(horizontal: t.space2, vertical: 2),
            margin: EdgeInsets.only(bottom: t.space1),
            decoration: BoxDecoration(
              color: (typeAccent ?? t.accent).withValues(alpha: 0.18),
              borderRadius: t.radiusPill,
            ),
            child: Text(
              typeLabel,
              style: t.caption.copyWith(
                color: typeAccent ?? t.accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          );

    if (p == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (typePill != null) typePill,
          Text(targetLine, style: t.body),
          if (target.rest != null && target.rest!.inSeconds > 0) ...[
            SizedBox(height: t.space1),
            Text(
              '${l.restLabel} ${TimerText.format(target.rest!)}',
              style: t.caption,
            ),
          ],
        ],
      );
    }

    final weight = p.actualWeight;
    final actualLine =
        weight != null
            ? '${p.actualReps} × ${_formatNum(weight)} kg'
            : '${p.actualReps} reps';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (typePill != null) typePill,
        Text(actualLine, style: t.body),
        SizedBox(height: t.space1),
        Wrap(
          spacing: t.space2,
          children: [
            Text('Target $targetLine', style: t.caption),
            if (p.rir != null)
              Text('RIR ${p.rir}', style: t.caption.copyWith(color: t.accent)),
            if (p.duration != null && p.duration!.inSeconds > 0)
              Text('Time ${TimerText.format(p.duration!)}', style: t.caption),
          ],
        ),
      ],
    );
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _SetTrailing extends StatelessWidget {
  final _SetMode mode;
  final WorkoutRunner runner;
  final WorkoutSet target;

  const _SetTrailing({
    required this.mode,
    required this.runner,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    switch (mode) {
      case _SetMode.pending:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: t.radiusSmall,
          ),
          child: Icon(Icons.play_arrow_rounded, color: t.onAccent, size: 24),
        );
      case _SetMode.running:
        final isTimed = target.isTimed && target.targetDuration != null;
        final shownDuration = isTimed
            ? runner.currentSetRemaining
            : runner.currentSetElapsed;
        final reachedTarget = isTimed &&
            runner.currentSetElapsed >= target.targetDuration!;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.space3,
            vertical: t.space1,
          ),
          decoration: BoxDecoration(
            color: (reachedTarget ? t.success : t.hot).withValues(alpha: 0.22),
            borderRadius: t.radiusPill,
          ),
          child: TimerText(
            duration: shownDuration,
            style: t.title.copyWith(
              fontSize: 14,
              color: reachedTarget ? t.success : t.hot,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      case _SetMode.done:
        return Icon(Icons.edit_rounded, color: t.textDim, size: 18);
      case _SetMode.locked:
        return Icon(Icons.lock_outline_rounded, color: t.textDim, size: 20);
    }
  }
}

/// Bottom-sheet entry/edit form for a single set. Use [show] to display it;
/// the result is a [SetInputResult] or `null` if the user cancelled.
class SetInputSheet extends StatefulWidget {
  final WorkoutSet target;
  final Duration elapsed;
  final int setIndex;
  final PerformedSet? existing;

  const SetInputSheet({
    super.key,
    required this.target,
    required this.elapsed,
    required this.setIndex,
    this.existing,
  });

  /// Convenience launcher.
  static Future<SetInputResult?> show({
    required BuildContext context,
    required WorkoutSet target,
    required Duration elapsed,
    required int setIndex,
    PerformedSet? existing,
  }) => showModalBottomSheet<SetInputResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => SetInputSheet(
          target: target,
          elapsed: elapsed,
          setIndex: setIndex,
          existing: existing,
        ),
  );

  @override
  State<SetInputSheet> createState() => _SetInputSheetState();
}

class _SetInputSheetState extends State<SetInputSheet> {
  late int _reps = widget.existing?.actualReps ?? widget.target.targetReps;
  late double _weight =
      widget.existing?.actualWeight ?? widget.target.targetWeight ?? 0;
  late int _rir = widget.existing?.rir ?? 2;
  late Duration _rest = widget.target.rest ?? const Duration(seconds: 90);

  bool get _isEdit => widget.existing != null;
  bool get _hasWeightTarget => widget.target.targetWeight != null;

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedPadding(
      duration: reduceMotion ? Duration.zero : t.motionFast,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.border)),
        ),
        padding: EdgeInsets.fromLTRB(
          t.space5,
          t.space4,
          t.space5,
          t.space5 + 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textDim.withValues(alpha: 0.6),
                  borderRadius: t.radiusPill,
                ),
              ),
            ),
            SizedBox(height: t.space4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit
                        ? 'Edit set ${widget.setIndex + 1}'
                        : 'Set ${widget.setIndex + 1}',
                    style: t.titleLarge,
                  ),
                ),
                if (widget.elapsed.inSeconds > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.space3,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: t.hotMuted,
                      borderRadius: t.radiusPill,
                    ),
                    child: TimerText(
                      duration: widget.elapsed,
                      style: t.title.copyWith(color: t.hot, fontSize: 14),
                    ),
                  ),
              ],
            ),
            SizedBox(height: t.space5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: HeroStepper(
                    label: 'Reps',
                    value: _reps,
                    integer: true,
                    min: 0,
                    max: 999,
                    smallStep: 1,
                    largeStep: 5,
                    onChanged: (v) => setState(() => _reps = v.toInt()),
                  ),
                ),
                SizedBox(width: t.space3),
                Expanded(
                  child: HeroStepper(
                    label: 'Weight',
                    unit: 'kg',
                    value: _weight,
                    min: 0,
                    max: 1000,
                    smallStep: _hasWeightTarget ? 2.5 : 1,
                    largeStep: 5,
                    onChanged: (v) => setState(() => _weight = v.toDouble()),
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space4),
            Row(
              children: [
                Text('Reps in reserve', style: t.caption),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: t.accentMuted,
                    borderRadius: t.radiusPill,
                  ),
                  child: Text(
                    '$_rir',
                    style: t.title.copyWith(color: t.accent, fontSize: 13),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: t.accent,
                inactiveTrackColor: t.surfaceElevated,
                thumbColor: t.accent,
                overlayColor: t.accentMuted,
                trackHeight: 4,
              ),
              child: Slider(
                value: _rir.toDouble(),
                onChanged: (v) => setState(() => _rir = v.round()),
                min: 0,
                max: 5,
                divisions: 5,
              ),
            ),
            if (!_isEdit) ...[
              SizedBox(height: t.space2),
              Text('Rest', style: t.caption),
              SizedBox(height: t.space2),
              Wrap(
                spacing: t.space2,
                children: [
                  for (final s in const [0, 30, 60, 90, 120, 180, 240])
                    _RestChip(
                      seconds: s,
                      selected: _rest.inSeconds == s,
                      onTap: () => setState(() => _rest = Duration(seconds: s)),
                    ),
                ],
              ),
            ],
            SizedBox(height: t.space5),
            RunnerPillButton(
              label: _isEdit ? 'Save changes' : 'Save set',
              icon: Icons.check_rounded,
              expand: true,
              onPressed:
                  () => Navigator.of(context).pop(
                    SetInputResult(
                      reps: _reps,
                      weight:
                          _weight == 0 && !_hasWeightTarget ? null : _weight,
                      rir: _rir,
                      rest: _rest,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Return type for [SetInputSheet].
class SetInputResult {
  final int reps;
  final double? weight;
  final int? rir;
  final Duration rest;

  const SetInputResult({
    required this.reps,
    this.weight,
    this.rir,
    required this.rest,
  });
}

class _RestChip extends StatelessWidget {
  final int seconds;
  final bool selected;
  final VoidCallback onTap;

  const _RestChip({
    required this.seconds,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final label =
        seconds == 0 ? 'None' : TimerText.format(Duration(seconds: seconds));
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : t.motionFast,
        padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: t.space2),
        decoration: BoxDecoration(
          color: selected ? t.accent : Colors.transparent,
          borderRadius: t.radiusPill,
          border: Border.all(color: selected ? Colors.transparent : t.border),
        ),
        child: Text(
          label,
          style: t.title.copyWith(
            fontSize: 13,
            color: selected ? t.onAccent : t.textPrimary,
          ),
        ),
      ),
    );
  }
}
