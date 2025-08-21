import 'dart:convert';
import 'dart:math';

import 'package:fitness_workout/src/models/data/default_workout_data.dart';

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

extension _Str on String {
  String _n() => trim().toLowerCase();
}

class WorkoutExercise {
  final String id;
  final String name;
  final String? desc;
  final ExerciseCategorie? category;
  final List<Muscle>? muscles;
  final List<WorkoutSet> sets;
  final String? notes;
  final Map<String, dynamic>? meta;

  WorkoutExercise({
    required this.id,
    required this.name,
    this.desc,
    this.category,
    this.muscles,
    required this.sets,
    this.notes,
    this.meta,
  });

  WorkoutExercise copyWith({
    String? id,
    String? name,
    String? desc,
    ExerciseCategorie? category,
    List<Muscle>? muscles,
    List<WorkoutSet>? sets,
    String? notes,
    Map<String, dynamic>? meta,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      desc: desc ?? this.desc,
      category: category ?? this.category,
      muscles: muscles ?? this.muscles,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      meta: meta ?? this.meta,
    );
  }

  static final _rnd = Random();

  static List<WorkoutSet> generateRandomSets() {
    final setCount = 2 + _rnd.nextInt(3);
    return List.generate(setCount, (i) {
      final reps = 6 + _rnd.nextInt(7);
      final weight = 40 + _rnd.nextInt(61);
      return WorkoutSet(targetReps: reps, targetWeight: weight.toDouble());
    });
  }

  static List<WorkoutExercise> getDefaultExercises() {
    return defaultExercises;
  }

  static List<WorkoutExercise> getStrengthExercises() {
    return defaultExercises
        .where((e) => e.category?.name._n() == 'krafttraining')
        .toList();
  }

  static List<WorkoutExercise> getCardioExercises() {
    return defaultExercises
        .where((e) => e.category?.name._n() == 'cardio')
        .toList();
  }

  static List<WorkoutExercise> getExercisesByName(String query) {
    final q = query._n();
    if (q.isEmpty) return const [];
    return defaultExercises.where((e) => e.name._n().contains(q)).toList();
  }

  static List<WorkoutExercise> getByCategory(String categoryName) {
    final c = categoryName._n();
    return defaultExercises.where((e) => e.category?.name._n() == c).toList();
  }

  //Nach Muskelgurppe Suchen (Oberkörper)
  static List<WorkoutExercise> getByMuscleGroup(String group) {
    final g = group.trim().toLowerCase();
    return defaultExercises.where((e) {
      return e.muscles?.any((m) => (m.group ?? '').toLowerCase() == g) ?? false;
    }).toList();
  }

