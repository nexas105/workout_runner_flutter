import '../models/muscle.dart';

/// Built-in [Muscle] presets with English names and a coarse group split
/// (upper / lower / core).
class DefaultMuscles {
  DefaultMuscles._();

  // Upper body
  static const Muscle chest = Muscle(
    id: 'm_chest',
    name: 'Chest',
    group: 'upper',
  );
  static const Muscle shoulders = Muscle(
    id: 'm_shoulders',
    name: 'Shoulders',
    group: 'upper',
  );
  static const Muscle rearDelts = Muscle(
    id: 'm_rear_delts',
    name: 'Rear delts',
    group: 'upper',
  );
  static const Muscle triceps = Muscle(
    id: 'm_triceps',
    name: 'Triceps',
    group: 'upper',
  );
  static const Muscle biceps = Muscle(
    id: 'm_biceps',
    name: 'Biceps',
    group: 'upper',
  );
  static const Muscle forearms = Muscle(
    id: 'm_forearms',
    name: 'Forearms',
    group: 'upper',
  );
  static const Muscle lats = Muscle(id: 'm_lats', name: 'Lats', group: 'upper');
  static const Muscle traps = Muscle(
    id: 'm_traps',
    name: 'Traps',
    group: 'upper',
  );
  static const Muscle upperBack = Muscle(
    id: 'm_upper_back',
    name: 'Upper back',
    group: 'upper',
  );

  // Core
  static const Muscle abs = Muscle(id: 'm_abs', name: 'Abs', group: 'core');
  static const Muscle obliques = Muscle(
    id: 'm_obliques',
    name: 'Obliques',
    group: 'core',
  );
  static const Muscle lowerBack = Muscle(
    id: 'm_lower_back',
    name: 'Lower back',
    group: 'core',
  );

  // Lower body
  static const Muscle quads = Muscle(
    id: 'm_quads',
    name: 'Quads',
    group: 'lower',
  );
  static const Muscle hamstrings = Muscle(
    id: 'm_hamstrings',
    name: 'Hamstrings',
    group: 'lower',
  );
  static const Muscle glutes = Muscle(
    id: 'm_glutes',
    name: 'Glutes',
    group: 'lower',
  );
  static const Muscle calves = Muscle(
    id: 'm_calves',
    name: 'Calves',
    group: 'lower',
  );
  static const Muscle adductors = Muscle(
    id: 'm_adductors',
    name: 'Adductors',
    group: 'lower',
  );
  static const Muscle abductors = Muscle(
    id: 'm_abductors',
    name: 'Abductors',
    group: 'lower',
  );

  static const List<Muscle> all = [
    chest,
    shoulders,
    rearDelts,
    triceps,
    biceps,
    forearms,
    lats,
    traps,
    upperBack,
    abs,
    obliques,
    lowerBack,
    quads,
    hamstrings,
    glutes,
    calves,
    adductors,
    abductors,
  ];

  static Muscle? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  static Muscle? byName(String name) {
    final n = name.trim().toLowerCase();
    for (final m in all) {
      if (m.name.toLowerCase() == n) return m;
    }
    return null;
  }

  /// Muscles in a coarse group ("upper", "core", "lower").
  static List<Muscle> byGroup(String group) {
    final g = group.trim().toLowerCase();
    return all.where((m) => (m.group ?? '').toLowerCase() == g).toList();
  }
}
