import 'package:flutter/material.dart';

import '../../intelligence/equipment_profile.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_pill_button.dart';

/// Modal bottom sheet that lets the user toggle the [EquipmentItem]s they
/// have access to. A quick-pick row at the top swaps the whole selection to
/// one of the bundled [EquipmentProfile] presets (bodyweight only, home gym,
/// commercial gym, cardio studio).
///
/// Use [EquipmentPickerSheet.show] to display the sheet. The returned future
/// resolves with the final selection when the user taps "Done", or `null`
/// when the sheet is dismissed.
class EquipmentPickerSheet extends StatefulWidget {
  /// Items that should appear toggled on when the sheet opens.
  final Set<EquipmentItem> initial;

  /// Fires with the final selection when the user taps "Done".
  final ValueChanged<Set<EquipmentItem>> onSave;

  const EquipmentPickerSheet({
    super.key,
    this.initial = const {},
    required this.onSave,
  });

  /// Opens the picker in a modal bottom sheet. Resolves with the saved
  /// selection or `null` when the user dismisses without saving.
  static Future<Set<EquipmentItem>?> show(
    BuildContext context, {
    Set<EquipmentItem> initial = const {},
  }) {
    return showModalBottomSheet<Set<EquipmentItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EquipmentPickerSheet(initial: initial, onSave: (_) {}),
    );
  }

  @override
  State<EquipmentPickerSheet> createState() => _EquipmentPickerSheetState();
}

class _EquipmentPickerSheetState extends State<EquipmentPickerSheet> {
  late Set<EquipmentItem> _selected = {...widget.initial};

  void _apply(Set<EquipmentItem> items) {
    setState(() {
      _selected = {...items};
    });
  }

  void _toggle(EquipmentItem item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  void _save() {
    widget.onSave(Set.unmodifiable(_selected));
    Navigator.of(context).pop(Set<EquipmentItem>.from(_selected));
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
        height: screenHeight * 0.78,
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
              Text('Available equipment', style: t.titleLarge),
              SizedBox(height: t.space2),
              Text(
                'Filters which exercises the plan generator can pick.',
                style: t.bodyMuted,
              ),
              SizedBox(height: t.space3),
              _QuickPickRow(onApply: _apply),
              SizedBox(height: t.space3),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: t.space2,
                    runSpacing: t.space2,
                    children: [
                      for (final item in EquipmentItem.values)
                        _EquipmentChip(
                          item: item,
                          selected: _selected.contains(item),
                          onTap: () => _toggle(item),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: t.space3),
              RunnerPillButton(
                label: 'Done',
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

class _QuickPickRow extends StatelessWidget {
  final ValueChanged<Set<EquipmentItem>> onApply;

  const _QuickPickRow({required this.onApply});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final presets = <_QuickPick>[
      _QuickPick('Bodyweight only', EquipmentProfile.bodyweightOnly().items),
      _QuickPick('Home gym', EquipmentProfile.homeGymBasic().items),
      _QuickPick('Commercial gym', EquipmentProfile.commercialGym().items),
      _QuickPick('Cardio studio', EquipmentProfile.cardioStudio().items),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => SizedBox(width: t.space2),
        itemBuilder: (ctx, i) {
          final p = presets[i];
          return _PresetPill(label: p.label, onTap: () => onApply(p.items));
        },
      ),
    );
  }
}

class _QuickPick {
  final String label;
  final Set<EquipmentItem> items;
  const _QuickPick(this.label, this.items);
}

class _PresetPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceElevated,
          borderRadius: t.radiusPill,
          border: Border.all(color: t.border),
        ),
        padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: t.space2),
        alignment: Alignment.center,
        child: Text(
          label,
          style: t.caption.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EquipmentChip extends StatelessWidget {
  final EquipmentItem item;
  final bool selected;
  final VoidCallback onTap;

  const _EquipmentChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : t.motionFast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? t.accent : Colors.transparent,
          borderRadius: t.radiusPill,
          border: Border.all(color: selected ? t.accent : t.border, width: 1),
        ),
        padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: t.space2),
        child: Text(
          _labelOf(item),
          style: t.body.copyWith(
            color: selected ? t.onAccent : t.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

String _labelOf(EquipmentItem item) {
  switch (item) {
    case EquipmentItem.barbell:
      return 'Barbell';
    case EquipmentItem.dumbbell:
      return 'Dumbbell';
    case EquipmentItem.kettlebell:
      return 'Kettlebell';
    case EquipmentItem.machine:
      return 'Machine';
    case EquipmentItem.cable:
      return 'Cable';
    case EquipmentItem.bodyweight:
      return 'Bodyweight';
    case EquipmentItem.bands:
      return 'Bands';
    case EquipmentItem.plates:
      return 'Plates';
    case EquipmentItem.bench:
      return 'Bench';
    case EquipmentItem.rack:
      return 'Rack';
    case EquipmentItem.pullupBar:
      return 'Pull-up bar';
    case EquipmentItem.treadmill:
      return 'Treadmill';
    case EquipmentItem.rower:
      return 'Rower';
    case EquipmentItem.stationaryBike:
      return 'Stationary bike';
    case EquipmentItem.jumpRope:
      return 'Jump rope';
    case EquipmentItem.medball:
      return 'Med ball';
  }
}
