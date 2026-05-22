import 'package:flutter/material.dart';

import '../../l10n/workout_runner_localizations.dart';
import '../../models/muscle.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/runner_pill_button.dart';
import 'meta_field_row.dart';

/// Drop-in bottom sheet that creates or edits a [Muscle].
class MuscleEditorSheet extends StatefulWidget {
  /// Existing muscle being edited. `null` switches the sheet into "create"
  /// mode.
  final Muscle? existing;

  /// Called with the produced [Muscle] when the user taps Save.
  final ValueChanged<Muscle> onSave;

  const MuscleEditorSheet({
    super.key,
    required this.existing,
    required this.onSave,
  });

  /// Convenience that shows the editor in a modal bottom sheet. Returns the
  /// saved muscle on Save, `null` on Cancel/dismiss.
  static Future<Muscle?> show({
    required BuildContext context,
    Muscle? existing,
  }) {
    return showModalBottomSheet<Muscle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => MuscleEditorSheet(
            existing: existing,
            onSave: (m) => Navigator.of(ctx).pop(m),
          ),
    );
  }

  @override
  State<MuscleEditorSheet> createState() => _MuscleEditorSheetState();
}

class _MuscleEditorSheetState extends State<MuscleEditorSheet> {
  late String _name;
  late String _group;

  @override
  void initState() {
    super.initState();
    _name = widget.existing?.name ?? '';
    _group = widget.existing?.group ?? '';
  }

  String _slugify(String input) {
    final normalized = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'muscle' : normalized;
  }

  void _save() {
    if (_name.trim().isEmpty) return;
    final id = widget.existing?.id ?? _slugify(_name);
    final muscle = Muscle(
      id: id,
      name: _name.trim(),
      group: _group.trim().isEmpty ? null : _group.trim(),
    );
    widget.onSave(muscle);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final canSave = _name.trim().isNotEmpty;

    return AnimatedPadding(
      duration: t.motionFast,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      curve: Curves.easeOut,
      child: RunnerCard(
        padding: EdgeInsets.fromLTRB(t.space4, t.space3, t.space4, t.space4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: t.space3),
            Text(
              widget.existing == null ? 'New muscle' : 'Edit muscle',
              style: t.titleLarge,
            ),
            SizedBox(height: t.space3),
            MetaFieldRow.text(
              label: 'Name',
              value: _name,
              hint: 'Quadriceps',
              onChanged: (v) => setState(() => _name = v),
            ),
            MetaFieldRow.text(
              label: 'Group',
              value: _group,
              hint: 'Lower body',
              onChanged: (v) => setState(() => _group = v),
            ),
            SizedBox(height: t.space3),
            Row(
              children: [
                Expanded(
                  child: RunnerPillButton(
                    label: l.actionCancel,
                    style: RunnerButtonStyle.outline,
                    expand: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                SizedBox(width: t.space3),
                Expanded(
                  child: RunnerPillButton(
                    label: l.saveChanges,
                    style: RunnerButtonStyle.accent,
                    expand: true,
                    onPressed: canSave ? _save : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
