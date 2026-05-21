/// Equipment a `WorkoutExercise` needs. Free-form string id matches what the
/// `EquipmentItem` enum from `lib/src/intelligence/equipment_profile.dart`
/// uses, so a user's `EquipmentProfile.idSet` filters against this directly.
enum ExerciseEquipment {
  barbell,
  dumbbell,
  kettlebell,
  machine,
  cable,
  bodyweight,
  bands,
  bench,
  rack,
  pullupBar,
  medball,
  other,
}

extension ExerciseEquipmentId on ExerciseEquipment {
  String get id => name;

  static ExerciseEquipment fromId(String? raw) {
    if (raw == null) return ExerciseEquipment.other;
    return ExerciseEquipment.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ExerciseEquipment.other,
    );
  }
}

/// Coarse-grained movement pattern. Drives substitution suggestions,
/// programming heuristics and filter chips in editor screens.
enum MovementPattern { push, pull, squat, hinge, lunge, carry, core, rotation }

extension MovementPatternId on MovementPattern {
  String get id => name;

  static MovementPattern? fromId(String? raw) {
    if (raw == null) return null;
    for (final v in MovementPattern.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

/// Rough difficulty bucket — apps can use it to filter exercise pickers or
/// gate beginners away from advanced moves. Not a substitute for coaching.
enum ExerciseDifficulty { beginner, intermediate, advanced }

extension ExerciseDifficultyId on ExerciseDifficulty {
  String get id => name;

  static ExerciseDifficulty? fromId(String? raw) {
    if (raw == null) return null;
    for (final v in ExerciseDifficulty.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
