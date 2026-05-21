import '../models/set_type.dart';
import '../models/workout_exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_set.dart';
import 'default_exercises.dart';

/// Curated catalogue of ready-to-use strength [WorkoutPlan]s. Each plan is
/// built from [DefaultExercises] so muscle / category metadata stays in sync
/// with the rest of the package, and carries a `tmpl_*` id so it can be
/// distinguished from user-authored or [DefaultPlans] entries.
abstract class StrengthTemplates {
  static WorkoutExercise _byName(String name) {
    final lower = name.toLowerCase();
    return DefaultExercises.all.firstWhere(
      (e) => e.name.toLowerCase() == lower,
      orElse: () => throw StateError(
        'StrengthTemplates: DefaultExercises is missing "$name".',
      ),
    );
  }

  static WorkoutExercise _with(
    String exerciseName, {
    required List<WorkoutSet> sets,
  }) => _byName(exerciseName).copyWith(sets: sets);

  static List<WorkoutSet> _working({
    required int sets,
    required int reps,
    double? weight,
    Duration rest = const Duration(seconds: 90),
  }) => List<WorkoutSet>.generate(
    sets,
    (_) => WorkoutSet(targetReps: reps, targetWeight: weight, rest: rest),
  );

  /// Working sets prefixed with a single lighter warmup set. Warmup uses the
  /// same rest as the working sets so the runner doesn't sit idle longer than
  /// expected, but at roughly half the load.
  static List<WorkoutSet> _withWarmup({
    required int sets,
    required int reps,
    required int warmupReps,
    double? weight,
    Duration rest = const Duration(seconds: 90),
    double warmupFraction = 0.5,
  }) {
    final warmupWeight = weight == null ? null : weight * warmupFraction;
    return [
      WorkoutSet(
        targetReps: warmupReps,
        targetWeight: warmupWeight,
        rest: rest,
        type: SetType.warmup,
      ),
      ..._working(sets: sets, reps: reps, weight: weight, rest: rest),
    ];
  }

  static final WorkoutPlan fullBodyBeginner = WorkoutPlan(
    id: 'tmpl_full_body_beginner',
    name: 'Full body — beginner',
    description: 'Four compound lifts, 3x5 working sets, 2 min rest.',
    exercises: [
      _with(
        'Back squat',
        sets: _withWarmup(
          sets: 3,
          reps: 5,
          warmupReps: 8,
          weight: 40,
          rest: const Duration(minutes: 2),
        ),
      ),
      _with(
        'Bench press',
        sets: _withWarmup(
          sets: 3,
          reps: 5,
          warmupReps: 8,
          weight: 40,
          rest: const Duration(minutes: 2),
        ),
      ),
      _with(
        'Barbell row',
        sets: _withWarmup(
          sets: 3,
          reps: 5,
          warmupReps: 8,
          weight: 40,
          rest: const Duration(minutes: 2),
        ),
      ),
      _with(
        'Romanian deadlift',
        sets: _withWarmup(
          sets: 3,
          reps: 5,
          warmupReps: 8,
          weight: 50,
          rest: const Duration(minutes: 2),
        ),
      ),
    ],
    meta: const {
      'kind': 'strength',
      'split': 'full-body',
      'level': 'beginner',
      'template': 'full_body_beginner',
    },
  );

