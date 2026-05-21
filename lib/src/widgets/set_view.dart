import 'package:flutter/material.dart';

import '../controller/workout_runner.dart';
import '../models/performed_set.dart';
import '../models/workout_set.dart';
import '../theme/workout_runner_theme.dart';
import 'internals/runner_card.dart';
import 'internals/runner_pill_button.dart';
import 'internals/timer_text.dart';
import 'workout_runner_scope.dart';

/// State machine for a single set row.
enum _SetMode { pending, running, done, locked }

/// A single set row inside an exercise card. Handles start / running / done
/// visuals plus the bottom-sheet input flow for finishing a set.
class SetRow extends StatelessWidget {
  final int exerciseIndex;
  final int setIndex;
  final WorkoutSet target;
  final PerformedSet? performed;

  const SetRow({
    super.key,
    required this.exerciseIndex,
    required this.setIndex,
    required this.target,
    this.performed,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = WorkoutRunnerScope.of(context);
    final mode = _modeFor(runner);

    final accent = switch (mode) {
      _SetMode.running => t.hot,
      _SetMode.done => t.accent,
      _ => t.textDim,
    };

    return RunnerCard(
      padding: EdgeInsets.symmetric(horizontal: t.space4, vertical: t.space3),
      borderRadius: t.radiusMedium,
      color: t.surfaceElevated,
      borderColor:
          mode == _SetMode.running ? t.hot : t.border,
      shadow: mode == _SetMode.running
          ? [
              BoxShadow(
                color: t.hot.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: -4,
              ),
            ]
          : t.shadowCard,
      onTap: () => _handleTap(context, runner, mode),
      child: Row(
        children: [
          _SetBadge(setIndex: setIndex + 1, accent: accent, mode: mode),
          SizedBox(width: t.space3),
          Expanded(child: _SetMeta(target: target, performed: performed)),
          SizedBox(width: t.space3),
          _SetTrailing(mode: mode, runner: runner, target: target),
        ],
      ),
    );
  }

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
        await _promptFinish(context, runner);
        break;
      case _SetMode.done:
      case _SetMode.locked:
        break;
    }
  }

  Future<void> _promptFinish(
    BuildContext context,
    WorkoutRunner runner,
  ) async {
    final result = await showModalBottomSheet<_SetInputResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SetInputSheet(
        target: target,
        elapsed: runner.currentSetElapsed,
        setIndex: setIndex,
      ),
    );
    if (result == null) return;
    await runner.finishCurrentSet(
      reps: result.reps,
      weight: result.weight,
      rir: result.rir,
      rest: result.rest,
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
    final isDone = mode == _SetMode.done;
    return AnimatedContainer(
      duration: t.motionFast,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDone ? t.accent : Colors.transparent,
        borderRadius: t.radiusSmall,
        border: Border.all(color: isDone ? Colors.transparent : accent, width: 1.5),
      ),
      alignment: Alignment.center,
      child: isDone
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

    String repsLine = '${target.targetReps} reps';
    if (target.targetWeight != null) {
      repsLine = '${target.targetReps} × ${_formatNum(target.targetWeight!)} kg';
    }

    if (p == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(repsLine, style: t.body),
          if (target.rest != null && target.rest!.inSeconds > 0) ...[
            SizedBox(height: t.space1),
            Text(
              'Rest ${TimerText.format(target.rest!)}',
              style: t.caption,
            ),
          ],
        ],
      );
    }

    final weight = p.actualWeight;
    final actualLine = weight != null
        ? '${p.actualReps} × ${_formatNum(weight)} kg'
        : '${p.actualReps} reps';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(actualLine, style: t.body),
        SizedBox(height: t.space1),
        Wrap(
          spacing: t.space2,
          children: [
            Text('Target $repsLine', style: t.caption),
            if (p.rir != null)
              Text('RIR ${p.rir}', style: t.caption.copyWith(color: t.accent)),
            if (p.duration != null && p.duration!.inSeconds > 0)
              Text(
                'Time ${TimerText.format(p.duration!)}',
                style: t.caption,
              ),
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
        return Icon(Icons.play_arrow_rounded, color: t.accent, size: 28);
      case _SetMode.running:
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.space3,
            vertical: t.space1,
          ),
          decoration: BoxDecoration(
            color: t.hot.withValues(alpha: 0.18),
            borderRadius: t.radiusPill,
          ),
          child: TimerText(
            duration: runner.currentSetElapsed,
            style: t.title.copyWith(
              fontSize: 14,
              color: t.hot,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      case _SetMode.done:
        return Icon(Icons.check_circle_rounded, color: t.accent, size: 24);
      case _SetMode.locked:
        return Icon(Icons.lock_outline_rounded, color: t.textDim, size: 20);
    }
  }
}

