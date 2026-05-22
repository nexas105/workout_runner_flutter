import 'package:flutter/material.dart';

import '../../l10n/workout_runner_localizations.dart';
import '../../models/exercise_category.dart';
import '../../models/muscle.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_plan.dart';
import '../../models/workout_plan_validation.dart';
import '../../models/workout_set.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/runner_pill_button.dart';
import '../internals/section_label.dart';
import 'meta_field_row.dart';

/// Drop-in full-screen editor for a [WorkoutPlan]. Maintains a mutable working
/// copy of the plan and emits the final value via [onSave] when the user taps
/// the save action.
///
/// Pass `existing: null` to start with a blank plan. The supplied
/// [categories] and [muscles] are forwarded to the per-exercise editor so the
/// user can attach metadata without leaving the screen.
///
/// The screen surfaces [WorkoutPlanValidation] inline: a coloured badge shows
/// whether the plan is valid, has warnings or errors, and the topmost error
/// message renders as a subtitle. Save is disabled while errors are present.
class PlanEditorScreen extends StatefulWidget {
  /// Plan to seed the editor with. When `null` the editor starts with a blank
  /// plan (empty name, no exercises).
  final WorkoutPlan? existing;

  /// Categories offered by the exercise editor sheet.
  final List<ExerciseCategory> categories;

  /// Muscles offered by the exercise editor sheet (multi-select).
  final List<Muscle> muscles;

  /// Fired with the edited plan when the user taps the save action. The
  /// callback receives a freshly constructed [WorkoutPlan] — the original
  /// `existing` instance is never mutated.
  final ValueChanged<WorkoutPlan> onSave;

  /// Optional cancel hook. When `null` the cancel button is hidden.
  final VoidCallback? onCancel;

  const PlanEditorScreen({
    super.key,
    this.existing,
    this.categories = const [],
    this.muscles = const [],
    required this.onSave,
    this.onCancel,
  });

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  late WorkoutPlan _plan;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _plan =
        widget.existing ?? const WorkoutPlan(id: '', name: '', exercises: []);
    _nameController = TextEditingController(text: _plan.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(WorkoutPlan next) => setState(() => _plan = next);

  void _setName(String value) {
    setState(() {
      _plan = _plan.copyWith(name: value);
    });
  }

  void _setDescription(String value) {
    setState(() {
      _plan = _plan.copyWith(description: value.isEmpty ? null : value);
    });
  }

  void _reorderExercise(int oldIndex, int newIndex) {
    setState(() {
      final list = List<WorkoutExercise>.from(_plan.exercises);
      var to = newIndex;
      if (to > oldIndex) to -= 1;
      final moved = list.removeAt(oldIndex);
      list.insert(to, moved);
      _plan = _plan.copyWith(exercises: list);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      final list = List<WorkoutExercise>.from(_plan.exercises)..removeAt(index);
      _plan = _plan.copyWith(exercises: list);
    });
  }

  void _duplicateExercise(int index) {
    setState(() {
      final list = List<WorkoutExercise>.from(_plan.exercises);
      final source = list[index];
      final copy = source.cloneWithId(_uniqueExerciseId('${source.id}-copy'));
      list.insert(index + 1, copy);
      _plan = _plan.copyWith(exercises: list);
    });
  }

  String _uniqueExerciseId(String base) {
    final existing = _plan.exercises.map((e) => e.id).toSet();
    if (!existing.contains(base)) return base;
    var i = 2;
    while (existing.contains('$base-$i')) {
      i++;
    }
    return '$base-$i';
  }

  Future<void> _editExercise(int index) async {
    final updated = await _openExerciseEditor(_plan.exercises[index]);
    if (updated == null) return;
    setState(() {
      final list = List<WorkoutExercise>.from(_plan.exercises);
      list[index] = updated;
      _plan = _plan.copyWith(exercises: list);
    });
  }

  Future<void> _addExercise() async {
    final created = await _openExerciseEditor(null);
    if (created == null) return;
    setState(() {
      final list = List<WorkoutExercise>.from(_plan.exercises);
      // Ensure the new id doesn't clash with existing exercises.
      var ex = created;
      if (list.any((e) => e.id == ex.id)) {
        ex = ex.cloneWithId(_uniqueExerciseId(ex.id));
      }
      list.add(ex);
      _plan = _plan.copyWith(exercises: list);
    });
  }

  Future<WorkoutExercise?> _openExerciseEditor(
    WorkoutExercise? existing,
  ) async {
    return showModalBottomSheet<WorkoutExercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _InlineExerciseEditor(
            existing: existing,
            categories: widget.categories,
            muscles: widget.muscles,
          ),
    );
  }

