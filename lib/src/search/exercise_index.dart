import '../models/workout_exercise.dart';

class ExerciseIndex {
  final List<WorkoutExercise> source;

  final Map<String, WorkoutExercise> _byId = {};
  final Map<String, List<WorkoutExercise>> _byMuscleId = {};
  final Map<String, List<WorkoutExercise>> _byMuscleGroup = {};
  final Map<String, List<WorkoutExercise>> _byCategoryId = {};
  final Map<String, List<WorkoutExercise>> _byEquipment = {};
  final Map<String, List<WorkoutExercise>> _byNamePrefix = {};

  ExerciseIndex(this.source) {
    for (final ex in source) {
      _byId[ex.id] = ex;

      final seenMuscleIds = <String>{};
      final seenMuscleGroups = <String>{};
      for (final m in ex.muscles) {
        if (seenMuscleIds.add(m.id)) {
          (_byMuscleId[m.id] ??= <WorkoutExercise>[]).add(ex);
        }
        final group = m.group;
        if (group != null && seenMuscleGroups.add(group)) {
          (_byMuscleGroup[group] ??= <WorkoutExercise>[]).add(ex);
        }
      }

      final cat = ex.category;
      if (cat != null) {
        (_byCategoryId[cat.id] ??= <WorkoutExercise>[]).add(ex);
      }

      final equipment = ex.meta?['equipment'];
      if (equipment is String && equipment.isNotEmpty) {
        (_byEquipment[equipment] ??= <WorkoutExercise>[]).add(ex);
      } else if (equipment is Iterable) {
        final seenEquip = <String>{};
        for (final e in equipment) {
          if (e is String && e.isNotEmpty && seenEquip.add(e)) {
            (_byEquipment[e] ??= <WorkoutExercise>[]).add(ex);
          }
        }
      }

      final name = ex.name.toLowerCase();
      if (name.isNotEmpty) {
        final prefix = name.length >= 3 ? name.substring(0, 3) : name;
        (_byNamePrefix[prefix] ??= <WorkoutExercise>[]).add(ex);
      }
    }
  }

  WorkoutExercise? byId(String id) => _byId[id];

  List<WorkoutExercise> byMuscle(String muscleId) =>
      List.unmodifiable(_byMuscleId[muscleId] ?? const <WorkoutExercise>[]);

  List<WorkoutExercise> byMuscleGroup(String group) =>
      List.unmodifiable(_byMuscleGroup[group] ?? const <WorkoutExercise>[]);

  List<WorkoutExercise> byCategory(String categoryId) =>
      List.unmodifiable(_byCategoryId[categoryId] ?? const <WorkoutExercise>[]);

  List<WorkoutExercise> byEquipment(String equipment) =>
      List.unmodifiable(_byEquipment[equipment] ?? const <WorkoutExercise>[]);

  List<WorkoutExercise> byPrefix(String prefix) {
    if (prefix.isEmpty) return const <WorkoutExercise>[];
    final lower = prefix.toLowerCase();
    final key = lower.length >= 3 ? lower.substring(0, 3) : lower;
    if (key.length < 3) {
      final out = <WorkoutExercise>[];
      final seen = <String>{};
      for (final entry in _byNamePrefix.entries) {
        if (entry.key.startsWith(key)) {
          for (final ex in entry.value) {
            if (seen.add(ex.id)) out.add(ex);
          }
        }
      }
      return List.unmodifiable(out);
    }
    return List.unmodifiable(_byNamePrefix[key] ?? const <WorkoutExercise>[]);
  }

  Iterable<String> get muscleIds => _byMuscleId.keys;
  Iterable<String> get muscleGroups => _byMuscleGroup.keys;
  Iterable<String> get categoryIds => _byCategoryId.keys;
  Iterable<String> get equipmentTypes => _byEquipment.keys;
}

class CatalogSnapshot {
  final ExerciseIndex index;
  final DateTime builtAt;

  CatalogSnapshot({required this.index, required this.builtAt});

  factory CatalogSnapshot.from(List<WorkoutExercise> source) => CatalogSnapshot(
    index: ExerciseIndex(source),
    builtAt: DateTime.now(),
  );
}