  static WorkoutExercise? getById(String id) {
    try {
      return defaultExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  factory WorkoutExercise.fromDefaultsByName(String name) {
    final base = getExercisesByName(name).first;
    return WorkoutExercise(
      id: base.id,
      name: base.name,
      desc: base.desc,
      category: base.category,
      muscles: base.muscles,
      sets: generateRandomSets(),
      notes: base.notes,
      meta: base.meta == null ? null : Map<String, dynamic>.from(base.meta!),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'desc': desc,
    'category': category?.name, // Speichere den Namen der Kategorie
    'muscles':
        muscles?.map((m) => m.name).toList(), // Speichere die Namen der Muskeln
    'sets': sets.map((s) => s.toJson()).toList(),
    'notes': notes,
    'meta': meta,
  };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final category =
        json['category'] != null
            ? ExerciseCategorie.findByName(json['category'])
            : null;
    final muscles =
        json['muscles'] != null
            ? (json['muscles'] as List)
                .map((name) => Muscle.findByName(name as String)!)
                .toList()
            : null;

    return WorkoutExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      desc: json['desc'] as String?,
      category: category,
      muscles: muscles,
      sets:
          (json['sets'] as List)
              .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
              .toList(),
      notes: json['notes'] as String?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}

class ExerciseCategorie {
  final String id;
  final String name;
  final String? description;

  ExerciseCategorie({required this.id, required this.name, this.description});

  static final List<ExerciseCategorie> categories = [
    ExerciseCategorie(
      id: '1',
      name: 'Krafttraining',
      description:
          'Übungen mit Gewichten oder Eigengewicht zur Steigerung von Kraft und Muskelmasse',
    ),
    ExerciseCategorie(
      id: '2',
      name: 'Cardio',
      description: 'Herz-Kreislauf-Training wie Laufen, Radfahren, Rudern',
    ),
    ExerciseCategorie(
      id: '3',
      name: 'Beweglichkeit',
      description:
          'Mobility, Stretching, Yoga zur Verbesserung von Flexibilität',
    ),
    ExerciseCategorie(
      id: '4',
      name: 'Core',
      description: 'Rumpfstabilität, Bauchübungen, Balance',
    ),
    ExerciseCategorie(
      id: '5',
      name: 'HIIT',
      description: 'Intervalltraining mit hoher Intensität',
    ),
  ];

  static ExerciseCategorie? findByName(String name) {
    try {
      return categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

class Muscle {
  final String id;
  final String name;
  final String? group;

  Muscle({required this.id, required this.name, this.group});

  static final List<Muscle> muscles = [
    Muscle(id: '1', name: 'Brust', group: 'Oberkörper'),
    Muscle(id: '2', name: 'Schultern', group: 'Oberkörper'),
    Muscle(id: '3', name: 'Trizeps', group: 'Oberkörper'),
    Muscle(id: '4', name: 'Bizeps', group: 'Oberkörper'),
    Muscle(id: '5', name: 'Rücken', group: 'Oberkörper'),
    Muscle(id: '6', name: 'Bauch', group: 'Core'),
    Muscle(id: '7', name: 'Quadrizeps', group: 'Unterkörper'),
    Muscle(id: '8', name: 'Hamstrings', group: 'Unterkörper'),
    Muscle(id: '9', name: 'Gluteus', group: 'Unterkörper'),
    Muscle(id: '10', name: 'Waden', group: 'Unterkörper'),
    Muscle(id: '11', name: 'Latissimus', group: 'Oberkörper'),
    Muscle(id: '12', name: 'Trapezius', group: 'Oberkörper'),
    Muscle(id: '13', name: 'Unterer Rücken', group: 'Core'),
    Muscle(id: '14', name: 'Unterarme', group: 'Oberkörper'),
    Muscle(id: '15', name: 'Seitliche Bauchmuskeln', group: 'Core'),
    Muscle(id: '16', name: 'Adduktoren', group: 'Unterkörper'),
    Muscle(id: '17', name: 'Abduktoren', group: 'Unterkörper'),
    Muscle(id: '18', name: 'Hintere Schulter', group: 'Oberkörper'),
    Muscle(id: '19', name: 'Sägezahnmuskel', group: 'Oberkörper'),
    Muscle(id: '20', name: 'Beinbeuger', group: 'Unterkörper'),
  ];

  static List<Muscle> getDefaultMuscles() {
    return muscles;
  }

  static Muscle? findByName(String name) {
    try {
      return muscles.firstWhere(
        (m) => m.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static List<Muscle> getByGroup(String group) {
    final g = group.trim().toLowerCase();
    return muscles.where((m) => (m.group ?? '').toLowerCase() == g).toList();
  }
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
    DateTime? restEndsAt,
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
                .map((s) => PerformedSet.fromJson(s as Map<String, dynamic>))
                .toList(),
      );
}

class PerformedSet {
  final int exerciseIndex;
  final int setIndex;

  final int actualReps;
  final double? actualWeight;
  final int? rir;
  final Duration? pause;
  final Duration? duration; // The duration of the set itself
  final DateTime completedAt;

  PerformedSet({
    required this.exerciseIndex,
    required this.setIndex,
    required this.actualReps,
    this.actualWeight,
    this.rir,
    this.pause,
    this.duration,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'exerciseIndex': exerciseIndex,
    'setIndex': setIndex,
    'actualReps': actualReps,
    'actualWeight': actualWeight,
    'rir': rir,
    'restTaken': pause?.inSeconds,
    // ADDED: Save the set duration in seconds
    'duration': duration?.inSeconds,
    'completedAt': completedAt.toIso8601String(),
  };

  factory PerformedSet.fromJson(Map<String, dynamic> json) => PerformedSet(
    exerciseIndex: json['exerciseIndex'] as int,
    setIndex: json['setIndex'] as int,
    actualReps: json['actualReps'] as int,
    actualWeight: (json['actualWeight'] as num?)?.toDouble(),
    rir: json['rir'] as int?,
    pause:
        json['restTaken'] == null
            ? null
            : Duration(seconds: json['restTaken'] as int),
    // ADDED: Reconstruct the duration from seconds
    duration:
        json['duration'] == null
            ? null
            : Duration(seconds: json['duration'] as int),
    completedAt: DateTime.parse(json['completedAt'] as String),
  );
}