  void _save() {
    var plan = _plan;
    // Generate an id from the name if one is missing — keeps round-tripping
    // through Save → re-edit predictable.
    if (plan.id.trim().isEmpty) {
      final slug = _slug(plan.name);
      plan = plan.copyWith(id: slug);
    }
    widget.onSave(plan);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final validation = _plan.validate();
    final canSave = validation.isValid && _plan.name.trim().isNotEmpty;

    // Keep the name controller in sync if the underlying value diverges (e.g.
    // a reset would re-seed _plan).
    if (_nameController.text != _plan.name) {
      _nameController.value = _nameController.value.copyWith(
        text: _plan.name,
        selection: TextSelection.collapsed(offset: _plan.name.length),
        composing: TextRange.empty,
      );
    }

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.space3),
          child: TextField(
            key: const Key('plan_editor_name_field'),
            controller: _nameController,
            onChanged: _setName,
            cursorColor: t.accent,
            style: t.titleLarge.copyWith(fontSize: 20),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: 'Plan name',
              hintStyle: t.titleLarge.copyWith(fontSize: 20, color: t.textDim),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.space3,
              vertical: t.space2,
            ),
            child: RunnerPillButton(
              key: const Key('plan_editor_save_button'),
              label: l.saveChanges,
              icon: Icons.check_rounded,
              onPressed: canSave ? _save : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(t.space4, t.space2, t.space4, t.space7),
          children: [
            _SummaryHeader(plan: _plan),
            SizedBox(height: t.space3),
            RunnerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('Plan'),
                  SizedBox(height: t.space2),
                  MetaFieldRow.text(
                    label: 'Name',
                    value: _plan.name,
                    hint: 'My new plan',
                    onChanged: _setName,
                  ),
                  MetaFieldRow.text(
                    label: 'Description',
                    value: _plan.description ?? '',
                    hint: 'Optional notes about this plan',
                    maxLines: 2,
                    onChanged: _setDescription,
                  ),
                ],
              ),
            ),
            SizedBox(height: t.space3),
            _ValidationBadge(result: validation),
            SizedBox(height: t.space3),
            SectionLabel('Exercises (${_plan.exercises.length})'),
            SizedBox(height: t.space2),
            _ExerciseList(
              exercises: _plan.exercises,
              onReorder: _reorderExercise,
              onTapEdit: _editExercise,
              onDuplicate: _duplicateExercise,
              onRemove: _removeExercise,
              onSetsChanged: (index, sets) {
                final list = List<WorkoutExercise>.from(_plan.exercises);
                list[index] = list[index].copyWith(sets: sets);
                _update(_plan.copyWith(exercises: list));
              },
            ),
            SizedBox(height: t.space3),
            RunnerPillButton(
              key: const Key('plan_editor_add_exercise_button'),
              label: 'Add exercise',
              icon: Icons.add_rounded,
              style: RunnerButtonStyle.filled,
              expand: true,
              onPressed: _addExercise,
            ),
            SizedBox(height: t.space4),
            if (widget.onCancel != null)
              Align(
                alignment: Alignment.centerLeft,
                child: RunnerPillButton(
                  key: const Key('plan_editor_cancel_button'),
                  label: l.actionCancel,
                  style: RunnerButtonStyle.ghost,
                  onPressed: widget.onCancel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final WorkoutPlan plan;
  const _SummaryHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space1),
      child: Text(
        plan.exercises.isEmpty ? 'Empty plan' : plan.previewSummary,
        style: t.bodyMuted,
      ),
    );
  }
}

