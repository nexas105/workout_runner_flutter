import 'package:flutter/material.dart';

import '../../l10n/workout_runner_localizations.dart';
import '../../models/exercise_category.dart';
import '../../models/exercise_metadata.dart';
import '../../models/muscle.dart';
import '../../models/workout_exercise.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/runner_pill_button.dart';
import 'catalog_picker_sheet.dart';
import 'meta_field_row.dart';

/// Drop-in bottom sheet that creates or edits a [WorkoutExercise].
///
/// Pass `existing: null` for create mode and a non-null [WorkoutExercise] to
/// edit an existing entity. The sheet emits the saved instance via [onSave]
/// before popping.
class ExerciseEditorSheet extends StatefulWidget {
  /// Existing exercise being edited. `null` switches the sheet into
  /// "create" mode and seeds defaults.
  final WorkoutExercise? existing;

  /// Catalogue of categories the user may pick from (single-select).
  final List<ExerciseCategory> categories;

  /// Catalogue of muscles the user may pick from (multi-select).
  final List<Muscle> muscles;

  /// Called with the produced [WorkoutExercise] when the user taps Save.
  final ValueChanged<WorkoutExercise> onSave;

  const ExerciseEditorSheet({
    super.key,
    required this.existing,
    required this.categories,
    required this.muscles,
    required this.onSave,
  });

