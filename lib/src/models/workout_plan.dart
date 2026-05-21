import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../internal/schema.dart';
import 'workout_exercise.dart';

@immutable
class WorkoutPlan {
  final String id;
  final String name;
  final String? description;
  final List<WorkoutExercise> exercises;
  final Map<String, dynamic>? meta;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.exercises,
    this.description,
    this.meta,
  });

  WorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    Map<String, dynamic>? meta,
  }) => WorkoutPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    exercises: exercises ?? this.exercises,
    meta: meta ?? this.meta,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': kPluginSchemaVersion,
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    if (meta != null) 'meta': meta,
  };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    exercises:
        (json['exercises'] as List<dynamic>)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
    meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
  );

  String toJsonString() => jsonEncode(toJson());
  factory WorkoutPlan.fromJsonString(String s) =>
      WorkoutPlan.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Returns a copy of the plan with a fresh [id]. Useful when forking a
  /// catalog plan into a user-owned variant.
  WorkoutPlan cloneWithId(String newId) => copyWith(id: newId);

  /// Total target set count across all exercises.
  int get totalTargetSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);

  /// Rough estimate of how long this plan takes if every set is executed.
  /// Uses each set's `targetDuration` when present, otherwise assumes 30 s of
  /// work per set, plus the set's `rest`. Returned value is meant for UI
  /// previews, not training planning.
  Duration get estimatedDuration {
    const defaultWork = Duration(seconds: 30);
    var total = Duration.zero;
    for (final ex in exercises) {
      for (final s in ex.sets) {
        total += s.targetDuration ?? defaultWork;
        total += s.rest ?? Duration.zero;
      }
    }
    return total;
  }

  /// One-line summary suited for plan picker cards, e.g.
  /// `"5 exercises • 15 sets • ~45 min"`. Localise it yourself if needed —
  /// this is meant for quick debug / default surfaces only.
  String get previewSummary {
    final minutes = estimatedDuration.inMinutes;
    final minutesPart = minutes <= 0 ? '<1 min' : '~$minutes min';
    return '${exercises.length} '
        '${exercises.length == 1 ? 'exercise' : 'exercises'} '
        '• $totalTargetSets ${totalTargetSets == 1 ? 'set' : 'sets'} '
        '• $minutesPart';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutPlan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