class _ValidationBadge extends StatelessWidget {
  final WorkoutPlanValidationResult result;
  const _ValidationBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final hasErrors = result.errors.isNotEmpty;
    final hasWarnings = result.warnings.isNotEmpty;

    final Color color;
    final String label;
    final IconData icon;
    if (hasErrors) {
      color = t.danger;
      label = 'Errors';
      icon = Icons.error_outline_rounded;
    } else if (hasWarnings) {
      color = t.hot;
      label = 'Warnings';
      icon = Icons.warning_amber_rounded;
    } else {
      color = t.success;
      label = 'Valid';
      icon = Icons.check_circle_outline_rounded;
    }

    final messages =
        hasErrors
            ? result.errors
            : hasWarnings
            ? result.warnings
            : const [];
    final topMessage = messages.isEmpty ? null : messages.first.message;

    return RunnerCard(
      key: const Key('plan_editor_validation_badge'),
      borderColor: color.withValues(alpha: 0.4),
      padding: EdgeInsets.symmetric(horizontal: t.space4, vertical: t.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: t.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: t.title.copyWith(color: color, fontSize: 14),
                ),
                if (topMessage != null) ...[
                  SizedBox(height: t.space1),
                  Text(topMessage, style: t.bodyMuted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onTapEdit;
  final ValueChanged<int> onDuplicate;
  final ValueChanged<int> onRemove;
  final void Function(int index, List<WorkoutSet> sets) onSetsChanged;

  const _ExerciseList({
    required this.exercises,
    required this.onReorder,
    required this.onTapEdit,
    required this.onDuplicate,
    required this.onRemove,
    required this.onSetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    if (exercises.isEmpty) {
      return RunnerCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.space3),
          child: Center(
            child: Text(
              'No exercises yet. Tap "Add exercise" below.',
              style: t.bodyMuted,
            ),
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      key: const Key('plan_editor_exercise_list'),
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      onReorder: onReorder,
      itemBuilder: (ctx, index) {
        final ex = exercises[index];
        return Padding(
          key: ValueKey('plan_editor_exercise_${ex.id}_$index'),
          padding: EdgeInsets.only(bottom: t.space2),
          child: _ExerciseRow(
            index: index,
            exercise: ex,
            onTap: () => onTapEdit(index),
            onDuplicate: () => onDuplicate(index),
            onRemove: () => onRemove(index),
            onSetsChanged: (sets) => onSetsChanged(index, sets),
          ),
        );
      },
    );
  }
}

class _ExerciseRow extends StatefulWidget {
  final int index;
  final WorkoutExercise exercise;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final ValueChanged<List<WorkoutSet>> onSetsChanged;

  const _ExerciseRow({
    required this.index,
    required this.exercise,
    required this.onTap,
    required this.onDuplicate,
    required this.onRemove,
    required this.onSetsChanged,
  });

  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  bool _expanded = false;

  String _summary(BuildContext context) {
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final sets = widget.exercise.sets;
    if (sets.isEmpty) return 'No sets';
    final first = sets.first;
    final sameReps = sets.every((s) => s.targetReps == first.targetReps);
    final sameWeight = sets.every((s) => s.targetWeight == first.targetWeight);
    if (sameReps && sameWeight) {
      final reps = first.targetReps;
      final weight = first.targetWeight;
      if (weight == null) {
        return '${sets.length} × $reps';
      }
      return '${sets.length} × $reps @ ${l.formatWeight(weight)} ${l.unitKg}';
    }
    return '${sets.length} sets';
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerCard(
      padding: EdgeInsets.fromLTRB(t.space2, t.space3, t.space2, t.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: t.space2),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: t.textMuted,
                    size: 22,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.name.isEmpty
                            ? 'Untitled exercise'
                            : widget.exercise.name,
                        style: t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: t.space1),
                      Text(_summary(context), style: t.bodyMuted),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: Key('plan_editor_expand_sets_${widget.index}'),
                icon: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: t.textMuted,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                tooltip: _expanded ? 'Collapse sets' : 'Expand sets',
              ),
              _RowKebab(
                index: widget.index,
                onEdit: widget.onTap,
                onDuplicate: widget.onDuplicate,
                onRemove: widget.onRemove,
              ),
            ],
          ),
          if (_expanded) ...[
            SizedBox(height: t.space2),
            _SetsEditor(
              sets: widget.exercise.sets,
              onChanged: widget.onSetsChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _RowKebab extends StatelessWidget {
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;

  const _RowKebab({
    required this.index,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return PopupMenuButton<_RowAction>(
      key: Key('plan_editor_row_kebab_$index'),
      icon: Icon(Icons.more_vert_rounded, color: t.textMuted),
      color: t.surfaceElevated,
      onSelected: (action) {
        switch (action) {
          case _RowAction.edit:
            onEdit();
          case _RowAction.duplicate:
            onDuplicate();
          case _RowAction.remove:
            onRemove();
        }
      },
      itemBuilder:
          (ctx) => [
            PopupMenuItem(
              value: _RowAction.edit,
              child: Text('Edit', style: t.body),
            ),
            PopupMenuItem(
              value: _RowAction.duplicate,
              child: Text('Duplicate', style: t.body),
            ),
            PopupMenuItem(
              value: _RowAction.remove,
              child: Text('Remove', style: t.body.copyWith(color: t.danger)),
            ),
          ],
    );
  }
}

enum _RowAction { edit, duplicate, remove }

/// Inline per-exercise set editor. Each set is a small card with stepper rows
/// for reps / weight / rest.
class _SetsEditor extends StatelessWidget {
  final List<WorkoutSet> sets;
  final ValueChanged<List<WorkoutSet>> onChanged;

  const _SetsEditor({required this.sets, required this.onChanged});

  void _addSet() {
    final template = sets.isEmpty ? const WorkoutSet(targetReps: 8) : sets.last;
    onChanged([...sets, template.copyWith()]);
  }

  void _removeSet(int index) {
    final next = List<WorkoutSet>.from(sets)..removeAt(index);
    onChanged(next);
  }

  void _replaceSet(int index, WorkoutSet next) {
    final list = List<WorkoutSet>.from(sets);
    list[index] = next;
    onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sets.length; i++) ...[
            _SetEditorRow(
              index: i,
              set: sets[i],
              onChanged: (next) => _replaceSet(i, next),
              onRemove: () => _removeSet(i),
            ),
            SizedBox(height: t.space2),
          ],
          RunnerPillButton(
            key: const Key('plan_editor_add_set_button'),
            label: 'Add set',
            icon: Icons.add_rounded,
            style: RunnerButtonStyle.outline,
            expand: true,
            onPressed: _addSet,
          ),
        ],
      ),
    );
  }
}

class _SetEditorRow extends StatelessWidget {
  final int index;
  final WorkoutSet set;
  final ValueChanged<WorkoutSet> onChanged;
  final VoidCallback onRemove;

  const _SetEditorRow({
    required this.index,
    required this.set,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    return RunnerCard(
      elevated: true,
      padding: EdgeInsets.fromLTRB(t.space3, t.space3, t.space2, t.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.setIndexLabel(index + 1), style: t.caption),
              ),
              IconButton(
                key: Key('plan_editor_remove_set_${index}_button'),
                onPressed: onRemove,
                icon: Icon(Icons.close_rounded, color: t.textMuted, size: 18),
                tooltip: 'Remove set',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: t.space2),
          MetaFieldRow.stepper(
            label: l.repsLabel,
            value: set.targetReps,
            min: 1,
            max: 99,
            integer: true,
            onChanged: (v) => onChanged(set.copyWith(targetReps: v.toInt())),
          ),
          MetaFieldRow.stepper(
            label: l.weightLabel,
            value: set.targetWeight ?? 0,
            min: 0,
            max: 500,
            smallStep: 2.5,
            integer: false,
            unit: l.unitKg,
            onChanged: (v) {
              final weight = v.toDouble();
              onChanged(
                set.copyWith(targetWeight: weight == 0 ? null : weight),
              );
            },
          ),
          MetaFieldRow.stepper(
            label: l.restLabel,
            value: set.rest?.inSeconds ?? 0,
            min: 0,
            max: 600,
            smallStep: 5,
            integer: true,
            unit: 's',
            onChanged: (v) {
              final secs = v.toInt();
              onChanged(
                set.copyWith(rest: secs == 0 ? null : Duration(seconds: secs)),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Lightweight inline editor surfaced when no separate `ExerciseEditorSheet`
/// implementation is wired up yet. Lets the user create or edit an exercise
/// with a name, category and muscle multi-select.
class _InlineExerciseEditor extends StatefulWidget {
  final WorkoutExercise? existing;
  final List<ExerciseCategory> categories;
  final List<Muscle> muscles;

  const _InlineExerciseEditor({
    required this.existing,
    required this.categories,
    required this.muscles,
  });

  @override
  State<_InlineExerciseEditor> createState() => _InlineExerciseEditorState();
}

class _InlineExerciseEditorState extends State<_InlineExerciseEditor> {
  late String _name;
  late String? _description;
  late ExerciseCategory? _category;
  late List<Muscle> _muscles;
  late List<WorkoutSet> _sets;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _name = ex?.name ?? '';
    _description = ex?.description;
    _category = ex?.category;
    _muscles = List<Muscle>.from(ex?.muscles ?? const <Muscle>[]);
    _sets = List<WorkoutSet>.from(
      ex?.sets ?? const <WorkoutSet>[WorkoutSet(targetReps: 8)],
    );
  }

  void _save() {
    final base = widget.existing;
    final id = base?.id ?? _slug(_name.isEmpty ? 'exercise' : _name);
    final exercise = (base ?? WorkoutExercise(id: id, name: _name)).copyWith(
      id: id,
      name: _name,
      description: _description,
      category: _category,
      muscles: List<Muscle>.unmodifiable(_muscles),
      sets: List<WorkoutSet>.unmodifiable(_sets),
    );
    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.vertical(top: t.radiusLarge.topLeft),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(t.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existing == null ? 'New exercise' : 'Edit exercise',
                  style: t.titleLarge,
                ),
                SizedBox(height: t.space3),
                MetaFieldRow.text(
                  label: 'Name',
                  value: _name,
                  hint: 'e.g. Goblet squat',
                  onChanged: (v) => setState(() => _name = v),
                ),
                MetaFieldRow.text(
                  label: 'Description',
                  value: _description ?? '',
                  hint: 'Optional cue',
                  maxLines: 2,
                  onChanged:
                      (v) =>
                          setState(() => _description = v.isEmpty ? null : v),
                ),
                if (widget.categories.isNotEmpty)
                  MetaFieldRow.dropdown<ExerciseCategory?>(
                    label: 'Category',
                    value: _category,
                    items: [
                      const DropdownMenuItem<ExerciseCategory?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...widget.categories.map(
                        (c) => DropdownMenuItem<ExerciseCategory?>(
                          value: c,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                if (widget.muscles.isNotEmpty) ...[
                  SizedBox(height: t.space2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Muscles', style: t.caption),
                  ),
                  SizedBox(height: t.space2),
                  Wrap(
                    spacing: t.space2,
                    runSpacing: t.space2,
                    children: [
                      for (final m in widget.muscles)
                        FilterChip(
                          label: Text(m.name),
                          selected: _muscles.contains(m),
                          onSelected:
                              (sel) => setState(() {
                                if (sel) {
                                  _muscles.add(m);
                                } else {
                                  _muscles.remove(m);
                                }
                              }),
                        ),
                    ],
                  ),
                ],
                SizedBox(height: t.space4),
                Row(
                  children: [
                    Expanded(
                      child: RunnerPillButton(
                        label: l.actionCancel,
                        style: RunnerButtonStyle.ghost,
                        expand: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(width: t.space3),
                    Expanded(
                      child: RunnerPillButton(
                        key: const Key('plan_editor_inline_save_button'),
                        label: widget.existing == null ? 'Add' : l.saveChanges,
                        icon: Icons.check_rounded,
                        expand: true,
                        onPressed: _name.trim().isEmpty ? null : _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _slug(String input) {
  final normalized = input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'exercise' : normalized;
}
