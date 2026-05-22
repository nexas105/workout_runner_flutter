import 'package:flutter/material.dart';

import '../../l10n/workout_runner_localizations.dart';
import '../../models/exercise_category.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/runner_pill_button.dart';
import 'meta_field_row.dart';

/// Drop-in bottom sheet that creates or edits an [ExerciseCategory].
class CategoryEditorSheet extends StatefulWidget {
  /// Existing category being edited. `null` switches the sheet into
  /// "create" mode.
  final ExerciseCategory? existing;

  /// Called with the produced [ExerciseCategory] when the user taps Save.
  final ValueChanged<ExerciseCategory> onSave;

  const CategoryEditorSheet({
    super.key,
    required this.existing,
    required this.onSave,
  });

  /// Convenience that shows the editor in a modal bottom sheet. Returns the
  /// saved category on Save, `null` on Cancel/dismiss.
  static Future<ExerciseCategory?> show({
    required BuildContext context,
    ExerciseCategory? existing,
  }) {
    return showModalBottomSheet<ExerciseCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => CategoryEditorSheet(
            existing: existing,
            onSave: (c) => Navigator.of(ctx).pop(c),
          ),
    );
  }

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late String _name;
  late String _description;

  @override
  void initState() {
    super.initState();
    _name = widget.existing?.name ?? '';
    _description = widget.existing?.description ?? '';
  }

  String _slugify(String input) {
    final normalized = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'category' : normalized;
  }

  void _save() {
    if (_name.trim().isEmpty) return;
    final id = widget.existing?.id ?? _slugify(_name);
    final category = ExerciseCategory(
      id: id,
      name: _name.trim(),
      description: _description.trim().isEmpty ? null : _description.trim(),
    );
    widget.onSave(category);
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
              widget.existing == null ? 'New category' : 'Edit category',
              style: t.titleLarge,
            ),
            SizedBox(height: t.space3),
            MetaFieldRow.text(
              label: 'Name',
              value: _name,
              hint: 'Compound lifts',
              onChanged: (v) => setState(() => _name = v),
            ),
            MetaFieldRow.text(
              label: 'Description',
              value: _description,
              hint: 'Optional notes',
              maxLines: 2,
              onChanged: (v) => setState(() => _description = v),
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
