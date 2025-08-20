import 'dart:convert';

class WorkoutPlan {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;

  WorkoutPlan({required this.id, required this.name, required this.exercises});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    exercises:
        (json['exercises'] as List)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

  String toJsonString() => jsonEncode(toJson());
  factory WorkoutPlan.fromJsonString(String s) =>
      WorkoutPlan.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class WorkoutExercise {
  final String id;
  final String name;
  final List<WorkoutSet> sets;
  final Map<String, dynamic>? meta;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sets': sets.map((s) => s.toJson()).toList(),
    'meta': meta,
  };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String,
        name: json['name'] as String,
        sets:
            (json['sets'] as List)
                .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
                .toList(),
        meta: json['meta'] as Map<String, dynamic>?,
      );
}

class WorkoutSet {
  final int targetReps;
  final double? targetWeight;
  final Duration? rest;

  WorkoutSet({required this.targetReps, this.targetWeight, this.rest});

  Map<String, dynamic> toJson() => {
    'targetReps': targetReps,
    'targetWeight': targetWeight,
    'rest': rest?.inSeconds,
  };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    targetReps: json['targetReps'] as int,
    targetWeight: (json['targetWeight'] as num?)?.toDouble(),
    rest: json['rest'] == null ? null : Duration(seconds: json['rest'] as int),
  );
}

class WorkoutRunnerState {
  final String planId;
  final int exerciseIndex;
  int? activeExerciseIndex;
  final int setIndex;

  /// Workout läuft generell
  final bool isActive;

  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime exerciseStartedAt;
  final DateTime setStartedAt;

  final List<PerformedExercise> performed;

  WorkoutRunnerState({
    required this.planId,
    required this.exerciseIndex,
    required this.activeExerciseIndex,
    required this.setIndex,
    required this.isActive,

    required this.startedAt,
    required this.updatedAt,
    required this.exerciseStartedAt,
    required this.setStartedAt,
    required this.performed,
  });

  WorkoutRunnerState copyWith({
    int? exerciseIndex,
    int? activeExerciseIndex,
    int? setIndex,
    bool? isActive,
    bool? isExerciseRunning,
    bool? isSetRunning,
    bool? isResting,
    DateTime? restEndsAt, // mit _NullRest() explizit auf null setzen
    DateTime? updatedAt,
    DateTime? exerciseStartedAt,
    DateTime? setStartedAt,
    List<PerformedExercise>? performed,
  }) => WorkoutRunnerState(
    planId: planId,
    exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    activeExerciseIndex: activeExerciseIndex ?? this.activeExerciseIndex,
    setIndex: setIndex ?? this.setIndex,
    isActive: isActive ?? this.isActive,

    startedAt: startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    exerciseStartedAt: exerciseStartedAt ?? this.exerciseStartedAt,
    setStartedAt: setStartedAt ?? this.setStartedAt,
    performed: performed ?? this.performed,
  );

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'exerciseIndex': exerciseIndex,
    'activeExerciseIndex': activeExerciseIndex,

    'setIndex': setIndex,
    'isActive': isActive,

    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'exerciseStartedAt': exerciseStartedAt.toIso8601String(),
    'setStartedAt': setStartedAt.toIso8601String(),
    'performed': performed.map((e) => e.toJson()).toList(),
  };

  factory WorkoutRunnerState.fromJson(Map<String, dynamic> json) =>
      WorkoutRunnerState(
        planId: json['planId'] as String,
        exerciseIndex: json['exerciseIndex'] as int,
        activeExerciseIndex: json['activeExerciseIndex'] as int,

        setIndex: json['setIndex'] as int,
        isActive: (json['isActive'] as bool?) ?? true,

        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        exerciseStartedAt: DateTime.parse(json['exerciseStartedAt'] as String),
        setStartedAt: DateTime.parse(json['setStartedAt'] as String),
        performed:
            (json['performed'] as List)
                .map(
                  (e) => PerformedExercise.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );
}

class PerformedExercise {
  final int exerciseIndex;
  final String exerciseName;
  final List<PerformedSet> sets;

  PerformedExercise({
    required this.exerciseIndex,
    required this.exerciseName,
    required this.sets,
  });

  Map<String, dynamic> toJson() => {
    'exerciseIndex': exerciseIndex,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  factory PerformedExercise.fromJson(Map<String, dynamic> json) =>
      PerformedExercise(
        exerciseIndex: json['exerciseIndex'] as int,
        exerciseName: json['exerciseName'] as String,
        sets:
            (json['sets'] as List<dynamic>)
                .map((s) => PerformedSet.fromJson(s))
                .toList(),
      );
}

class PerformedSet {
  final int exerciseIndex;
  final int setIndex;

  final int actualReps;
  final double? actualWeight;
  final int? rir; // "Reps in Reserve"
  final Duration? restTaken;
  final DateTime completedAt;

  PerformedSet({
    required this.exerciseIndex,
    required this.setIndex,
    required this.actualReps,
    this.actualWeight,
    this.rir,
    this.restTaken,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'exerciseIndex': exerciseIndex,
    'setIndex': setIndex,
    'actualReps': actualReps,
    'actualWeight': actualWeight,
    'rir': rir,
    'restTaken': restTaken?.inSeconds,
    'completedAt': completedAt.toIso8601String(),
  };

  factory PerformedSet.fromJson(Map<String, dynamic> json) => PerformedSet(
    exerciseIndex: json['exerciseIndex'] as int,
    setIndex: json['setIndex'] as int,
    actualReps: json['actualReps'] as int,
    actualWeight: (json['actualWeight'] as num?)?.toDouble(),
    rir: json['rir'] as int?,
    restTaken:
        json['restTaken'] == null
            ? null
            : Duration(seconds: json['restTaken'] as int),
    completedAt: DateTime.parse(json['completedAt'] as String),
  );
}
