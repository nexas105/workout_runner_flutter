import '../models/cardio/cardio_plan.dart';
import '../models/exercise_category.dart';
import '../models/muscle.dart';
import '../models/workout_exercise.dart';
import '../models/workout_plan.dart';
import '../storage/custom_entity_registry.dart';
import 'default_cardio_plans.dart';
import 'default_categories.dart';
import 'default_exercises.dart';
import 'default_muscles.dart';
import 'default_plans.dart';

/// Reads the bundled `Default*` catalogues and overlays user-defined entries
/// from a [CustomEntityRegistry] on top. Custom entries WIN over defaults
/// with the same id (so a user can shadow / override a bundled exercise).
///
/// Reads are pull-on-demand; for snappier UI wire a `CatalogSnapshot` on top.
class Catalog {
  Catalog(this.registry);

  final CustomEntityRegistry registry;

  Future<List<WorkoutExercise>> exercises() async {
    final custom = await registry.readAll(CustomEntityKinds.exercises);
    return _merge<WorkoutExercise>(
      DefaultExercises.all,
      custom.map(WorkoutExercise.fromJson),
      (e) => e.id,
    );
  }

  Future<List<Muscle>> muscles() async {
    final custom = await registry.readAll(CustomEntityKinds.muscles);
    return _merge<Muscle>(
      DefaultMuscles.all,
      custom.map(Muscle.fromJson),
      (m) => m.id,
    );
  }

  Future<List<ExerciseCategory>> categories() async {
    final custom = await registry.readAll(CustomEntityKinds.categories);
    return _merge<ExerciseCategory>(
      DefaultCategories.all,
      custom.map(ExerciseCategory.fromJson),
      (c) => c.id,
    );
  }

  Future<List<WorkoutPlan>> plans() async {
    final custom = await registry.readAll(CustomEntityKinds.plans);
    return _merge<WorkoutPlan>(
      DefaultPlans.all,
      custom.map(WorkoutPlan.fromJson),
      (p) => p.id,
    );
  }

  Future<List<CardioPlan>> cardioPlans() async {
    final custom = await registry.readAll(CustomEntityKinds.cardioPlans);
    return _merge<CardioPlan>(
      DefaultCardioPlans.all,
      custom.map(CardioPlan.fromJson),
      (p) => p.id,
    );
  }

  static List<T> _merge<T>(
    Iterable<T> defaults,
    Iterable<T> custom,
    String Function(T) idOf,
  ) {
    final shadowed = <String, T>{for (final c in custom) idOf(c): c};
    return [
      for (final d in defaults)
        if (shadowed.containsKey(idOf(d))) shadowed.remove(idOf(d))! else d,
      ...shadowed.values,
    ];
  }
}
