class WorkoutResult {
  final String planId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<ExerciseSummary> exercises;

  WorkoutResult({
    required this.planId,
    required this.startedAt,
    required this.finishedAt,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
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
