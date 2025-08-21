import 'package:fitness_workout/fitness_workout.dart';

class WorkoutResult {
  final String planId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final Duration duration;
  // NEU: Nutzt jetzt eine detaillierte Liste anstelle einer Zusammenfassung
  final List<PerformedExerciseDetails> exercises;

  WorkoutResult({
    required this.planId,
    required this.duration,
    required this.startedAt,
    required this.finishedAt,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    // Duration is stored as total seconds for easy serialization.
    'duration': duration.inSeconds,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  /// Creates a WorkoutResult object from a JSON map.
  factory WorkoutResult.fromJson(Map<String, dynamic> json) {
    return WorkoutResult(
      planId: json['planId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: DateTime.parse(json['finishedAt'] as String),
      // Reconstructs the Duration from the stored seconds.
      duration: Duration(seconds: json['duration'] as int),
      // Maps over the list of exercises and creates each one from its JSON representation.
      exercises:
          (json['exercises'] as List<dynamic>)
              .map(
                (e) => PerformedExerciseDetails.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}

class PerformedExerciseDetails {
  final String exerciseId;
  final String exerciseName;
  final List<PerformedSet> sets;

  PerformedExerciseDetails({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  /// Converts the object into a JSON map.
  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  /// Creates an object from a JSON map.
  factory PerformedExerciseDetails.fromJson(Map<String, dynamic> json) {
    return PerformedExerciseDetails(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      // Maps over the list of sets and creates each one from its JSON representation.
      sets:
          (json['sets'] as List<dynamic>)
              .map((s) => PerformedSet.fromJson(s as Map<String, dynamic>))
              .toList(),
    );
  }
}

class ExerciseSummary {
  final String exerciseId;
  final int setsCompleted;
  final int repsTotal;
  final double volume;

  ExerciseSummary({
    required this.exerciseId,
    required this.setsCompleted,
    required this.repsTotal,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'setsCompleted': setsCompleted,
    'repsTotal': repsTotal,
    'volume': volume,
  };
}
