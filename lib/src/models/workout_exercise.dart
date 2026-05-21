import 'package:flutter/foundation.dart';

import 'exercise_category.dart';
import 'muscle.dart';
import 'workout_set.dart';

@immutable
class WorkoutExercise {
  final String id;
  final String name;
  final String? description;
  final ExerciseCategory? category;
  final List<Muscle> muscles;
  final List<WorkoutSet> sets;
  final String? notes;
  final Map<String, dynamic>? meta;

  /// Metabolic Equivalent of Task — used by `WorkoutResult.kcal()` to estimate
  /// energy expenditure. When `null`, the exercise category's default is used,
  /// falling back to a global default if the category is also unknown.
  final double? met;

  const WorkoutExercise({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.muscles = const [],
    this.sets = const [],
    this.notes,
    this.meta,
    this.met,
  });

  WorkoutExercise copyWith({
    String? id,
    String? name,
    String? description,
    ExerciseCategory? category,
    List<Muscle>? muscles,
    List<WorkoutSet>? sets,
    String? notes,
    Map<String, dynamic>? meta,
    double? met,
  }) => WorkoutExercise(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    muscles: muscles ?? this.muscles,
    sets: sets ?? this.sets,
    notes: notes ?? this.notes,
    meta: meta ?? this.meta,
    met: met ?? this.met,
  );

  /// Returns a copy with a fresh [id]. Useful when forking a catalog exercise
  /// into a user-owned variant.
  WorkoutExercise cloneWithId(String newId) => copyWith(id: newId);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (category != null) 'category': category!.toJson(),
    'muscles': muscles.map((m) => m.toJson()).toList(),
    'sets': sets.map((s) => s.toJson()).toList(),
    if (notes != null) 'notes': notes,
    if (meta != null) 'meta': meta,
    if (met != null) 'met': met,
  };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category:
            json['category'] == null
                ? null
                : ExerciseCategory.fromJson(
                  json['category'] as Map<String, dynamic>,
                ),
        muscles:
            (json['muscles'] as List<dynamic>? ?? const [])
                .map((m) => Muscle.fromJson(m as Map<String, dynamic>))
                .toList(),
        sets:
            (json['sets'] as List<dynamic>? ?? const [])
                .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
                .toList(),
        notes: json['notes'] as String?,
        meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
        met: (json['met'] as num?)?.toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExercise &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
