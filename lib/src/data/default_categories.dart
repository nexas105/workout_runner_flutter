import '../models/exercise_category.dart';

/// Built-in [ExerciseCategory] presets. Apps may use these directly or
/// supply their own list.
class DefaultCategories {
  DefaultCategories._();

  static const ExerciseCategory strength = ExerciseCategory(
    id: 'cat_strength',
    name: 'Strength',
    description:
        'Resistance training with weights or bodyweight to build force and muscle.',
  );

  static const ExerciseCategory cardio = ExerciseCategory(
    id: 'cat_cardio',
    name: 'Cardio',
    description: 'Cardiovascular training (running, cycling, rowing, …).',
  );

  static const ExerciseCategory mobility = ExerciseCategory(
    id: 'cat_mobility',
    name: 'Mobility',
    description: 'Stretching, yoga, mobility drills.',
  );

  static const ExerciseCategory core = ExerciseCategory(
    id: 'cat_core',
    name: 'Core',
    description: 'Trunk stability and abdominal work.',
  );

  static const ExerciseCategory hiit = ExerciseCategory(
    id: 'cat_hiit',
    name: 'HIIT',
    description: 'High-intensity interval training.',
  );

  static const List<ExerciseCategory> all = [
    strength,
    cardio,
    mobility,
    core,
    hiit,
  ];

  static ExerciseCategory? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static ExerciseCategory? byName(String name) {
    final n = name.trim().toLowerCase();
    for (final c in all) {
      if (c.name.toLowerCase() == n) return c;
    }
    return null;
  }
}
