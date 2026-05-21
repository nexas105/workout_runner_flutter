import '../models/workout_exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_set.dart';
import 'default_exercises.dart';

/// Built-in [WorkoutPlan]s composed from [DefaultExercises]. Useful for demos,
/// onboarding flows, or as a starting point when the user has not yet created
/// their own plans.
///
/// All entries reuse exercise templates from [DefaultExercises], so muscle
/// and category metadata stays consistent. Set targets are overridden per plan
/// (e.g. a hypertrophy push day uses different rep ranges than a beginner
/// full-body plan).
class DefaultPlans {
  DefaultPlans._();

  static WorkoutExercise _withSets(
    WorkoutExercise template, {
    int sets = 3,
    int reps = 10,
    double? weight,
    Duration rest = const Duration(seconds: 90),
  }) => template.copyWith(
    sets: List.generate(
      sets,
      (_) => WorkoutSet(targetReps: reps, targetWeight: weight, rest: rest),
    ),
  );

  static WorkoutExercise _byId(String id) {
    final ex = DefaultExercises.byId(id);
    assert(ex != null, 'Missing default exercise: $id');
    return ex!;
  }

  /// Classic upper-body push session (chest / shoulders / triceps).
  static final WorkoutPlan pushDay = WorkoutPlan(
    id: 'plan_push_day',
    name: 'Push day',
    description: 'Chest, shoulders, triceps — hypertrophy focus.',
    exercises: [
      _withSets(_byId('ex_bench_press'), sets: 4, reps: 8, weight: 60),
      _withSets(_byId('ex_incline_db_press'), sets: 3, reps: 10, weight: 22.5),
      _withSets(_byId('ex_ohp'), sets: 3, reps: 8, weight: 40),
      _withSets(_byId('ex_dips'), sets: 3, reps: 10),
      _withSets(_byId('ex_triceps_pushdown'), sets: 3, reps: 12, weight: 25),
    ],
    meta: const {'kind': 'strength', 'split': 'push'},
  );

  /// Classic upper-body pull session (back / biceps / rear delts).
  static final WorkoutPlan pullDay = WorkoutPlan(
    id: 'plan_pull_day',
    name: 'Pull day',
    description: 'Back, biceps, rear delts.',
    exercises: [
      _withSets(_byId('ex_pullups'), sets: 4, reps: 8),
      _withSets(_byId('ex_barbell_row'), sets: 4, reps: 8, weight: 60),
      _withSets(_byId('ex_lat_pulldown'), sets: 3, reps: 10, weight: 50),
      _withSets(_byId('ex_face_pulls'), sets: 3, reps: 15, weight: 20),
      _withSets(_byId('ex_barbell_curl'), sets: 3, reps: 10, weight: 25),
      _withSets(_byId('ex_hammer_curl'), sets: 3, reps: 12, weight: 12.5),
    ],
    meta: const {'kind': 'strength', 'split': 'pull'},
  );

  /// Lower-body strength day (quads / glutes / hamstrings / calves).
  static final WorkoutPlan legDay = WorkoutPlan(
    id: 'plan_leg_day',
    name: 'Leg day',
    description: 'Quads, glutes, hamstrings, calves.',
    exercises: [
      _withSets(_byId('ex_squat'), sets: 4, reps: 6, weight: 80),
      _withSets(_byId('ex_rdl'), sets: 3, reps: 8, weight: 70),
      _withSets(_byId('ex_leg_press'), sets: 3, reps: 12, weight: 120),
      _withSets(_byId('ex_lunges'), sets: 3, reps: 12, weight: 15),
      _withSets(_byId('ex_leg_curl'), sets: 3, reps: 12, weight: 35),
      _withSets(_byId('ex_calf_raise'), sets: 4, reps: 15, weight: 50),
    ],
    meta: const {'kind': 'strength', 'split': 'legs'},
  );

