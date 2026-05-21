import 'package:flutter/widgets.dart';

import '../models/set_type.dart';

/// All user-facing strings shown by the bundled workout-runner widgets.
///
/// The package ships an English-default implementation. To localise, subclass
/// [WorkoutRunnerLocalizations], override the strings you care about, and
/// expose your instance via [WorkoutRunnerLocalizationsScope]. Widgets that
/// haven't been migrated to use the lookup yet will continue to render their
/// hard-coded English fallback — the migration is additive, not breaking.
///
/// Number / duration formatters live alongside the strings so locale-aware
/// formatting only needs a single override site.
class WorkoutRunnerLocalizations {
  const WorkoutRunnerLocalizations();

  // ─── Set types ─────────────────────────────────────────────────────────────
  String labelForSetType(SetType type) => switch (type) {
        SetType.working => 'Working',
        SetType.warmup => 'Warmup',
        SetType.drop => 'Drop',
        SetType.failure => 'Failure',
        SetType.amrap => 'AMRAP',
        SetType.timed => 'Timed',
      };

  // ─── Set / input sheet ─────────────────────────────────────────────────────
  String get repsLabel => 'Reps';
  String get weightLabel => 'Weight';
  String get restLabel => 'Rest';
  String get restNone => 'None';
  String get repsInReserveLabel => 'Reps in reserve';
  String get saveSet => 'Save set';
  String get saveChanges => 'Save changes';
  String setIndexLabel(int index) => 'Set $index';
  String setEditLabel(int index) => 'Edit set $index';

  // ─── Rest overlay ──────────────────────────────────────────────────────────
  String get restHeader => 'REST';
  String get restGetReady => 'Get ready!';
  String get restBreathe => 'Breathe and shake it out';
  String get restAdd30 => '+30 s';
  String get restSkip => 'Skip rest';
  String get restRemainingTrailing => 'remaining';

  // ─── Results ───────────────────────────────────────────────────────────────
  String get workoutComplete => 'Workout complete';
  String get cardioComplete => 'Cardio complete';
  String get performedExercises => 'Performed exercises';
  String get closeAction => 'Close';
  String get statExercises => 'Exercises';
  String get statSets => 'Sets';
  String get statReps => 'Reps';
  String get statVolume => 'Volume';
  String get statLaps => 'Laps';
  String get statWorkTime => 'Work time';
  String get statDistance => 'Distance';
  String get statAvgPace => 'Avg pace';

  // ─── Common units ──────────────────────────────────────────────────────────
  String get unitKg => 'kg';
  String get unitKm => 'km';
  String get unitPerKm => '/km';

  // ─── Common actions / dialog buttons ───────────────────────────────────────
  String get actionCancel => 'Cancel';
  String get actionOk => 'OK';

  // ─── Number / duration formatters ──────────────────────────────────────────

  /// Format a [double] weight for display. Strips trailing `.0` so 60.0 → "60"
  /// while 62.5 → "62.5". Override to switch locales or units.
  String formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

/// Provides a [WorkoutRunnerLocalizations] to the subtree. Falls back to the
/// English defaults when no ancestor is present, so consumers only need to
/// install this if they want to override strings or formatters.
class WorkoutRunnerLocalizationsScope extends InheritedWidget {
  final WorkoutRunnerLocalizations data;

  const WorkoutRunnerLocalizationsScope({
    super.key,
    required this.data,
    required super.child,
  });

  static const WorkoutRunnerLocalizations _fallback =
      WorkoutRunnerLocalizations();

  static WorkoutRunnerLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WorkoutRunnerLocalizationsScope>();
    return scope?.data ?? _fallback;
  }

  @override
  bool updateShouldNotify(WorkoutRunnerLocalizationsScope oldWidget) =>
      data != oldWidget.data;
}
