import 'package:flutter/material.dart';

import '../../intelligence/equipment_profile.dart';
import '../../intelligence/plan_generator.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/runner_pill_button.dart';
import 'equipment_picker_sheet.dart';
import 'experience_level_picker.dart';
import 'goal_picker_sheet.dart';

/// Composite onboarding sheet that walks the user through the four inputs of
/// a [PlanGenerationProfile] (goal, experience level, days-per-week,
/// equipment) and emits the final profile when the user taps "Save".
///
/// Internally composes [GoalPickerSheet], [ExperienceLevelPicker] and
/// [EquipmentPickerSheet] so they all stay independently usable.
class PlanGenerationProfileSheet extends StatefulWidget {
  /// Starting values. When `null` the form defaults to general fitness /
  /// intermediate / 3 days a week / no equipment.
  final PlanGenerationProfile? initial;

  /// Fires with the final profile when the user taps "Save".
  final ValueChanged<PlanGenerationProfile> onSave;

  const PlanGenerationProfileSheet({
    super.key,
    this.initial,
    required this.onSave,
  });

  /// Opens the sheet. Returns the saved [PlanGenerationProfile] or `null` if
  /// the user dismissed the sheet without saving.
  static Future<PlanGenerationProfile?> show(
    BuildContext context, {
    PlanGenerationProfile? initial,
  }) {
    return showModalBottomSheet<PlanGenerationProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => PlanGenerationProfileSheet(initial: initial, onSave: (_) {}),
    );
  }

  @override
  State<PlanGenerationProfileSheet> createState() =>
      _PlanGenerationProfileSheetState();
}

class _PlanGenerationProfileSheetState
    extends State<PlanGenerationProfileSheet> {
  static const int _minDays = 3;
  static const int _maxDays = 6;

  TrainingGoal? _goal;
  ExperienceLevel _level = ExperienceLevel.intermediate;
  int _daysPerWeek = 3;
  Set<EquipmentItem> _equipment = const {};

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _goal = init.goal;
      _level = init.level;
      _daysPerWeek = init.daysPerWeek;
      _equipment = _decodeEquipment(init.equipment);
    }
  }

  static Set<EquipmentItem> _decodeEquipment(Set<String> ids) {
    final out = <EquipmentItem>{};
    for (final id in ids) {
      for (final item in EquipmentItem.values) {
        if (item.id == id) {
          out.add(item);
          break;
        }
      }
    }
    return out;
  }

  Future<void> _pickGoal() async {
    final picked = await GoalPickerSheet.show(context, initial: _goal);
    if (picked != null && mounted) {
      setState(() => _goal = picked);
    }
  }

  Future<void> _pickEquipment() async {
    final picked = await EquipmentPickerSheet.show(
      context,
      initial: _equipment,
    );
    if (picked != null && mounted) {
      setState(() => _equipment = picked);
    }
  }

  void _changeDays(int delta) {
    final next = (_daysPerWeek + delta).clamp(_minDays, _maxDays);
    if (next == _daysPerWeek) return;
    setState(() => _daysPerWeek = next);
  }

  void _save() {
    final goal = _goal ?? TrainingGoal.general;
    final profile = PlanGenerationProfile(
      goal: goal,
      level: _level,
      daysPerWeek: _daysPerWeek,
      equipment: _equipment.map((e) => e.id).toSet(),
    );
    widget.onSave(profile);
    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AnimatedPadding(
      duration: reduceMotion ? Duration.zero : t.motionFast,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      curve: Curves.easeOut,
      child: SizedBox(
        height: screenHeight * 0.82,
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: t.border)),
          ),
          padding: EdgeInsets.fromLTRB(t.space4, t.space3, t.space4, t.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: EdgeInsets.only(bottom: t.space3),
                  decoration: BoxDecoration(
                    color: t.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Plan profile', style: t.titleLarge),
              SizedBox(height: t.space2),
              Text('Tell the plan generator who you are.', style: t.bodyMuted),
              SizedBox(height: t.space4),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(text: 'Goal'),
                      SizedBox(height: t.space2),
                      _GoalTile(goal: _goal, onTap: _pickGoal),
                      SizedBox(height: t.space4),
                      _SectionLabel(text: 'Experience level'),
                      SizedBox(height: t.space2),
                      ExperienceLevelPicker(
                        value: _level,
                        onChanged: (l) => setState(() => _level = l),
                      ),
                      SizedBox(height: t.space4),
                      _SectionLabel(text: 'Days per week'),
                      SizedBox(height: t.space2),
                      _DaysStepper(
                        value: _daysPerWeek,
                        min: _minDays,
                        max: _maxDays,
                        onChange: _changeDays,
                      ),
                      SizedBox(height: t.space4),
                      _SectionLabel(text: 'Equipment'),
                      SizedBox(height: t.space2),
                      _EquipmentSummary(
                        items: _equipment,
                        onTap: _pickEquipment,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: t.space3),
              RunnerPillButton(
                label: 'Save',
                style: RunnerButtonStyle.accent,
                expand: true,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Text(text.toUpperCase(), style: t.eyebrow);
  }
}

class _GoalTile extends StatelessWidget {
  final TrainingGoal? goal;
  final VoidCallback onTap;

  const _GoalTile({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final label = goal == null ? 'Pick a training goal' : _goalLabel(goal!);
    final hasValue = goal != null;
    return RunnerCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            hasValue ? Icons.flag_rounded : Icons.add_circle_outline_rounded,
            color: hasValue ? t.accent : t.textMuted,
          ),
          SizedBox(width: t.space3),
          Expanded(
            child: Text(
              label,
              style: hasValue ? t.title : t.bodyMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textMuted),
        ],
      ),
    );
  }
}

class _DaysStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChange;

  const _DaysStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final canDecrement = value > min;
    final canIncrement = value < max;
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          enabled: canDecrement,
          onTap: canDecrement ? () => onChange(-1) : null,
        ),
        Expanded(
          child: Center(
            child: Text(
              '$value',
              style: t.titleLarge.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          enabled: canIncrement,
          onTap: canIncrement ? () => onChange(1) : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: t.surfaceElevated,
            borderRadius: t.radiusPill,
            border: Border.all(color: t.border),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: t.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _EquipmentSummary extends StatelessWidget {
  final Set<EquipmentItem> items;
  final VoidCallback onTap;

  const _EquipmentSummary({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final summary =
        items.isEmpty
            ? 'Any equipment'
            : '${items.length} item${items.length == 1 ? '' : 's'} selected';
    return RunnerCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            items.isEmpty
                ? Icons.add_circle_outline_rounded
                : Icons.fitness_center_rounded,
            color: items.isEmpty ? t.textMuted : t.accent,
          ),
          SizedBox(width: t.space3),
          Expanded(
            child: Text(
              summary,
              style: items.isEmpty ? t.bodyMuted : t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textMuted),
        ],
      ),
    );
  }
}

String _goalLabel(TrainingGoal goal) {
  switch (goal) {
    case TrainingGoal.strength:
      return 'Strength';
    case TrainingGoal.hypertrophy:
      return 'Hypertrophy';
    case TrainingGoal.conditioning:
      return 'Conditioning';
    case TrainingGoal.general:
      return 'General fitness';
  }
}
