import '../models/workout_exercise.dart';

class ExerciseAlternativeGroup {
  final WorkoutExercise source;
  final List<WorkoutExercise> alternatives;

  ExerciseAlternativeGroup({required this.source, required this.alternatives});

  @override
  String toString() =>
      'ExerciseAlternativeGroup(source: ${source.id}, '
      'alternatives: ${alternatives.map((e) => e.id).toList()})';
}

enum AlternativeMatch {
  sameMovementSameEquipment,
  sameMovementDifferentEquipment,
  sameMuscleGroup,
  sameCategoryFallback,
}

class ScoredAlternative {
  final WorkoutExercise exercise;
  final double score;
  final AlternativeMatch match;
  final String reason;

  ScoredAlternative({
    required this.exercise,
    required this.score,
    required this.match,
    required this.reason,
  });

  @override
  String toString() =>
      'ScoredAlternative(${exercise.id}, score: $score, '
      'match: $match, reason: $reason)';
}

abstract class ExerciseAlternatives {
  static List<ScoredAlternative> forExercise(
    WorkoutExercise source,
    List<WorkoutExercise> catalog, {
    int limit = 5,
    Set<String>? availableEquipment,
  }) {
    if (limit <= 0) return const [];

    final sourceMovement = _metaLower(source, 'movementPattern');
    final sourceEquipment = _metaLower(source, 'equipment');
    final sourceMuscleIds = source.muscles.map((m) => m.id).toSet();
    final sourceMuscleGroups = source.muscles
        .map((m) => m.group)
        .whereType<String>()
        .map((g) => g.toLowerCase())
        .toSet();
    final sourceCategoryId = source.category?.id;

    final availableLower = availableEquipment
        ?.map((e) => e.toLowerCase())
        .toSet();

    final scored = <ScoredAlternative>[];

    for (final candidate in catalog) {
      if (candidate.id == source.id) continue;

      final candidateEquipment = _metaLower(candidate, 'equipment');
      if (availableLower != null &&
          candidateEquipment != null &&
          !availableLower.contains(candidateEquipment)) {
        continue;
      }

      final candidateMovement = _metaLower(candidate, 'movementPattern');
      final candidateMuscleIds = candidate.muscles.map((m) => m.id).toSet();
      final candidateMuscleGroups = candidate.muscles
          .map((m) => m.group)
          .whereType<String>()
          .map((g) => g.toLowerCase())
          .toSet();

      ScoredAlternative? entry;

      if (sourceMovement != null &&
          candidateMovement != null &&
          sourceMovement == candidateMovement) {
        if (sourceEquipment != null &&
            candidateEquipment != null &&
            sourceEquipment == candidateEquipment) {
          entry = ScoredAlternative(
            exercise: candidate,
            score: 1.0,
            match: AlternativeMatch.sameMovementSameEquipment,
            reason: 'Same movement pattern and equipment',
          );
        } else {
          entry = ScoredAlternative(
            exercise: candidate,
            score: 0.8,
            match: AlternativeMatch.sameMovementDifferentEquipment,
            reason: 'Same movement pattern, different equipment',
          );
        }
      } else {
        final sharedMuscles =
            sourceMuscleIds.intersection(candidateMuscleIds).isNotEmpty ||
            sourceMuscleGroups.intersection(candidateMuscleGroups).isNotEmpty;
        if (sharedMuscles) {
          entry = ScoredAlternative(
            exercise: candidate,
            score: 0.6,
            match: AlternativeMatch.sameMuscleGroup,
            reason: 'Shared muscle group',
          );
        } else if (sourceCategoryId != null &&
            candidate.category?.id == sourceCategoryId) {
          entry = ScoredAlternative(
            exercise: candidate,
            score: 0.3,
            match: AlternativeMatch.sameCategoryFallback,
            reason: 'Same category',
          );
        }
      }

      if (entry != null) scored.add(entry);
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.exercise.name.toLowerCase().compareTo(
        b.exercise.name.toLowerCase(),
      );
    });

    if (scored.length > limit) {
      return scored.sublist(0, limit);
    }
    return scored;
  }

  static ExerciseAlternativeGroup group(
    WorkoutExercise source,
    List<WorkoutExercise> catalog, {
    Set<String>? availableEquipment,
  }) {
    final scored = forExercise(
      source,
      catalog,
      availableEquipment: availableEquipment,
    );
    return ExerciseAlternativeGroup(
      source: source,
      alternatives: scored.map((s) => s.exercise).toList(growable: false),
    );
  }

  static String? _metaLower(WorkoutExercise exercise, String key) {
    final meta = exercise.meta;
    if (meta == null) return null;
    final value = meta[key];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed.toLowerCase();
    }
    return null;
  }
}