  /// Beginner full-body plan — short, low volume, no machines.
  static final WorkoutPlan fullBodyBeginner = WorkoutPlan(
    id: 'plan_full_body_beginner',
    name: 'Full body — beginner',
    description: 'Three sets each, light loads. Good first session.',
    exercises: [
      _withSets(_byId('ex_squat'), sets: 3, reps: 8, weight: 40),
      _withSets(_byId('ex_pushups'), sets: 3, reps: 10),
      _withSets(_byId('ex_barbell_row'), sets: 3, reps: 10, weight: 30),
      _withSets(
        _byId('ex_plank'),
        sets: 3,
        reps: 1,
        rest: const Duration(seconds: 45),
      ),
    ],
    meta: const {'kind': 'strength', 'split': 'full-body', 'level': 'beginner'},
  );

  /// Five-move core burn — no equipment.
  static final WorkoutPlan coreBurn = WorkoutPlan(
    id: 'plan_core_burn',
    name: 'Core burn',
    description: 'Short trunk-stability session.',
    exercises: [
      _withSets(
        _byId('ex_plank'),
        sets: 3,
        reps: 1,
        rest: const Duration(seconds: 30),
      ),
      _withSets(
        _byId('ex_crunches'),
        sets: 3,
        reps: 20,
        rest: const Duration(seconds: 30),
      ),
      _withSets(
        _byId('ex_russian_twist'),
        sets: 3,
        reps: 30,
        rest: const Duration(seconds: 30),
      ),
      _withSets(
        _byId('ex_hanging_leg_raise'),
        sets: 3,
        reps: 10,
        rest: const Duration(seconds: 45),
      ),
    ],
    meta: const {'kind': 'strength', 'split': 'core'},
  );

  /// HIIT circuit — short rest, high-effort moves.
  static final WorkoutPlan hiitCircuit = WorkoutPlan(
    id: 'plan_hiit_circuit',
    name: 'HIIT circuit',
    description: 'Four-move circuit. Three rounds, 30 s rest.',
    exercises: [
      _withSets(
        _byId('ex_burpees'),
        sets: 3,
        reps: 10,
        rest: const Duration(seconds: 30),
      ),
      _withSets(
        _byId('ex_kettlebell_swing'),
        sets: 3,
        reps: 20,
        weight: 16,
        rest: const Duration(seconds: 30),
      ),
      _withSets(
        _byId('ex_box_jump'),
        sets: 3,
        reps: 10,
        rest: const Duration(seconds: 30),
      ),
      _withSets(
        _byId('ex_battle_ropes'),
        sets: 3,
        reps: 30,
        rest: const Duration(seconds: 30),
      ),
    ],
    meta: const {'kind': 'hiit'},
  );

  /// Light mobility / recovery flow — no targets to chase.
  static final WorkoutPlan mobilityFlow = WorkoutPlan(
    id: 'plan_mobility_flow',
    name: 'Mobility flow',
    description: 'Recovery and stretching.',
    exercises: [
      _withSets(
        _byId('ex_sun_salutation'),
        sets: 2,
        reps: 5,
        rest: const Duration(seconds: 15),
      ),
      _withSets(
        _byId('ex_static_stretch'),
        sets: 1,
        reps: 1,
        rest: Duration.zero,
      ),
    ],
    meta: const {'kind': 'mobility'},
  );

  /// Full preset catalogue.
  static final List<WorkoutPlan> all = [
    pushDay,
    pullDay,
    legDay,
    fullBodyBeginner,
    coreBurn,
    hiitCircuit,
    mobilityFlow,
  ];

  static WorkoutPlan? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Filter plans by their `meta['kind']` tag (`strength`, `hiit`, `mobility`).
  static List<WorkoutPlan> byKind(String kind) {
    final k = kind.trim().toLowerCase();
    return all
        .where((p) => (p.meta?['kind'] as String?)?.toLowerCase() == k)
        .toList();
  }
}
