import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/workout_runner_theme.dart';

/// Hero-style numeric input. Big tap-target with `−` / `+` buttons and a
/// long-press to type a precise value. Built for set inputs (reps, weight) but
/// also used for cardio (distance, heart rate).
///
/// Generic over `num` so the consumer decides whether to round to int.
class HeroStepper extends StatelessWidget {
  final String label;
  final String? unit;
  final num value;
  final num min;
  final num max;
  final num smallStep;
  final num largeStep;
  final bool integer;
  final ValueChanged<num> onChanged;

  const HeroStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.unit,
    this.min = 0,
    this.max = 1000,
    this.smallStep = 1,
    this.largeStep = 5,
    this.integer = false,
  });

  num _clamp(num v) {
    if (v < min) return min;
    if (v > max) return max;
    return integer ? v.toInt() : v;
  }

  String _format(num v) {
    if (integer) return v.toInt().toString();
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);

    void haptic() => HapticFeedback.selectionClick();

    return GestureDetector(
      onLongPress: () => _promptManual(context),
      child: Container(
        padding: EdgeInsets.fromLTRB(t.space3, t.space3, t.space3, t.space3),
        decoration: BoxDecoration(
          color: t.surfaceElevated,
          borderRadius: t.radiusLarge,
          border: Border.all(color: t.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.caption),
            SizedBox(height: t.space2),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  semanticLabel:
                      'Decrease $label, current value ${_format(value)}',
                  onTap: () {
                    haptic();
                    onChanged(_clamp(value - smallStep));
                  },
                  onLongTap: () {
                    haptic();
                    onChanged(_clamp(value - largeStep));
                  },
                ),
                Expanded(
                  child: Center(
                    child: Semantics(
                      label: label,
                      value: '${_format(value)}${unit != null ? ' $unit' : ''}',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _format(value),
                            style: t.heroNumber.copyWith(fontSize: 40),
                          ),
                          if (unit != null) ...[
                            SizedBox(width: t.space2),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(unit!, style: t.bodyMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  semanticLabel:
                      'Increase $label, current value ${_format(value)}',
                  onTap: () {
                    haptic();
                    onChanged(_clamp(value + smallStep));
                  },
                  onLongTap: () {
                    haptic();
                    onChanged(_clamp(value + largeStep));
                  },
                ),
              ],
            ),
            SizedBox(height: t.space1),
            Center(
              child: Text(
                'tap & hold for ±$largeStep · long press to type',
                style: t.caption.copyWith(fontSize: 11, color: t.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptManual(BuildContext context) async {
    final t = WorkoutRunnerTheme.of(context);
    final controller = TextEditingController(text: _format(value));
    final raw = await showDialog<String>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: t.surface,
            shape: RoundedRectangleBorder(borderRadius: t.radiusLarge),
            insetPadding: EdgeInsets.symmetric(horizontal: t.space5),
            child: Padding(
              padding: EdgeInsets.all(t.space5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label, style: t.title),
                  SizedBox(height: t.space3),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: !integer,
                    ),
                    cursorColor: t.accent,
                    style: t.titleLarge.copyWith(fontSize: 32),
                    onSubmitted: (v) => Navigator.of(ctx).pop(v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: t.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: t.radiusMedium,
                        borderSide: BorderSide(color: t.border),
                      ),
                    ),
                  ),
                  SizedBox(height: t.space3),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Cancel',
                            style: t.title.copyWith(color: t.textMuted),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed:
                              () => Navigator.of(ctx).pop(controller.text),
                          child: Text(
                            'OK',
                            style: t.title.copyWith(color: t.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (raw == null) return;
    final cleaned = raw.replaceAll(',', '.').trim();
    final parsed =
        integer
            ? (int.tryParse(cleaned)?.toDouble())
            : double.tryParse(cleaned);
    if (parsed == null) return;
    onChanged(_clamp(integer ? parsed.toInt() : parsed));
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongTap;
  final String semanticLabel;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.onLongTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      onLongPress: onLongTap,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: t.radiusMedium,
            border: Border.all(color: t.border),
          ),
          child: Icon(icon, color: t.accent, size: 28),
        ),
      ),
    );
  }
}
