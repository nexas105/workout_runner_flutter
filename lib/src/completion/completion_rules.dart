import '../models/workout_plan.dart';
import '../models/workout_result.dart';

enum WorkoutCompletionStatus { completed, partial, cancelled, abandoned }

abstract class CompletionRule {
  const CompletionRule();

  String get name;

  bool isCompletedBy(WorkoutResult result, WorkoutPlan plan);
}

class AllSetsCompletionRule extends CompletionRule {
  const AllSetsCompletionRule();

  @override
  String get name => 'all_sets';

  @override
  bool isCompletedBy(WorkoutResult result, WorkoutPlan plan) {
    if (plan.totalTargetSets == 0) return true;
    for (var exIdx = 0; exIdx < plan.exercises.length; exIdx++) {
      final planEx = plan.exercises[exIdx];
      final performedEx = _matchPerformed(result, planEx.id, exIdx);
      if (performedEx == null) return false;
      for (var sIdx = 0; sIdx < planEx.sets.length; sIdx++) {
        final hit = performedEx.sets.any(
          (s) => s.setIndex == sIdx && s.actualReps > 0,
        );
        if (!hit) return false;
      }
    }
    return true;
  }
}

class MinimumSetsCompletionRule extends CompletionRule {
  final int minimum;

  const MinimumSetsCompletionRule(this.minimum);

  @override
  String get name => 'minimum_sets';

  @override
  bool isCompletedBy(WorkoutResult result, WorkoutPlan plan) {
    final performed = _countPerformedSets(result);
    return performed >= minimum;
  }
}

class FreeSessionCompletionRule extends CompletionRule {
  const FreeSessionCompletionRule();

  @override
  String get name => 'free_session';

  @override
  bool isCompletedBy(WorkoutResult result, WorkoutPlan plan) => true;
}

class RequiredExercisesCompletionRule extends CompletionRule {
  final List<String> exerciseIds;

  const RequiredExercisesCompletionRule(this.exerciseIds);

  @override
  String get name => 'required_exercises';

  @override
  bool isCompletedBy(WorkoutResult result, WorkoutPlan plan) {
    for (final id in exerciseIds) {
      final performed = result.exercises.where((e) => e.exerciseId == id);
      final any = performed.any((e) => e.sets.any((s) => s.actualReps > 0));
      if (!any) return false;
    }
    return true;
  }
}

class CompletionEvaluation {
  final WorkoutCompletionStatus status;
  final double ratio;
  final List<String> missingExerciseIds;

  const CompletionEvaluation({
    required this.status,
    required this.ratio,
    required this.missingExerciseIds,
  });

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'ratio': ratio,
    'missingExerciseIds': missingExerciseIds,
  };

  factory CompletionEvaluation.fromJson(Map<String, dynamic> json) =>
      CompletionEvaluation(
        status: WorkoutCompletionStatus.values.firstWhere(
          (s) => s.name == json['status'] as String,
        ),
        ratio: (json['ratio'] as num).toDouble(),
        missingExerciseIds:
            (json['missingExerciseIds'] as List<dynamic>)
                .map((e) => e as String)
                .toList(),
      );
}

abstract class WorkoutCompletion {
  static CompletionEvaluation evaluate(
    WorkoutResult result,
    WorkoutPlan plan,
    CompletionRule rule,
  ) {
    final performedSets = _countPerformedSets(result);
    final planned = plan.totalTargetSets;
    final ratio = planned == 0 ? 1.0 : (performedSets / planned).clamp(0.0, 1.0);
    final missing = _missingExerciseIds(result, plan);

    if (performedSets == 0) {
      return CompletionEvaluation(
        status: WorkoutCompletionStatus.cancelled,
        ratio: 0.0,
        missingExerciseIds: missing,
      );
    }

    final ruleOk = rule.isCompletedBy(result, plan);
    if (ruleOk && ratio >= 1.0) {
      return CompletionEvaluation(
        status: WorkoutCompletionStatus.completed,
        ratio: ratio,
        missingExerciseIds: missing,
      );
    }

    if (ratio < 0.5 && missing.isNotEmpty) {
      return CompletionEvaluation(
        status: WorkoutCompletionStatus.abandoned,
        ratio: ratio,
        missingExerciseIds: missing,
      );
    }

    return CompletionEvaluation(
      status: WorkoutCompletionStatus.partial,
      ratio: ratio,
      missingExerciseIds: missing,
    );
  }
}

PerformedExerciseDetails? _matchPerformed(
  WorkoutResult result,
  String exerciseId,
  int exerciseIndex,
) {
  for (final ex in result.exercises) {
    if (ex.exerciseId == exerciseId) return ex;
  }
  return null;
}

int _countPerformedSets(WorkoutResult result) {
  var count = 0;
  for (final ex in result.exercises) {
    for (final s in ex.sets) {
      if (s.actualReps > 0) count++;
    }
  }
  return count;
}

List<String> _missingExerciseIds(WorkoutResult result, WorkoutPlan plan) {
  final missing = <String>[];
  for (final planEx in plan.exercises) {
    final performed = result.exercises
        .where((e) => e.exerciseId == planEx.id)
        .any((e) => e.sets.any((s) => s.actualReps > 0));
    if (!performed) missing.add(planEx.id);
  }
  return missing;
}
