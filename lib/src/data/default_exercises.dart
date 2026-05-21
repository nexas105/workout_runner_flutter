import '../models/exercise_category.dart';
import '../models/muscle.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'default_categories.dart';
import 'default_muscles.dart';

/// Catalogue of built-in [WorkoutExercise] templates. Use [DefaultExercises.all]
/// to get the full list, or one of the helpers like [byCategory] / [byMuscle].
class DefaultExercises {
  DefaultExercises._();

  static List<WorkoutSet> _defaultSets({
    int sets = 3,
    int reps = 10,
    double? weight,
    Duration rest = const Duration(seconds: 90),
  }) => List.generate(
    sets,
    (_) => WorkoutSet(targetReps: reps, targetWeight: weight, rest: rest),
  );

  static final List<WorkoutExercise> all = [
    // Strength — upper push
    WorkoutExercise(
      id: 'ex_bench_press',
      name: 'Bench press',
      category: DefaultCategories.strength,
      muscles: const [
        DefaultMuscles.chest,
        DefaultMuscles.triceps,
        DefaultMuscles.shoulders,
      ],
      sets: _defaultSets(reps: 8, weight: 60),
    ),
    WorkoutExercise(
      id: 'ex_incline_db_press',
      name: 'Incline dumbbell press',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.chest, DefaultMuscles.shoulders],
      sets: _defaultSets(reps: 10, weight: 22.5),
    ),
    WorkoutExercise(
      id: 'ex_ohp',
      name: 'Overhead press',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.shoulders, DefaultMuscles.triceps],
      sets: _defaultSets(reps: 8, weight: 40),
    ),
    WorkoutExercise(
      id: 'ex_dips',
      name: 'Dips',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.triceps, DefaultMuscles.chest],
      sets: _defaultSets(reps: 10),
    ),
    WorkoutExercise(
      id: 'ex_pushups',
      name: 'Push-ups',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.chest, DefaultMuscles.triceps],
      sets: _defaultSets(reps: 15),
    ),

    // Strength — upper pull
    WorkoutExercise(
      id: 'ex_pullups',
      name: 'Pull-ups',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.lats, DefaultMuscles.biceps],
      sets: _defaultSets(reps: 8),
    ),
    WorkoutExercise(
      id: 'ex_barbell_row',
      name: 'Barbell row',
      category: DefaultCategories.strength,
      muscles: const [
        DefaultMuscles.upperBack,
        DefaultMuscles.lats,
        DefaultMuscles.biceps,
      ],
      sets: _defaultSets(reps: 8, weight: 60),
    ),
    WorkoutExercise(
      id: 'ex_lat_pulldown',
      name: 'Lat pulldown',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.lats, DefaultMuscles.biceps],
      sets: _defaultSets(reps: 10, weight: 50),
    ),
    WorkoutExercise(
      id: 'ex_face_pulls',
      name: 'Face pulls',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.rearDelts, DefaultMuscles.upperBack],
      sets: _defaultSets(reps: 15, weight: 20),
    ),

    // Strength — arms
    WorkoutExercise(
      id: 'ex_barbell_curl',
      name: 'Barbell curl',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.biceps],
      sets: _defaultSets(reps: 10, weight: 25),
    ),
    WorkoutExercise(
      id: 'ex_hammer_curl',
      name: 'Hammer curl',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.biceps, DefaultMuscles.forearms],
      sets: _defaultSets(reps: 12, weight: 12.5),
    ),
    WorkoutExercise(
      id: 'ex_triceps_pushdown',
      name: 'Triceps pushdown',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.triceps],
      sets: _defaultSets(reps: 12, weight: 25),
    ),

    // Strength — legs
    WorkoutExercise(
      id: 'ex_squat',
      name: 'Back squat',
      category: DefaultCategories.strength,
      muscles: const [
        DefaultMuscles.quads,
        DefaultMuscles.glutes,
        DefaultMuscles.hamstrings,
      ],
      sets: _defaultSets(reps: 6, weight: 80),
    ),
    WorkoutExercise(
      id: 'ex_front_squat',
      name: 'Front squat',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.quads, DefaultMuscles.glutes],
      sets: _defaultSets(reps: 6, weight: 60),
    ),
    WorkoutExercise(
      id: 'ex_deadlift',
      name: 'Deadlift',
      category: DefaultCategories.strength,
      muscles: const [
        DefaultMuscles.hamstrings,
        DefaultMuscles.glutes,
        DefaultMuscles.lowerBack,
      ],
      sets: _defaultSets(sets: 3, reps: 5, weight: 100),
    ),
    WorkoutExercise(
      id: 'ex_rdl',
      name: 'Romanian deadlift',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.hamstrings, DefaultMuscles.glutes],
      sets: _defaultSets(reps: 8, weight: 70),
    ),
    WorkoutExercise(
      id: 'ex_lunges',
      name: 'Walking lunges',
      category: DefaultCategories.strength,
      muscles: const [
        DefaultMuscles.quads,
        DefaultMuscles.glutes,
        DefaultMuscles.hamstrings,
      ],
      sets: _defaultSets(reps: 12, weight: 15),
    ),
    WorkoutExercise(
      id: 'ex_hip_thrust',
      name: 'Hip thrust',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.glutes, DefaultMuscles.hamstrings],
      sets: _defaultSets(reps: 10, weight: 80),
    ),
    WorkoutExercise(
      id: 'ex_leg_press',
      name: 'Leg press',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.quads, DefaultMuscles.glutes],
      sets: _defaultSets(reps: 12, weight: 120),
    ),
    WorkoutExercise(
      id: 'ex_leg_curl',
      name: 'Leg curl',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.hamstrings],
      sets: _defaultSets(reps: 12, weight: 35),
    ),
    WorkoutExercise(
      id: 'ex_calf_raise',
      name: 'Standing calf raise',
      category: DefaultCategories.strength,
      muscles: const [DefaultMuscles.calves],
      sets: _defaultSets(reps: 15, weight: 50),
    ),

    // Core
    WorkoutExercise(
      id: 'ex_plank',
      name: 'Plank',
      category: DefaultCategories.core,
      muscles: const [DefaultMuscles.abs, DefaultMuscles.lowerBack],
      sets: _defaultSets(reps: 1, rest: Duration(seconds: 45)),
    ),
    WorkoutExercise(
      id: 'ex_crunches',
      name: 'Crunches',
      category: DefaultCategories.core,
      muscles: const [DefaultMuscles.abs],
      sets: _defaultSets(reps: 20),
    ),
    WorkoutExercise(
      id: 'ex_russian_twist',
      name: 'Russian twist',
      category: DefaultCategories.core,
      muscles: const [DefaultMuscles.obliques, DefaultMuscles.abs],
      sets: _defaultSets(reps: 30),
    ),
    WorkoutExercise(
      id: 'ex_hanging_leg_raise',
      name: 'Hanging leg raise',
      category: DefaultCategories.core,
      muscles: const [DefaultMuscles.abs],
      sets: _defaultSets(reps: 10),
    ),

    // HIIT
    WorkoutExercise(
      id: 'ex_burpees',
      name: 'Burpees',
      category: DefaultCategories.hiit,
      muscles: const [
        DefaultMuscles.chest,
        DefaultMuscles.quads,
        DefaultMuscles.shoulders,
      ],
      sets: _defaultSets(reps: 10, rest: Duration(seconds: 30)),
    ),
    WorkoutExercise(
      id: 'ex_kettlebell_swing',
      name: 'Kettlebell swing',
      category: DefaultCategories.hiit,
      muscles: const [DefaultMuscles.glutes, DefaultMuscles.hamstrings],
      sets: _defaultSets(reps: 20, weight: 16),
    ),
    WorkoutExercise(
      id: 'ex_box_jump',
      name: 'Box jump',
      category: DefaultCategories.hiit,
      muscles: const [DefaultMuscles.quads, DefaultMuscles.glutes],
      sets: _defaultSets(reps: 10),
    ),
    WorkoutExercise(
      id: 'ex_battle_ropes',
      name: 'Battle ropes',
      category: DefaultCategories.hiit,
      muscles: const [DefaultMuscles.shoulders, DefaultMuscles.forearms],
      sets: _defaultSets(reps: 30, rest: Duration(seconds: 30)),
    ),

    // Cardio
    WorkoutExercise(
      id: 'ex_running',
      name: 'Running',
      category: DefaultCategories.cardio,
      muscles: const [DefaultMuscles.quads, DefaultMuscles.calves],
      sets: _defaultSets(sets: 1, reps: 1, rest: Duration(seconds: 0)),
    ),
    WorkoutExercise(
      id: 'ex_rowing',
      name: 'Rowing machine',
      category: DefaultCategories.cardio,
      muscles: const [DefaultMuscles.upperBack, DefaultMuscles.lats],
      sets: _defaultSets(sets: 1, reps: 1, rest: Duration(seconds: 0)),
    ),
    WorkoutExercise(
      id: 'ex_cycling',
      name: 'Cycling',
      category: DefaultCategories.cardio,
      muscles: const [DefaultMuscles.quads, DefaultMuscles.calves],
      sets: _defaultSets(sets: 1, reps: 1, rest: Duration(seconds: 0)),
    ),
    WorkoutExercise(
      id: 'ex_jump_rope',
      name: 'Jump rope',
      category: DefaultCategories.cardio,
      muscles: const [DefaultMuscles.calves],
      sets: _defaultSets(sets: 3, reps: 1, rest: Duration(seconds: 30)),
    ),

    // Mobility
    WorkoutExercise(
      id: 'ex_sun_salutation',
      name: 'Yoga — sun salutation',
      category: DefaultCategories.mobility,
      muscles: const [
        DefaultMuscles.abs,
        DefaultMuscles.lowerBack,
        DefaultMuscles.shoulders,
      ],
      sets: _defaultSets(sets: 2, reps: 5, rest: Duration(seconds: 15)),
    ),
    WorkoutExercise(
      id: 'ex_static_stretch',
      name: 'Static stretching',
      category: DefaultCategories.mobility,
      sets: _defaultSets(sets: 1, reps: 1, rest: Duration(seconds: 0)),
    ),
  ];

  static WorkoutExercise? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  static List<WorkoutExercise> byCategory(ExerciseCategory category) =>
      all.where((e) => e.category?.id == category.id).toList();

  static List<WorkoutExercise> byMuscle(Muscle muscle) =>
      all.where((e) => e.muscles.any((m) => m.id == muscle.id)).toList();

  static List<WorkoutExercise> byMuscleGroup(String group) {
    final g = group.trim().toLowerCase();
    return all
        .where((e) => e.muscles.any((m) => (m.group ?? '').toLowerCase() == g))
        .toList();
  }

  static List<WorkoutExercise> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return all.where((e) => e.name.toLowerCase().contains(q)).toList();
  }
}