class _SetInputResult {
  final int reps;
  final double? weight;
  final int? rir;
  final Duration rest;

  const _SetInputResult({
    required this.reps,
    this.weight,
    this.rir,
    required this.rest,
  });
}

class _SetInputSheet extends StatefulWidget {
  final WorkoutSet target;
  final Duration elapsed;
  final int setIndex;

  const _SetInputSheet({
    required this.target,
    required this.elapsed,
    required this.setIndex,
  });

  @override
  State<_SetInputSheet> createState() => _SetInputSheetState();
}

class _SetInputSheetState extends State<_SetInputSheet> {
  late int _reps = widget.target.targetReps;
  late double _weight = widget.target.targetWeight ?? 0;
  int _rir = 2;
  late Duration _rest =
      widget.target.rest ?? const Duration(seconds: 90);

  late final TextEditingController _repsCtrl =
      TextEditingController(text: _reps.toString());
  late final TextEditingController _weightCtrl =
      TextEditingController(text: _formatNum(_weight));

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  String _formatNum(double v) {
    if (v == 0) return '';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return AnimatedPadding(
      duration: t.motionFast,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: t.border),
          ),
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
                    'Set ${widget.setIndex + 1}',
                    style: t.titleLarge,
                  ),
                ),
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
                  child: _NumberField(
                    label: 'Reps',
                    controller: _repsCtrl,
                    onChanged: (v) =>
                        _reps = int.tryParse(v) ?? widget.target.targetReps,
                    isInteger: true,
                  ),
                ),
                SizedBox(width: t.space3),
                Expanded(
                  child: _NumberField(
                    label: 'Weight (kg)',
                    controller: _weightCtrl,
                    onChanged: (v) =>
                        _weight = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space5),
            Text('Reps in reserve  ·  $_rir', style: t.caption),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: t.accent,
                inactiveTrackColor: t.surfaceElevated,
                thumbColor: t.accent,
                overlayColor: t.accentMuted,
                valueIndicatorColor: t.accent,
                trackHeight: 4,
              ),
              child: Slider(
                value: _rir.toDouble(),
                onChanged: (v) => setState(() => _rir = v.round()),
                min: 0,
                max: 5,
                divisions: 5,
                label: '$_rir',
              ),
            ),
            SizedBox(height: t.space3),
            Text('Rest', style: t.caption),
            SizedBox(height: t.space2),
            Wrap(
              spacing: t.space2,
              children: [
                for (final s in const [0, 30, 60, 90, 120, 180, 240])
                  _RestChip(
                    seconds: s,
                    selected: _rest.inSeconds == s,
                    onTap: () =>
                        setState(() => _rest = Duration(seconds: s)),
                  ),
              ],
            ),
            SizedBox(height: t.space5),
            RunnerPillButton(
              label: 'Save set',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: () => Navigator.of(context).pop(
                _SetInputResult(
                  reps: _reps,
                  weight: _weight == 0 ? null : _weight,
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

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isInteger;

  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.caption),
        SizedBox(height: t.space2),
        Container(
          decoration: BoxDecoration(
            color: t.surfaceElevated,
            borderRadius: t.radiusMedium,
            border: Border.all(color: t.border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: t.space3,
            vertical: t.space2,
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(
              decimal: !isInteger,
              signed: false,
            ),
            cursorColor: t.accent,
            style: t.titleLarge.copyWith(fontSize: 28),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
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
    final label =
        seconds == 0 ? 'None' : TimerText.format(Duration(seconds: seconds));
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: t.motionFast,
        padding: EdgeInsets.symmetric(
          horizontal: t.space3,
          vertical: t.space2,
        ),
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
