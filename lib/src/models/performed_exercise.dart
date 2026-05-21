import 'package:flutter/foundation.dart';

import 'performed_set.dart';

/// An exercise as performed during a workout — name snapshot + executed sets.
@immutable
class PerformedExercise {
  final int exerciseIndex;
  final String exerciseName;
  final List<PerformedSet> sets;

  /// When the exercise was substituted mid-session, this carries the
  /// originally-planned exercise's id. `null` for first-class plan entries.
  /// Lets history readers tell "I swapped this in" apart from "this was on
  /// the plan from the start".
  final String? substitutedFrom;

  const PerformedExercise({
    required this.exerciseIndex,
    required this.exerciseName,
    required this.sets,
    this.substitutedFrom,
  });

  PerformedExercise copyWith({
    int? exerciseIndex,
    String? exerciseName,
    List<PerformedSet>? sets,
    String? substitutedFrom,
  }) => PerformedExercise(
    exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    exerciseName: exerciseName ?? this.exerciseName,
    sets: sets ?? this.sets,
    substitutedFrom: substitutedFrom ?? this.substitutedFrom,
  );

  Map<String, dynamic> toJson() => {
    'exerciseIndex': exerciseIndex,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
    if (substitutedFrom != null) 'substitutedFrom': substitutedFrom,
  };

  factory PerformedExercise.fromJson(Map<String, dynamic> json) =>
      PerformedExercise(
        exerciseIndex: (json['exerciseIndex'] as num).toInt(),
        exerciseName: json['exerciseName'] as String,
        sets:
            (json['sets'] as List<dynamic>)
                .map((s) => PerformedSet.fromJson(s as Map<String, dynamic>))
                .toList(),
        substitutedFrom: json['substitutedFrom'] as String?,
      );
}
