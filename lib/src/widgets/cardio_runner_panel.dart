import 'package:flutter/material.dart';

import '../controller/cardio_runner.dart';
import '../models/cardio/cardio_interval.dart';
import '../models/cardio/cardio_lap.dart';
import '../theme/workout_runner_theme.dart';
import 'cardio_runner_scope.dart';
import 'internals/runner_card.dart';
import 'internals/runner_pill_button.dart';
import 'internals/section_label.dart';
import 'internals/timer_text.dart';

/// Headline cardio view: hero timer + active-interval card + lap timeline +
/// control bar (complete / skip / pause-resume / finish).
class CardioRunnerPanel extends StatefulWidget {
  /// Called when the workout finishes (via the *Finish* button).
  final ValueChanged<bool>? onFinished;

  /// Header content shown above the timer block. `null` → hidden.
  final Widget? header;

  const CardioRunnerPanel({super.key, this.onFinished, this.header});

  @override
  State<CardioRunnerPanel> createState() => _CardioRunnerPanelState();
}

class _CardioRunnerPanelState extends State<CardioRunnerPanel> {
  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);

    if (runner.plan == null) {
      return _EmptyState();
    }

    return Container(
      color: t.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (widget.header != null) widget.header!,
            _Hero(),
            _IntervalCard(),
            Expanded(child: _LapTimeline()),
            _ControlBar(onFinished: widget.onFinished),
          ],
        ),
      ),
    );
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
          Icon(Icons.directions_run_rounded, size: 48, color: t.textDim),
          SizedBox(height: t.space3),
          Text('No active cardio session', style: t.titleLarge),
          SizedBox(height: t.space2),
          Text(
            'Start a cardio plan to see it here.',
            textAlign: TextAlign.center,
            style: t.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);
    final plan = runner.plan!;
    final remaining = runner.currentIntervalRemaining;
    final hasTarget =
        (runner.currentInterval?.targetDuration?.inSeconds ?? 0) > 0;
    final target = runner.currentInterval?.targetDuration?.inSeconds ?? 1;
    final progress =
        hasTarget
            ? (runner.currentIntervalElapsed.inSeconds / target).clamp(0.0, 1.0)
            : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space5, t.space5, t.space5, t.space3),
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
        padding: EdgeInsets.all(t.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(
              runner.isPaused ? 'Paused' : 'Cardio in progress',
              color: runner.isPaused ? t.hot : t.accent,
              trailing: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: runner.isPaused ? t.hot : t.accent,
                  shape: BoxShape.circle,
                  boxShadow: runner.isPaused ? null : t.shadowGlow,
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
                        '${runner.currentIntervalIndex + 1} / ${runner.intervals.length}',
                        style: t.title.copyWith(color: t.accent, fontSize: 18),
                      ),
                      Text('interval', style: t.caption),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space4),
            if (hasTarget) ...[
              ClipRRect(
                borderRadius: t.radiusPill,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: progress,
                  backgroundColor: t.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation(t.accent),
                ),
              ),
              SizedBox(height: t.space2),
              Row(
                children: [
                  Text(
                    TimerText.format(runner.currentIntervalElapsed),
                    style: t.caption,
                  ),
                  const Spacer(),
                  Text(
                    '-${TimerText.format(remaining)}',
                    style: t.caption.copyWith(color: t.accent),
                  ),
                ],
              ),
            ] else
              Text(
                'Open-ended interval · ${TimerText.format(runner.currentIntervalElapsed)} elapsed',
                style: t.caption,
              ),
          ],
        ),
      ),
    );
  }
}

