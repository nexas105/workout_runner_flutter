import 'workout_plan.dart';

enum WorkoutPlanValidationSeverity { warning, error }

class WorkoutPlanValidationIssue {
  const WorkoutPlanValidationIssue({
    required this.code,
    required this.message,
    this.severity = WorkoutPlanValidationSeverity.error,
  });

  final String code;
  final String message;
  final WorkoutPlanValidationSeverity severity;

  bool get isError => severity == WorkoutPlanValidationSeverity.error;
}

class WorkoutPlanValidationResult {
  const WorkoutPlanValidationResult(this.issues);

  final List<WorkoutPlanValidationIssue> issues;

  bool get isValid => !issues.any((issue) => issue.isError);
  bool get hasWarnings => issues.any(
    (issue) => issue.severity == WorkoutPlanValidationSeverity.warning,
  );

  List<WorkoutPlanValidationIssue> get errors =>
      issues.where((issue) => issue.isError).toList(growable: false);

  List<WorkoutPlanValidationIssue> get warnings => issues
      .where((issue) => issue.severity == WorkoutPlanValidationSeverity.warning)
      .toList(growable: false);
}

extension WorkoutPlanValidation on WorkoutPlan {
  WorkoutPlanValidationResult validate() {
    final issues = <WorkoutPlanValidationIssue>[];

    if (id.trim().isEmpty) {
      issues.add(
        const WorkoutPlanValidationIssue(
          code: 'plan_id_empty',
          message: 'WorkoutPlan.id must not be empty.',
        ),
      );
    }

    if (name.trim().isEmpty) {
      issues.add(
        const WorkoutPlanValidationIssue(
          code: 'plan_name_empty',
          message: 'WorkoutPlan.name must not be empty.',
        ),
      );
    }

    if (exercises.isEmpty) {
      issues.add(
        const WorkoutPlanValidationIssue(
          code: 'plan_exercises_empty',
          message: 'WorkoutPlan.exercises must contain at least one exercise.',
        ),
      );
    }

    final exerciseIds = <String>{};
    for (
      var exerciseIndex = 0;
      exerciseIndex < exercises.length;
      exerciseIndex++
    ) {
      final exercise = exercises[exerciseIndex];
      if (exercise.id.trim().isEmpty) {
        issues.add(
          WorkoutPlanValidationIssue(
            code: 'exercise_id_empty',
            message: 'Exercise at index $exerciseIndex has an empty id.',
          ),
        );
      } else if (!exerciseIds.add(exercise.id)) {
        issues.add(
          WorkoutPlanValidationIssue(
            code: 'exercise_id_duplicate',
            message: 'Exercise id "${exercise.id}" appears more than once.',
          ),
        );
      }

      if (exercise.name.trim().isEmpty) {
        issues.add(
          WorkoutPlanValidationIssue(
            code: 'exercise_name_empty',
            message: 'Exercise at index $exerciseIndex has an empty name.',
          ),
        );
      }

      if (exercise.sets.isEmpty) {
        issues.add(
          WorkoutPlanValidationIssue(
            code: 'exercise_sets_empty',
            message: 'Exercise "${exercise.name}" has no target sets.',
            severity: WorkoutPlanValidationSeverity.warning,
          ),
        );
      }

      for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        final set = exercise.sets[setIndex];
        if (set.targetReps <= 0) {
          issues.add(
            WorkoutPlanValidationIssue(
              code: 'set_reps_invalid',
              message:
                  'Set $setIndex of exercise "${exercise.name}" must target at least one rep.',
            ),
          );
        }
        final weight = set.targetWeight;
        if (weight != null && weight < 0) {
          issues.add(
            WorkoutPlanValidationIssue(
              code: 'set_weight_invalid',
              message:
                  'Set $setIndex of exercise "${exercise.name}" has a negative target weight.',
            ),
          );
        }
        final rest = set.rest;
        if (rest != null && rest.isNegative) {
          issues.add(
            WorkoutPlanValidationIssue(
              code: 'set_rest_invalid',
              message:
                  'Set $setIndex of exercise "${exercise.name}" has a negative rest duration.',
            ),
          );
        }
      }
    }

    final blockIds = <String>{};
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.id.trim().isEmpty) {
        issues.add(
          WorkoutPlanValidationIssue(
            code: 'block_id_empty',
            message: 'Block at index $i has an empty id.',
          ),
        );
      } else if (!blockIds.add(block.id)) {
        issues.add(
          WorkoutPlanValidationIssue(
            code: 'block_id_duplicate',
            message: 'Block id "${block.id}" appears more than once.',
          ),
        );
      }
      if (block.exerciseIndices.isEmpty) {
        issues.add(
          WorkoutPlanValidationIssue(
            code: 'block_empty',
            message: 'Block "${block.id}" must reference at least one exercise.',
            severity: WorkoutPlanValidationSeverity.warning,
          ),
        );
      }
      for (final idx in block.exerciseIndices) {
        if (idx < 0 || idx >= exercises.length) {
          issues.add(
            WorkoutPlanValidationIssue(
              code: 'block_exercise_index_out_of_range',
              message:
                  'Block "${block.id}" references exercise index $idx which is out of range.',
            ),
          );
        }
      }
      if (block.rounds < 1) {
        issues.add(
          WorkoutPlanValidationIssue(
            code: 'block_rounds_invalid',
            message: 'Block "${block.id}" must have at least 1 round.',
          ),
        );
      }
    }

    return WorkoutPlanValidationResult(List.unmodifiable(issues));
  }
}