  /// Convenience that shows the editor in a modal bottom sheet. Returns the
  /// saved exercise on Save, `null` on Cancel/dismiss.
  static Future<WorkoutExercise?> show({
    required BuildContext context,
    WorkoutExercise? existing,
    required List<ExerciseCategory> categories,
    required List<Muscle> muscles,
  }) {
    return showModalBottomSheet<WorkoutExercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExerciseEditorSheet(
        existing: existing,
        categories: categories,
        muscles: muscles,
        onSave: (ex) => Navigator.of(ctx).pop(ex),
      ),
    );
  }

  @override
  State<ExerciseEditorSheet> createState() => _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends State<ExerciseEditorSheet> {
  late String _name;
  late String _description;
  ExerciseCategory? _category;
  late List<Muscle> _muscles;
  late double _met;
  late String _notes;
  late bool _unilateral;
  late ExerciseEquipment _equipment;
  MovementPattern? _movementPattern;
  ExerciseDifficulty? _difficulty;
  late String _aliasesText;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _name = ex?.name ?? '';
    _description = ex?.description ?? '';
    _category = ex?.category;
    _muscles = List<Muscle>.from(ex?.muscles ?? const []);
    _met = ex?.met ?? 5.0;
    _notes = ex?.notes ?? '';
    _unilateral = ex?.unilateral ?? false;
    _equipment = ex?.equipment ?? ExerciseEquipment.bodyweight;
    _movementPattern = ex?.movementPattern;
    _difficulty = ex?.difficulty;
    _aliasesText = (ex?.aliases ?? const []).join(', ');
  }

  Future<void> _pickCategory() async {
    final picked = await CatalogPickerSheet.show<ExerciseCategory>(
      context,
      items: widget.categories,
      labelOf: (c) => c.name,
      subtitleOf: (c) => c.description ?? '',
      multiSelect: false,
      initialSelection: _category == null ? const [] : [_category!],
      title: 'Pick category',
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _category = picked.first);
    }
  }

  Future<void> _pickMuscles() async {
    final picked = await CatalogPickerSheet.show<Muscle>(
      context,
      items: widget.muscles,
      labelOf: (m) => m.name,
      subtitleOf: (m) => m.group ?? '',
      multiSelect: true,
      initialSelection: _muscles,
      title: 'Pick muscles',
    );
    if (picked != null) {
      setState(() => _muscles = picked);
    }
  }

  String _slugify(String input) {
    final normalized = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'exercise' : normalized;
  }

  List<String> _parseAliases(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  void _save() {
    if (_name.trim().isEmpty) return;
    final id = widget.existing?.id ?? _slugify(_name);
    final exercise = WorkoutExercise(
      id: id,
      name: _name.trim(),
      description: _description.trim().isEmpty ? null : _description.trim(),
      category: _category,
      muscles: List<Muscle>.from(_muscles),
      sets: widget.existing?.sets ?? const [],
      notes: _notes.trim().isEmpty ? null : _notes.trim(),
      meta: widget.existing?.meta,
      met: _met,
      equipment: _equipment,
      movementPattern: _movementPattern,
      difficulty: _difficulty,
      unilateral: _unilateral,
      aliases: _parseAliases(_aliasesText),
      searchTerms: widget.existing?.searchTerms ?? const [],
    );
    widget.onSave(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final canSave = _name.trim().isNotEmpty;

    return AnimatedPadding(
      duration: t.motionFast,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      curve: Curves.easeOut,
      child: SizedBox(
        height: screenHeight * 0.9,
        child: RunnerCard(
          padding: EdgeInsets.fromLTRB(
            t.space4,
            t.space3,
            t.space4,
            t.space4,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHandle(t: t),
              SizedBox(height: t.space3),
              Text(
                widget.existing == null ? 'New exercise' : 'Edit exercise',
                style: t.titleLarge,
              ),
              SizedBox(height: t.space3),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MetaFieldRow.text(
                        label: 'Name',
                        value: _name,
                        hint: 'Goblet Squat',
                        onChanged: (v) => setState(() => _name = v),
                      ),
                      MetaFieldRow.text(
                        label: 'Description',
                        value: _description,
                        hint: 'Short summary',
                        maxLines: 2,
                        onChanged: (v) => setState(() => _description = v),
                      ),
                      _PickerRow(
                        label: 'Category',
                        value: _category?.name ?? 'None',
                        onTap: _pickCategory,
                      ),
                      _PickerRow(
                        label: 'Muscles',
                        value: _muscles.isEmpty
                            ? 'None'
                            : _muscles.map((m) => m.name).join(', '),
                        onTap: _pickMuscles,
                      ),
                      MetaFieldRow.stepper(
                        label: 'MET',
                        value: _met,
                        min: 0,
                        max: 15,
                        smallStep: 0.5,
                        integer: false,
                        onChanged: (v) => setState(() => _met = v.toDouble()),
                      ),
                      MetaFieldRow.text(
                        label: 'Notes',
                        value: _notes,
                        hint: 'Cues, setup',
                        maxLines: 3,
                        onChanged: (v) => setState(() => _notes = v),
                      ),
                      MetaFieldRow.toggle(
                        label: 'Unilateral',
                        value: _unilateral,
                        onChanged: (v) => setState(() => _unilateral = v),
                      ),
                      MetaFieldRow.dropdown<ExerciseEquipment>(
                        label: 'Equipment',
                        value: _equipment,
                        items: [
                          for (final e in ExerciseEquipment.values)
                            DropdownMenuItem(value: e, child: Text(e.name)),
                        ],
                        onChanged: (v) =>
                            setState(() => _equipment = v ?? _equipment),
                      ),
                      MetaFieldRow.dropdown<MovementPattern?>(
                        label: 'Movement',
                        value: _movementPattern,
                        items: [
                          const DropdownMenuItem<MovementPattern?>(
                            value: null,
                            child: Text('—'),
                          ),
                          for (final m in MovementPattern.values)
                            DropdownMenuItem<MovementPattern?>(
                              value: m,
                              child: Text(m.name),
                            ),
                        ],
                        onChanged: (v) =>
                            setState(() => _movementPattern = v),
                      ),
                      MetaFieldRow.dropdown<ExerciseDifficulty?>(
                        label: 'Difficulty',
                        value: _difficulty,
                        items: [
                          const DropdownMenuItem<ExerciseDifficulty?>(
                            value: null,
                            child: Text('—'),
                          ),
                          for (final d in ExerciseDifficulty.values)
                            DropdownMenuItem<ExerciseDifficulty?>(
                              value: d,
                              child: Text(d.name),
                            ),
                        ],
                        onChanged: (v) => setState(() => _difficulty = v),
                      ),
                      MetaFieldRow.text(
                        label: 'Aliases',
                        value: _aliasesText,
                        hint: 'comma, separated, names',
                        onChanged: (v) => setState(() => _aliasesText = v),
                      ),
                    ],
                  ),
                ),
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
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  final WorkoutRunnerThemeData t;

  const _SheetHandle({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: t.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Row that mimics [MetaFieldRow] for tap-to-open pickers.
class _PickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.space2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: t.caption.copyWith(color: t.textMuted)),
          ),
          SizedBox(width: t.space3),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: t.surfaceElevated,
                  borderRadius: t.radiusMedium,
                  border: Border.all(color: t.border),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: t.space3,
                  vertical: t.space3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: t.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: t.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