class _IntervalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);
    final interval = runner.currentInterval;
    if (interval == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space2),
        child: RunnerCard(
          child: Text(
            'All intervals completed — finish the session to save your laps.',
            style: t.bodyMuted,
          ),
        ),
      );
    }

    final pace = interval.targetPacePerKm;
    final distance = interval.targetDistanceMeters;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space2),
      child: RunnerCard(
        borderColor: t.accent.withValues(alpha: 0.55),
        shadow: t.shadowGlow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PhasePill(phase: interval.phase),
                SizedBox(width: t.space2),
                if (interval.intensity != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.space2,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: t.surfaceElevated,
                      borderRadius: t.radiusPill,
                      border: Border.all(color: t.border),
                    ),
                    child: Text(
                      interval.intensity!,
                      style: t.eyebrow.copyWith(color: t.textPrimary),
                    ),
                  ),
                const Spacer(),
                if (runner.hasNextInterval)
                  Text(
                    'Next: ${runner.plan!.intervals[runner.currentIntervalIndex + 1].name}',
                    style: t.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            SizedBox(height: t.space3),
            Text(interval.name, style: t.titleLarge),
            if (interval.notes != null) ...[
              SizedBox(height: t.space2),
              Text(interval.notes!, style: t.bodyMuted),
            ],
            SizedBox(height: t.space3),
            Wrap(
              spacing: t.space2,
              runSpacing: t.space2,
              children: [
                if (interval.targetDuration != null)
                  _MetricChip(
                    icon: Icons.timer_outlined,
                    label: TimerText.format(interval.targetDuration!),
                  ),
                if (distance != null)
                  _MetricChip(
                    icon: Icons.straighten_rounded,
                    label: _formatDistance(distance),
                  ),
                if (pace != null)
                  _MetricChip(
                    icon: Icons.speed_rounded,
                    label: '${TimerText.format(pace)} / km',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return km == km.roundToDouble()
          ? '${km.toInt()} km'
          : '${km.toStringAsFixed(2)} km';
    }
    return '${meters.toInt()} m';
  }
}

class _PhasePill extends StatelessWidget {
  final CardioPhase phase;
  const _PhasePill({required this.phase});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final (label, color) = switch (phase) {
      CardioPhase.warmup => ('Warm-up', t.accent),
      CardioPhase.work => ('Work', t.hot),
      CardioPhase.rest => ('Rest', t.textMuted),
      CardioPhase.steady => ('Steady', t.accent),
      CardioPhase.cooldown => ('Cool-down', t.success),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space2, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: t.radiusPill,
      ),
      child: Text(label.toUpperCase(), style: t.eyebrow.copyWith(color: color)),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: 6),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: t.radiusPill,
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: t.textMuted),
          SizedBox(width: t.space2),
          Text(label, style: t.caption.copyWith(color: t.textPrimary)),
        ],
      ),
    );
  }
}

