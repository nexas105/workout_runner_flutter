import 'package:flutter/foundation.dart';

import 'performed_set.dart';

/// An exercise as performed during a workout — name snapshot + executed sets.
@immutable
class PerformedExercise {
  final int exerciseIndex;
  final String exerciseName;
  final List<PerformedSet> sets;

  const PerformedExercise({
    required this.exerciseIndex,
    required this.exerciseName,
    required this.sets,
  });

  PerformedExercise copyWith({
    int? exerciseIndex,
    String? exerciseName,
    List<PerformedSet>? sets,
  }) => PerformedExercise(
    exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    exerciseName: exerciseName ?? this.exerciseName,
    sets: sets ?? this.sets,
  );

  Map<String, dynamic> toJson() => {
    'exerciseIndex': exerciseIndex,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  factory PerformedExercise.fromJson(Map<String, dynamic> json) =>
      PerformedExercise(
        exerciseIndex: (json['exerciseIndex'] as num).toInt(),
        exerciseName: json['exerciseName'] as String,
        sets:
            (json['sets'] as List<dynamic>)
                .map((s) => PerformedSet.fromJson(s as Map<String, dynamic>))
                .toList(),
      );
}
