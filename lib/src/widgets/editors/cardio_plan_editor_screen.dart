import 'package:flutter/material.dart';

import '../../models/cardio/cardio_interval.dart';
import '../../models/cardio/cardio_plan.dart';
import '../../models/cardio/cardio_plan_builder.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/runner_pill_button.dart';
import '../internals/section_label.dart';
import 'meta_field_row.dart';

/// Full-screen drop-in editor for a [CardioPlan].
///
/// Mirrors `PlanEditorScreen` on the strength side: the host app provides an
/// optional [existing] plan and an [onSave] callback. The widget owns the
/// edit state internally so consumers do not have to manage controllers or
/// keep an intermediate plan instance.
///
/// The editor renders:
///
/// * an inline-editable plan name in the appbar plus a `Save` action that is
///   disabled while the name is empty or the plan has no intervals,
/// * a soft `previewSummary` chip below the appbar,
/// * a plan-meta block (description, discipline),
/// * a reorderable interval list with name, phase pill, target duration,
///   target distance and MET steppers, plus a kebab menu for duplicate /
///   remove,
/// * a tap-to-expand panel on each interval row for the advanced fields
///   (intensity label, pace per km, free-form notes),
/// * an "Add interval" button below the list (defaults to a 60 s `work`
///   segment).
///
/// All construction goes through [CardioPlanBuilder] so the resulting plan
/// matches the builder's slug-id semantics. The widget never mutates the
/// passed-in [existing]; [onSave] is invoked with a freshly built plan.
class CardioPlanEditorScreen extends StatefulWidget {
  /// When non-null, the editor pre-fills its fields from this plan. When
  /// `null`, the editor starts empty and the user is expected to enter at
  /// least a name and one interval before [onSave] can fire.
  final CardioPlan? existing;

  /// Invoked when the user taps `Save` with a non-empty, non-zero-interval
  /// plan. The callback receives a freshly built [CardioPlan].
  final ValueChanged<CardioPlan> onSave;

  /// Optional cancel/back action. When non-null, a leading `close` icon is
  /// rendered in the appbar that calls this callback. Hosts that push the
  /// editor onto a [Navigator] can leave this `null` and rely on the standard
  /// back button.
  final VoidCallback? onCancel;