class _LapTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);
    final laps = runner.laps;
    if (laps.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space3),
        child: RunnerCard(
          color: t.surfaceElevated,
          padding: EdgeInsets.symmetric(
            horizontal: t.space4,
            vertical: t.space3,
          ),
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: t.textMuted, size: 18),
              SizedBox(width: t.space2),
              Expanded(
                child: Text(
                  'No laps yet — tap *Complete interval* below.',
                  style: t.bodyMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space5, vertical: t.space2),
      child: RunnerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionLabel('Laps  ·  ${laps.length}'),
            SizedBox(height: t.space3),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: laps.length,
                reverse: true,
                separatorBuilder:
                    (_, __) => Divider(color: t.border, height: t.space3),
                itemBuilder: (context, i) {
                  final lap = laps[i];
                  final intervalName =
                      lap.intervalIndex < runner.intervals.length
                          ? runner.plan!.intervals[lap.intervalIndex].name
                          : 'Interval ${lap.intervalIndex + 1}';
                  return _LapRow(lap: lap, name: intervalName);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LapRow extends StatelessWidget {
  final CardioLap lap;
  final String name;

  const _LapRow({required this.lap, required this.name});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: t.accentMuted,
            borderRadius: t.radiusSmall,
          ),
          alignment: Alignment.center,
          child: Text(
            '${lap.intervalIndex + 1}',
            style: t.title.copyWith(color: t.accent, fontSize: 14),
          ),
        ),
        SizedBox(width: t.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: t.body),
              SizedBox(height: 2),
              Wrap(
                spacing: t.space2,
                children: [
                  Text(TimerText.format(lap.duration), style: t.caption),
                  if (lap.distanceMeters != null)
                    Text(
                      '${(lap.distanceMeters! / 1000).toStringAsFixed(2)} km',
                      style: t.caption,
                    ),
                  if (lap.avgPacePerKm != null)
                    Text(
                      '${TimerText.format(lap.avgPacePerKm!)} / km',
                      style: t.caption,
                    ),
                  if (lap.avgHeartRate != null)
                    Text('${lap.avgHeartRate} bpm', style: t.caption),
                  if (lap.rpe != null)
                    Text(
                      'RPE ${lap.rpe}',
                      style: t.caption.copyWith(color: t.hot),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlBar extends StatelessWidget {
  final ValueChanged<bool>? onFinished;
  const _ControlBar({required this.onFinished});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final runner = CardioRunnerScope.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space5, t.space3, t.space5, t.space5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: RunnerPillButton(
                  label: runner.isPaused ? 'Resume' : 'Pause',
                  icon:
                      runner.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                  style: RunnerButtonStyle.outline,
                  expand: true,
                  onPressed: () async {
                    if (runner.isPaused) {
                      await runner.resume();
                    } else {
                      await runner.pause();
                    }
                  },
                ),
              ),
              SizedBox(width: t.space2),
              Expanded(
                child: RunnerPillButton(
                  label: 'Skip',
                  icon: Icons.skip_next_rounded,
                  style: RunnerButtonStyle.outline,
                  expand: true,
                  onPressed:
                      runner.currentInterval == null
                          ? null
                          : () => runner.skipInterval(),
                ),
              ),
            ],
          ),
          SizedBox(height: t.space2),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: RunnerPillButton(
                  label:
                      runner.hasNextInterval
                          ? 'Complete interval'
                          : 'Complete final',
                  icon: Icons.check_circle_outline_rounded,
                  style: RunnerButtonStyle.accent,
                  expand: true,
                  onPressed:
                      runner.currentInterval == null
                          ? null
                          : () => _promptComplete(context, runner),
                ),
              ),
              SizedBox(width: t.space2),
              Expanded(
                child: RunnerPillButton(
                  label: 'Finish',
                  icon: Icons.flag_circle_rounded,
                  style: RunnerButtonStyle.hot,
                  expand: true,
                  onPressed: () async {
                    final result = await runner.finish();
                    onFinished?.call(result != null);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _promptComplete(
    BuildContext context,
    CardioRunner runner,
  ) async {
    final input = await showModalBottomSheet<_LapInputResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LapInputSheet(runner: runner),
    );
    if (input == null) return;
    await runner.completeInterval(
      distanceMeters: input.distanceMeters,
      avgHeartRate: input.heartRate,
      rpe: input.rpe,
    );
  }
}

class _LapInputResult {
  final double? distanceMeters;
  final int? heartRate;
  final int? rpe;

  const _LapInputResult({this.distanceMeters, this.heartRate, this.rpe});
}

class _LapInputSheet extends StatefulWidget {
  final CardioRunner runner;
  const _LapInputSheet({required this.runner});

  @override
  State<_LapInputSheet> createState() => _LapInputSheetState();
}

class _LapInputSheetState extends State<_LapInputSheet> {
  late final TextEditingController _distance = TextEditingController(
    text:
        widget.runner.currentInterval?.targetDistanceMeters != null
            ? (widget.runner.currentInterval!.targetDistanceMeters! / 1000)
                .toString()
            : '',
  );
  late final TextEditingController _hr = TextEditingController();
  int _rpe = 5;

  @override
  void dispose() {
    _distance.dispose();
    _hr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final interval = widget.runner.currentInterval;

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
                  child: Text(interval?.name ?? 'Lap', style: t.titleLarge),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.space3,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: t.accentMuted,
                    borderRadius: t.radiusPill,
                  ),
                  child: TimerText(
                    duration: widget.runner.currentIntervalElapsed,
                    style: t.title.copyWith(color: t.accent, fontSize: 14),
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
                    controller: _distance,
                    label: 'Distance (km)',
                  ),
                ),
                SizedBox(width: t.space3),
                Expanded(
                  child: _NumberField(
                    controller: _hr,
                    label: 'Avg HR (bpm)',
                    isInteger: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space5),
            Text('RPE  ·  $_rpe', style: t.caption),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: t.hot,
                inactiveTrackColor: t.surfaceElevated,
                thumbColor: t.hot,
                overlayColor: t.hotMuted,
                trackHeight: 4,
              ),
              child: Slider(
                value: _rpe.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: '$_rpe',
                onChanged: (v) => setState(() => _rpe = v.round()),
              ),
            ),
            SizedBox(height: t.space4),
            RunnerPillButton(
              label: 'Save lap',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: () {
                final km = double.tryParse(_distance.text.replaceAll(',', '.'));
                final hr = int.tryParse(_hr.text);
                Navigator.of(context).pop(
                  _LapInputResult(
                    distanceMeters: km == null ? null : km * 1000,
                    heartRate: hr,
                    rpe: _rpe,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isInteger;

  const _NumberField({
    required this.controller,
    required this.label,
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
            keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
            cursorColor: t.accent,
            style: t.titleLarge.copyWith(fontSize: 24),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}
