import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _plan({
  String id = 'plan-1',
  List<WorkoutExercise> exercises = const [],
}) => WorkoutPlan(id: id, name: 'Test plan', exercises: exercises);

WorkoutExercise _ex(String id, int setCount) => WorkoutExercise(
  id: id,
  name: id,
  sets: List.generate(setCount, (_) => const WorkoutSet(targetReps: 10)),
);

PerformedSet _performed(int exerciseIndex, int setIndex, {int reps = 10}) =>
    PerformedSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      actualReps: reps,
      completedAt: DateTime.utc(2026, 1, 1, 0, 0, setIndex),
    );

WorkoutResult _result({
  String planId = 'plan-1',
  List<PerformedExerciseDetails> exercises = const [],
}) => WorkoutResult(
  planId: planId,
  startedAt: DateTime.utc(2026, 1, 1),
  finishedAt: DateTime.utc(2026, 1, 1, 1),
  duration: const Duration(hours: 1),
  exercises: exercises,
);

void main() {
  group('AllSetsCompletionRule', () {
    test('completed when every planned set has a performed counterpart', () {
      final plan = _plan(exercises: [_ex('bench', 3)]);
      final result = _result(
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'bench',
            sets: [
              _performed(0, 0),
              _performed(0, 1),
              _performed(0, 2),
            ],
          ),
        ],
      );

      final eval = WorkoutCompletion.evaluate(
        result,
        plan,
        const AllSetsCompletionRule(),
      );

      expect(eval.status, WorkoutCompletionStatus.completed);
      expect(eval.ratio, 1.0);
      expect(eval.missingExerciseIds, isEmpty);
    });

    test('partial when some sets missing', () {
      final plan = _plan(exercises: [_ex('bench', 3)]);
      final result = _result(
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'bench',
            sets: [_performed(0, 0), _performed(0, 1)],
          ),
        ],
      );

      final eval = WorkoutCompletion.evaluate(
        result,
        plan,
        const AllSetsCompletionRule(),
      );

      expect(eval.status, WorkoutCompletionStatus.partial);
      expect(eval.ratio, closeTo(2 / 3, 1e-9));
    });
  });

  group('MinimumSetsCompletionRule', () {
    test('partial when 2 performed of required 3', () {
      final plan = _plan(exercises: [_ex('bench', 5)]);
      final result = _result(
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'bench',
            sets: [_performed(0, 0), _performed(0, 1)],
          ),
        ],
      );

      final eval = WorkoutCompletion.evaluate(
        result,
        plan,
        const MinimumSetsCompletionRule(3),
      );

      expect(eval.status, WorkoutCompletionStatus.partial);
    });

    test('completed when 3 performed of required 3', () {
      final plan = _plan(exercises: [_ex('bench', 3)]);
      final result = _result(
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'bench',
            sets: [
              _performed(0, 0),
              _performed(0, 1),
              _performed(0, 2),
            ],
          ),
        ],
      );

      final eval = WorkoutCompletion.evaluate(
        result,
        plan,
        const MinimumSetsCompletionRule(3),
      );

      expect(eval.status, WorkoutCompletionStatus.completed);
    });
  });

  group('RequiredExercisesCompletionRule', () {
    test('flags missing required exercises', () {
      final plan = _plan(exercises: [_ex('bench', 2), _ex('squat', 2)]);
      final result = _result(
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'bench',
            sets: [_performed(0, 0), _performed(0, 1)],
          ),
        ],
      );

      final rule = const RequiredExercisesCompletionRule(['bench', 'squat']);
      expect(rule.isCompletedBy(result, plan), isFalse);

      final eval = WorkoutCompletion.evaluate(result, plan, rule);
      expect(eval.missingExerciseIds, contains('squat'));
      expect(eval.status, isNot(WorkoutCompletionStatus.completed));
    });

    test('satisfied when each id has >=1 performed set', () {
      final plan = _plan(exercises: [_ex('bench', 1), _ex('squat', 1)]);
      final result = _result(
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'bench',
            sets: [_performed(0, 0)],
          ),
          PerformedExerciseDetails(
            exerciseId: 'squat',
            exerciseName: 'squat',
            sets: [_performed(1, 0)],
          ),
        ],
      );

      final eval = WorkoutCompletion.evaluate(
        result,
        plan,
        const RequiredExercisesCompletionRule(['bench', 'squat']),
      );
      expect(eval.status, WorkoutCompletionStatus.completed);
      expect(eval.missingExerciseIds, isEmpty);
    });
  });

  group('FreeSessionCompletionRule', () {
    test('always satisfied by the rule', () {
      final plan = _plan(exercises: [_ex('bench', 3)]);
      final result = _result(
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'bench',
            sets: [
              _performed(0, 0),
              _performed(0, 1),
              _performed(0, 2),
            ],
          ),
        ],
      );

      final eval = WorkoutCompletion.evaluate(
        result,
        plan,
        const FreeSessionCompletionRule(),
      );
      expect(eval.status, WorkoutCompletionStatus.completed);
    });
  });

  group('status mapping', () {
    test('empty result -> cancelled', () {
      final plan = _plan(exercises: [_ex('bench', 3)]);
      final result = _result();

      final eval = WorkoutCompletion.evaluate(
        result,
        plan,
        const AllSetsCompletionRule(),
      );
      expect(eval.status, WorkoutCompletionStatus.cancelled);
      expect(eval.ratio, 0.0);
      expect(eval.missingExerciseIds, ['bench']);
    });

    test('low ratio with missing exercises -> abandoned', () {
      final plan = _plan(
        exercises: [_ex('bench', 4), _ex('squat', 4), _ex('row', 4)],
      );
      final result = _result(
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'bench',
            sets: [_performed(0, 0)],
          ),
        ],
      );

      final eval = WorkoutCompletion.evaluate(
        result,
        plan,
        const AllSetsCompletionRule(),
      );
      expect(eval.status, WorkoutCompletionStatus.abandoned);
      expect(eval.missingExerciseIds, containsAll(['squat', 'row']));
    });
  });

  group('CompletionEvaluation JSON', () {
    test('round-trips through JSON', () {
      const eval = CompletionEvaluation(
        status: WorkoutCompletionStatus.partial,
        ratio: 0.42,
        missingExerciseIds: ['bench', 'squat'],
      );

      final round = CompletionEvaluation.fromJson(eval.toJson());

      expect(round.status, WorkoutCompletionStatus.partial);
      expect(round.ratio, 0.42);
      expect(round.missingExerciseIds, ['bench', 'squat']);
    });
  });
}