  const CardioPlanEditorScreen({
    super.key,
    this.existing,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<CardioPlanEditorScreen> createState() => _CardioPlanEditorScreenState();
}

class _CardioPlanEditorScreenState extends State<CardioPlanEditorScreen> {
  late TextEditingController _nameController;
  late String _name;
  late String _description;
  late CardioDiscipline _discipline;
  late List<_IntervalDraft> _intervals;
  final Set<String> _expanded = <String>{};
  int _autoCounter = 1;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = existing?.name ?? '';
    _description = existing?.description ?? '';
    _discipline = existing?.discipline ?? CardioDiscipline.mixed;
    _intervals = [
      if (existing != null)
        for (final interval in existing.intervals)
          _IntervalDraft.fromInterval(interval),
    ];
    _nameController = TextEditingController(text: _name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave => _name.trim().isNotEmpty && _intervals.isNotEmpty;

  CardioPlan _buildPlan() {
    final builder = CardioPlanBuilder(
      _name.trim(),
      id: widget.existing?.id,
      description: _description.trim().isEmpty ? null : _description.trim(),
      discipline: _discipline,
      category: widget.existing?.category,
      meta: widget.existing?.meta,
    );
    for (final draft in _intervals) {
      builder.interval(
        name: draft.name.trim().isEmpty ? 'Interval' : draft.name.trim(),
        phase: draft.phase,
        duration: draft.duration,
        distanceMeters: draft.distanceMeters,
        intensity:
            draft.intensity?.trim().isEmpty ?? true
                ? null
                : draft.intensity!.trim(),
        pacePerKm: draft.pacePerKm,
        notes: draft.notes?.trim().isEmpty ?? true ? null : draft.notes!.trim(),
        met: draft.met,
        id: draft.id,
      );
    }
    return builder.build();
  }

  void _handleSave() {
    if (!_canSave) return;
    widget.onSave(_buildPlan());
  }

  void _addInterval() {
    setState(() {
      final id =
          'interval-${DateTime.now().microsecondsSinceEpoch}-'
          '${_autoCounter++}';
      _intervals.add(
        _IntervalDraft(
          id: id,
          name: 'Work ${_intervals.length + 1}',
          phase: CardioPhase.work,
          duration: const Duration(seconds: 60),
        ),
      );
    });
  }

  void _duplicateInterval(int index) {
    setState(() {
      final source = _intervals[index];
      final id =
          'interval-${DateTime.now().microsecondsSinceEpoch}-'
          '${_autoCounter++}';
      _intervals.insert(index + 1, source.copyWith(id: id));
    });
  }

  void _removeInterval(int index) {
    setState(() {
      final removed = _intervals.removeAt(index);
      _expanded.remove(removed.id);
    });
  }

  void _reorderInterval(int oldIndex, int newIndex) {
    setState(() {
      var to = newIndex;
      if (to > oldIndex) to -= 1;
      final item = _intervals.removeAt(oldIndex);
      _intervals.insert(to, item);
    });
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  void _updateInterval(int index, _IntervalDraft Function(_IntervalDraft) f) {
    setState(() {
      _intervals[index] = f(_intervals[index]);
    });
  }

  String get _previewSummary {
    if (_intervals.isEmpty) return '0 intervals';
    final total = _intervals.fold<Duration>(
      Duration.zero,
      (acc, i) => acc + (i.duration ?? Duration.zero),
    );
    final distance = _intervals.fold<double>(
      0,
      (acc, i) => acc + (i.distanceMeters ?? 0),
    );
    final minutes = total.inMinutes;
    final minutesPart = minutes <= 0 ? '<1 min' : '~$minutes min';
    final distanceKm = distance / 1000;
    final distancePart =
        distanceKm > 0
            ? ' • ${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km'
            : '';
    final n = _intervals.length;
    return '$n ${n == 1 ? 'interval' : 'intervals'} • '
        '$minutesPart$distancePart';
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.textPrimary,
        elevation: 0,
        leading:
            widget.onCancel == null
                ? null
                : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onCancel,
                  tooltip: 'Cancel',
                ),
        titleSpacing: 0,
        title: TextField(
          key: const ValueKey('cardio-plan-name-field'),
          controller: _nameController,
          onChanged: (v) => setState(() => _name = v),
          cursorColor: t.accent,
          style: t.titleLarge,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: 'Plan name',
            hintStyle: t.titleLarge.copyWith(color: t.textDim),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.space3),
            child: Center(
              child: RunnerPillButton(
                key: const ValueKey('cardio-plan-save-button'),
                label: 'Save',
                style: RunnerButtonStyle.accent,
                onPressed: _canSave ? _handleSave : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : t.motionFast,
          child: ListView(
            key: const ValueKey('cardio-plan-editor-list'),
            padding: EdgeInsets.fromLTRB(
              t.space4,
              t.space3,
              t.space4,
              t.space6,
            ),
            children: [
              _PreviewChip(text: _previewSummary),
              SizedBox(height: t.space4),
              _MetaCard(
                description: _description,
                discipline: _discipline,
                onDescriptionChanged: (v) => setState(() => _description = v),
                onDisciplineChanged:
                    (v) => setState(() => _discipline = v ?? _discipline),
              ),
              SizedBox(height: t.space5),
              SectionLabel(
                'Intervals',
                trailing: Text(
                  '${_intervals.length}',
                  style: t.caption.copyWith(color: t.textMuted),
                ),
              ),
              SizedBox(height: t.space2),
              if (_intervals.isEmpty)
                _EmptyIntervals(onAdd: _addInterval)
              else
                ReorderableListView.builder(
                  key: const ValueKey('cardio-plan-interval-list'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _intervals.length,
                  onReorder: _reorderInterval,
                  itemBuilder: (ctx, index) {
                    final draft = _intervals[index];
                    return _IntervalRow(
                      key: ValueKey(draft.id),
                      index: index,
                      draft: draft,
                      expanded: _expanded.contains(draft.id),
                      onTap: () => _toggleExpanded(draft.id),
                      onNameChanged:
                          (v) => _updateInterval(
                            index,
                            (d) => d.copyWith(name: v),
                          ),
                      onPhaseChanged:
                          (v) => _updateInterval(
                            index,
                            (d) => d.copyWith(phase: v ?? d.phase),
                          ),
                      onDurationChanged:
                          (seconds) => _updateInterval(
                            index,
                            (d) => d.copyWith(
                              duration:
                                  seconds == 0
                                      ? null
                                      : Duration(seconds: seconds.toInt()),
                              clearDuration: seconds == 0,
                            ),
                          ),
                      onDistanceChanged:
                          (meters) => _updateInterval(
                            index,
                            (d) => d.copyWith(
                              distanceMeters:
                                  meters == 0 ? null : meters.toDouble(),
                              clearDistance: meters == 0,
                            ),
                          ),
                      onMetChanged:
                          (met) => _updateInterval(
                            index,
                            (d) => d.copyWith(
                              met: met == 0 ? null : met.toDouble(),
                              clearMet: met == 0,
                            ),
                          ),
                      onIntensityChanged:
                          (v) => _updateInterval(
                            index,
                            (d) => d.copyWith(intensity: v),
                          ),
                      onNotesChanged:
                          (v) => _updateInterval(
                            index,
                            (d) => d.copyWith(notes: v),
                          ),
                      onPaceSecondsChanged:
                          (seconds) => _updateInterval(
                            index,
                            (d) => d.copyWith(
                              pacePerKm:
                                  seconds == 0
                                      ? null
                                      : Duration(seconds: seconds.toInt()),
                              clearPace: seconds == 0,
                            ),
                          ),
                      onDuplicate: () => _duplicateInterval(index),
                      onRemove: () => _removeInterval(index),
                    );
                  },
                ),
              SizedBox(height: t.space3),
              RunnerPillButton(
                key: const ValueKey('cardio-plan-add-interval'),
                label: 'Add interval',
                icon: Icons.add_rounded,
                style: RunnerButtonStyle.filled,
                expand: true,
                onPressed: _addInterval,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mutable draft of a [CardioInterval] used by the editor. Held in editor
/// state to keep all the optional fields and stable ids together.
class _IntervalDraft {
  final String id;
  final String name;
  final CardioPhase phase;
  final Duration? duration;
  final double? distanceMeters;
  final double? met;
  final String? intensity;
  final Duration? pacePerKm;
  final String? notes;

  const _IntervalDraft({
    required this.id,
    required this.name,
    required this.phase,
    this.duration,
    this.distanceMeters,
    this.met,
    this.intensity,
    this.pacePerKm,
    this.notes,
  });

  factory _IntervalDraft.fromInterval(CardioInterval i) => _IntervalDraft(
    id: i.id,
    name: i.name,
    phase: i.phase,
    duration: i.targetDuration,
    distanceMeters: i.targetDistanceMeters,
    met: i.met,
    intensity: i.intensity,
    pacePerKm: i.targetPacePerKm,
    notes: i.notes,
  );

  _IntervalDraft copyWith({
    String? id,
    String? name,
    CardioPhase? phase,
    Duration? duration,
    double? distanceMeters,
    double? met,
    String? intensity,
    Duration? pacePerKm,
    String? notes,
    bool clearDuration = false,
    bool clearDistance = false,
    bool clearMet = false,
    bool clearPace = false,
  }) => _IntervalDraft(
    id: id ?? this.id,
    name: name ?? this.name,
    phase: phase ?? this.phase,
    duration: clearDuration ? null : (duration ?? this.duration),
    distanceMeters:
        clearDistance ? null : (distanceMeters ?? this.distanceMeters),
    met: clearMet ? null : (met ?? this.met),
    intensity: intensity ?? this.intensity,
    pacePerKm: clearPace ? null : (pacePerKm ?? this.pacePerKm),
    notes: notes ?? this.notes,
  );
}

class _PreviewChip extends StatelessWidget {
  final String text;
  const _PreviewChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: t.space2),
        decoration: BoxDecoration(
          color: t.surfaceElevated,
          borderRadius: t.radiusPill,
          border: Border.all(color: t.border),
        ),
        child: Text(
          text,
          style: t.caption.copyWith(color: t.textMuted),
          key: const ValueKey('cardio-plan-preview-chip'),
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final String description;
  final CardioDiscipline discipline;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<CardioDiscipline?> onDisciplineChanged;

  const _MetaCard({
    required this.description,
    required this.discipline,
    required this.onDescriptionChanged,
    required this.onDisciplineChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Plan meta'),
          SizedBox(height: t.space2),
          MetaFieldRow.text(
            label: 'Description',
            value: description,
            hint: '5x400m intervals with 1 min rest',
            maxLines: 2,
            onChanged: onDescriptionChanged,
          ),
          MetaFieldRow.dropdown<CardioDiscipline>(
            label: 'Discipline',
            value: discipline,
            items: [
              for (final d in CardioDiscipline.values)
                DropdownMenuItem(value: d, child: Text(_disciplineLabel(d))),
            ],
            onChanged: onDisciplineChanged,
          ),
        ],
      ),
    );
  }
}

class _EmptyIntervals extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyIntervals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('No intervals yet', style: t.title, textAlign: TextAlign.center),
          SizedBox(height: t.space1),
          Text(
            'Add at least one interval to save this plan.',
            style: t.bodyMuted,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: t.space3),
          RunnerPillButton(
            label: 'Add first interval',
            icon: Icons.add_rounded,
            style: RunnerButtonStyle.accent,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  final int index;
  final _IntervalDraft draft;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<CardioPhase?> onPhaseChanged;
  final ValueChanged<num> onDurationChanged;
  final ValueChanged<num> onDistanceChanged;
  final ValueChanged<num> onMetChanged;
  final ValueChanged<String> onIntensityChanged;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<num> onPaceSecondsChanged;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;

  const _IntervalRow({
    super.key,
    required this.index,
    required this.draft,
    required this.expanded,
    required this.onTap,
    required this.onNameChanged,
    required this.onPhaseChanged,
    required this.onDurationChanged,
    required this.onDistanceChanged,
    required this.onMetChanged,
    required this.onIntensityChanged,
    required this.onNotesChanged,
    required this.onPaceSecondsChanged,
    required this.onDuplicate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Padding(
      key: ValueKey('cardio-plan-interval-${draft.id}'),
      padding: EdgeInsets.only(bottom: t.space3),
      child: RunnerCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.only(right: t.space2),
                    child: Icon(Icons.drag_indicator_rounded, color: t.textDim),
                  ),
                ),
                Expanded(
                  child: MetaFieldRow.text(
                    label: 'Name',
                    value: draft.name,
                    hint: 'Sprint',
                    onChanged: onNameChanged,
                  ),
                ),
                _KebabMenu(onDuplicate: onDuplicate, onRemove: onRemove),
              ],
            ),
            MetaFieldRow.dropdown<CardioPhase>(
              label: 'Phase',
              value: draft.phase,
              items: [
                for (final p in CardioPhase.values)
                  DropdownMenuItem(value: p, child: Text(_phaseLabel(p))),
              ],
              onChanged: onPhaseChanged,
            ),
            SizedBox(height: t.space2),
            MetaFieldRow.stepper(
              label: 'Duration',
              value: draft.duration?.inSeconds ?? 0,
              min: 0,
              max: 3600,
              smallStep: 5,
              integer: true,
              unit: 's',
              onChanged: onDurationChanged,
            ),
            MetaFieldRow.stepper(
              label: 'Distance',
              value: draft.distanceMeters?.round() ?? 0,
              min: 0,
              max: 10000,
              smallStep: 50,
              integer: true,
              unit: 'm',
              onChanged: onDistanceChanged,
            ),
            MetaFieldRow.stepper(
              label: 'MET',
              value: draft.met ?? 0,
              min: 0,
              max: 15,
              smallStep: 0.5,
              integer: false,
              onChanged: onMetChanged,
            ),
            if (expanded) ...[
              SizedBox(height: t.space2),
              const SectionLabel('Advanced'),
              MetaFieldRow.text(
                label: 'Intensity',
                value: draft.intensity ?? '',
                hint: 'Z3 / 8 RPE',
                onChanged: onIntensityChanged,
              ),
              MetaFieldRow.stepper(
                label: 'Pace /km',
                value: draft.pacePerKm?.inSeconds ?? 0,
                min: 0,
                max: 900,
                smallStep: 5,
                integer: true,
                unit: 's',
                onChanged: onPaceSecondsChanged,
              ),
              MetaFieldRow.text(
                label: 'Notes',
                value: draft.notes ?? '',
                hint: 'Nasal breathing only',
                maxLines: 2,
                onChanged: onNotesChanged,
              ),
            ] else
              Padding(
                padding: EdgeInsets.only(top: t.space2),
                child: Text(
                  'Tap to edit intensity, pace, notes',
                  style: t.caption.copyWith(color: t.textDim),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KebabMenu extends StatelessWidget {
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;

  const _KebabMenu({required this.onDuplicate, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return PopupMenuButton<String>(
      key: const ValueKey('cardio-plan-interval-kebab'),
      icon: Icon(Icons.more_vert_rounded, color: t.textMuted),
      color: t.surfaceElevated,
      onSelected: (v) {
        switch (v) {
          case 'duplicate':
            onDuplicate();
            break;
          case 'remove':
            onRemove();
            break;
        }
      },
      itemBuilder:
          (ctx) => [
            PopupMenuItem(
              value: 'duplicate',
              child: Text('Duplicate', style: t.body),
            ),
            PopupMenuItem(
              value: 'remove',
              child: Text('Remove', style: t.body.copyWith(color: t.danger)),
            ),
          ],
    );
  }
}

String _phaseLabel(CardioPhase p) {
  switch (p) {
    case CardioPhase.warmup:
      return 'Warmup';
    case CardioPhase.work:
      return 'Work';
    case CardioPhase.rest:
      return 'Rest';
    case CardioPhase.steady:
      return 'Steady';
    case CardioPhase.cooldown:
      return 'Cooldown';
  }
}

String _disciplineLabel(CardioDiscipline d) {
  switch (d) {
    case CardioDiscipline.running:
      return 'Running';
    case CardioDiscipline.cycling:
      return 'Cycling';
    case CardioDiscipline.rowing:
      return 'Rowing';
    case CardioDiscipline.swimming:
      return 'Swimming';
    case CardioDiscipline.jumpRope:
      return 'Jump rope';
    case CardioDiscipline.walk:
      return 'Walk';
    case CardioDiscipline.mixed:
      return 'Mixed';
  }
}
