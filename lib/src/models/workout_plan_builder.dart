import 'exercise_category.dart';
import 'muscle.dart';
import 'workout_exercise.dart';
import 'workout_plan.dart';
import 'workout_set.dart';

/// Fluent builder for creating [WorkoutPlan]s without deeply nested model
/// constructors.
///
/// Example:
///
/// ```dart
/// final plan = WorkoutPlanBuilder('Push day')
///   .exercise('Bench press')
///   .set(reps: 8, weight: 80)
///   .set(reps: 8, weight: 80)
///   .exercise('Shoulder press')
///   .set(reps: 10)
///   .build();
/// ```
class WorkoutPlanBuilder {
  WorkoutPlanBuilder(
    this.name, {
    String? id,
    this.description,
    Map<String, dynamic>? meta,
  }) : id = id ?? _slug(name),
       meta = meta == null ? null : Map<String, dynamic>.from(meta);

  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic>? meta;

  final List<_ExerciseDraft> _exercises = [];

  /// Add a new exercise and make it the target for subsequent [set] calls.
  WorkoutPlanBuilder exercise(
    String name, {
    String? id,
    String? description,
    ExerciseCategory? category,
    List<Muscle> muscles = const [],
    String? notes,
    Map<String, dynamic>? meta,
  }) {
    final baseId = id ?? _slug(name);
    _exercises.add(
      _ExerciseDraft(
        id: _uniqueExerciseId(baseId),
        name: name,
        description: description,
        category: category,
        muscles: List<Muscle>.unmodifiable(muscles),
        notes: notes,
        meta: meta == null ? null : Map<String, dynamic>.from(meta),
      ),
    );
    return this;
  }

  /// Append an already constructed exercise.
  WorkoutPlanBuilder addExercise(WorkoutExercise exercise) {
    _exercises.add(_ExerciseDraft.fromExercise(exercise));
    return this;
  }

  /// Add a target set to the most recently added exercise.
  WorkoutPlanBuilder set({required int reps, double? weight, Duration? rest}) {
    if (_exercises.isEmpty) {
      throw StateError('Call exercise() before adding sets.');
    }
    _exercises.last.sets.add(
      WorkoutSet(targetReps: reps, targetWeight: weight, rest: rest),
    );
    return this;
  }

  /// Append an already constructed target set to the most recent exercise.
  WorkoutPlanBuilder addSet(WorkoutSet set) {
    if (_exercises.isEmpty) {
      throw StateError('Call exercise() before adding sets.');
    }
    _exercises.last.sets.add(set);
    return this;
  }

  WorkoutPlan build() => WorkoutPlan(
    id: id,
    name: name,
    description: description,
    exercises: _exercises.map((e) => e.build()).toList(growable: false),
    meta: meta,
  );

  /// Seed a builder from an existing plan — useful for editors that want a
  /// mutable copy without forking the constructor signature.
  factory WorkoutPlanBuilder.fromPlan(WorkoutPlan plan) {
    final b = WorkoutPlanBuilder(
      plan.name,
      id: plan.id,
      description: plan.description,
      meta: plan.meta,
    );
    for (final ex in plan.exercises) {
      b._exercises.add(_ExerciseDraft.fromExercise(ex));
    }
    return b;
  }

  String _uniqueExerciseId(String baseId) {
    final normalizedBase = baseId.isEmpty ? 'exercise' : baseId;
    var candidate = normalizedBase;
    var suffix = 2;
    final existing = _exercises.map((e) => e.id).toSet();
    while (existing.contains(candidate)) {
      candidate = '$normalizedBase-$suffix';
      suffix++;
    }
    return candidate;
  }
}

class _ExerciseDraft {
  _ExerciseDraft({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.muscles,
    this.notes,
    this.meta,
    List<WorkoutSet>? sets,
  }) : sets = sets ?? [];

  factory _ExerciseDraft.fromExercise(WorkoutExercise exercise) =>
      _ExerciseDraft(
        id: exercise.id,
        name: exercise.name,
        description: exercise.description,
        category: exercise.category,
        muscles: List<Muscle>.unmodifiable(exercise.muscles),
        notes: exercise.notes,
        meta:
            exercise.meta == null
                ? null
                : Map<String, dynamic>.from(exercise.meta!),
        sets: List<WorkoutSet>.from(exercise.sets),
      );

  final String id;
  final String name;
  final String? description;
  final ExerciseCategory? category;
  final List<Muscle> muscles;
  final String? notes;
  final Map<String, dynamic>? meta;
  final List<WorkoutSet> sets;

  WorkoutExercise build() => WorkoutExercise(
    id: id,
    name: name,
    description: description,
    category: category,
    muscles: muscles,
    sets: List<WorkoutSet>.unmodifiable(sets),
    notes: notes,
    meta: meta,
  );
}

String _slug(String input) {
  final normalized = input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'plan' : normalized;
}
