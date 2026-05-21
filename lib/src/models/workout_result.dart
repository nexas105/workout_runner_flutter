import 'package:flutter/foundation.dart';

import 'performed_set.dart';

/// Returned by [WorkoutRunner.finish] and emitted via the finished stream.
@immutable
class WorkoutResult {
  final String planId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final Duration duration;
  final List<PerformedExerciseDetails> exercises;

  const WorkoutResult({
    required this.planId,
    required this.startedAt,
    required this.finishedAt,
    required this.duration,
    required this.exercises,
  });

  /// Total number of completed sets across all exercises.
  int get totalSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);

  /// Total reps across all completed sets.
  int get totalReps =>
      exercises.fold(0, (sum, e) => sum + e.sets.fold(0, (s, x) => s + x.actualReps));

  /// Sum of (weight × reps) where weight is set.
  double get totalVolume => exercises.fold(
        0.0,
        (sum, e) => sum +
            e.sets.fold(
              0.0,
              (s, x) => s + (x.actualWeight ?? 0) * x.actualReps,
            ),
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'duration': duration.inSeconds,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutResult.fromJson(Map<String, dynamic> json) => WorkoutResult(
        planId: json['planId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        duration: Duration(seconds: (json['duration'] as num).toInt()),
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) =>
                PerformedExerciseDetails.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class PerformedExerciseDetails {
  final String exerciseId;
  final String exerciseName;
  final List<PerformedSet> sets;

  const PerformedExerciseDetails({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory PerformedExerciseDetails.fromJson(Map<String, dynamic> json) =>
      PerformedExerciseDetails(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        sets: (json['sets'] as List<dynamic>)
            .map((s) => PerformedSet.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