  static final WorkoutPlan pushDay = WorkoutPlan(
    id: 'tmpl_push_day',
    name: 'Push day — hypertrophy',
    description: 'Chest, shoulders, triceps. 4x8 hypertrophy scheme.',
    exercises: [
      _with(
        'Bench press',
        sets: _withWarmup(
          sets: 4,
          reps: 8,
          warmupReps: 10,
          weight: 60,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Overhead press',
        sets: _withWarmup(
          sets: 4,
          reps: 8,
          warmupReps: 10,
          weight: 40,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Incline dumbbell press',
        sets: _working(
          sets: 4,
          reps: 8,
          weight: 22.5,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Triceps pushdown',
        sets: _working(
          sets: 4,
          reps: 8,
          weight: 25,
          rest: const Duration(seconds: 75),
        ),
      ),
    ],
    meta: const {
      'kind': 'strength',
      'split': 'push',
      'template': 'push_day',
    },
  );

  static final WorkoutPlan pullDay = WorkoutPlan(
    id: 'tmpl_pull_day',
    name: 'Pull day — hypertrophy',
    description: 'Back, biceps, rear delts. 4x8 hypertrophy scheme.',
    exercises: [
      _with(
        'Deadlift',
        sets: _withWarmup(
          sets: 4,
          reps: 8,
          warmupReps: 6,
          weight: 100,
          rest: const Duration(seconds: 120),
        ),
      ),
      _with(
        'Barbell row',
        sets: _withWarmup(
          sets: 4,
          reps: 8,
          warmupReps: 10,
          weight: 60,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Lat pulldown',
        sets: _working(
          sets: 4,
          reps: 8,
          weight: 50,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Barbell curl',
        sets: _working(
          sets: 4,
          reps: 8,
          weight: 25,
          rest: const Duration(seconds: 75),
        ),
      ),
    ],
    meta: const {
      'kind': 'strength',
      'split': 'pull',
      'template': 'pull_day',
    },
  );

  static final WorkoutPlan legDay = WorkoutPlan(
    id: 'tmpl_leg_day',
    name: 'Leg day — hypertrophy',
    description: 'Quads, hamstrings, glutes. 4x8 hypertrophy scheme.',
    exercises: [
      _with(
        'Back squat',
        sets: _withWarmup(
          sets: 4,
          reps: 8,
          warmupReps: 8,
          weight: 80,
          rest: const Duration(seconds: 120),
        ),
      ),
      _with(
        'Romanian deadlift',
        sets: _withWarmup(
          sets: 4,
          reps: 8,
          warmupReps: 8,
          weight: 70,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Walking lunges',
        sets: _working(
          sets: 4,
          reps: 8,
          weight: 15,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Leg curl',
        sets: _working(
          sets: 4,
          reps: 8,
          weight: 35,
          rest: const Duration(seconds: 75),
        ),
      ),
    ],
    meta: const {
      'kind': 'strength',
      'split': 'legs',
      'template': 'leg_day',
    },
  );

  static final WorkoutPlan upperA = WorkoutPlan(
    id: 'tmpl_upper_a',
    name: 'Upper A',
    description: 'Mixed upper compound + isolation. 4x8.',
    exercises: [
      _with(
        'Bench press',
        sets: _withWarmup(
          sets: 4,
          reps: 8,
          warmupReps: 10,
          weight: 60,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Pull-ups',
        sets: _working(
          sets: 4,
          reps: 8,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Overhead press',
        sets: _withWarmup(
          sets: 4,
          reps: 8,
          warmupReps: 10,
          weight: 40,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Hammer curl',
        sets: _working(
          sets: 4,
          reps: 8,
          weight: 12.5,
          rest: const Duration(seconds: 60),
        ),
      ),
    ],
    meta: const {
      'kind': 'strength',
      'split': 'upper',
      'template': 'upper_a',
    },
  );

  static final WorkoutPlan lowerA = WorkoutPlan(
    id: 'tmpl_lower_a',
    name: 'Lower A — squat focus',
    description: 'Squat-focused lower body. 4x6 working sets.',
    exercises: [
      _with(
        'Back squat',
        sets: _withWarmup(
          sets: 4,
          reps: 6,
          warmupReps: 8,
          weight: 90,
          rest: const Duration(seconds: 150),
        ),
      ),
      _with(
        'Front squat',
        sets: _withWarmup(
          sets: 4,
          reps: 6,
          warmupReps: 8,
          weight: 60,
          rest: const Duration(seconds: 120),
        ),
      ),
      _with(
        'Leg press',
        sets: _working(
          sets: 4,
          reps: 6,
          weight: 140,
          rest: const Duration(seconds: 90),
        ),
      ),
      _with(
        'Standing calf raise',
        sets: _working(
          sets: 4,
          reps: 6,
          weight: 70,
          rest: const Duration(seconds: 60),
        ),
      ),
    ],
    meta: const {
      'kind': 'strength',
      'split': 'lower',
      'template': 'lower_a',
    },
  );

  static final WorkoutPlan fiveByFive = WorkoutPlan(
    id: 'tmpl_five_by_five',
    name: '5x5 strength',
    description: 'Squat, bench, row. 5x5 strength scheme, 3 min rest.',
    exercises: [
      _with(
        'Back squat',
        sets: _withWarmup(
          sets: 5,
          reps: 5,
          warmupReps: 5,
          weight: 80,
          rest: const Duration(minutes: 3),
        ),
      ),
      _with(
        'Bench press',
        sets: _withWarmup(
          sets: 5,
          reps: 5,
          warmupReps: 5,
          weight: 60,
          rest: const Duration(minutes: 3),
        ),
      ),
      _with(
        'Barbell row',
        sets: _withWarmup(
          sets: 5,
          reps: 5,
          warmupReps: 5,
          weight: 60,
          rest: const Duration(minutes: 3),
        ),
      ),
    ],
    meta: const {
      'kind': 'strength',
      'split': 'full-body',
      'scheme': '5x5',
      'template': 'five_by_five',
    },
  );

  static List<WorkoutPlan> get all => [
    fullBodyBeginner,
    pushDay,
    pullDay,
    legDay,
    upperA,
    lowerA,
    fiveByFive,
  ];
}
