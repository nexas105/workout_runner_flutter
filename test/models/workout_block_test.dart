import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutBlock', () {
    test('isSuperset vs isCircuit classification', () {
      const sup = WorkoutBlock(
        id: 'block_a',
        exerciseIndices: [0, 1],
        rounds: 1,
      );
      const circ = WorkoutBlock(
        id: 'block_b',
        exerciseIndices: [0, 1, 2],
        rounds: 3,
      );
      expect(sup.isSuperset, isTrue);
      expect(sup.isCircuit, isFalse);
      expect(circ.isCircuit, isTrue);
      expect(circ.isSuperset, isFalse);
    });

    test('JSON round-trip preserves all fields', () {
      const original = WorkoutBlock(
        id: 'b1',
        name: 'Chest Superset',
        exerciseIndices: [0, 1],
        rounds: 2,
        restBetween: Duration(seconds: 30),
        restAfterBlock: Duration(seconds: 120),
        meta: {'tag': 'finisher'},
      );
      final round = WorkoutBlock.fromJson(original.toJson());
      expect(round.id, 'b1');
      expect(round.name, 'Chest Superset');
      expect(round.exerciseIndices, [0, 1]);
      expect(round.rounds, 2);
      expect(round.restBetween, const Duration(seconds: 30));
      expect(round.restAfterBlock, const Duration(seconds: 120));
      expect(round.meta?['tag'], 'finisher');
    });
  });

  group('WorkoutPlan + blocks', () {
    const plan = WorkoutPlan(
      id: 'p',
      name: 'Push',
      exercises: [
        WorkoutExercise(
          id: 'bench',
          name: 'Bench',
          sets: [WorkoutSet(targetReps: 8)],
        ),
        WorkoutExercise(
          id: 'flyes',
          name: 'Flyes',
          sets: [WorkoutSet(targetReps: 12)],
        ),
        WorkoutExercise(
          id: 'extension',
          name: 'Triceps extension',
          sets: [WorkoutSet(targetReps: 12)],
        ),
      ],
      blocks: [
        WorkoutBlock(
          id: 'chest_super',
          exerciseIndices: [0, 1],
          rounds: 1,
          restBetween: Duration(seconds: 30),
        ),
      ],
    );

    test('JSON round-trip preserves blocks alongside exercises', () {
      final round = WorkoutPlan.fromJson(plan.toJson());
      expect(round.blocks.length, 1);
      expect(round.blocks.first.id, 'chest_super');
      expect(round.blocks.first.exerciseIndices, [0, 1]);
    });

    test('blockForExerciseIndex finds the owning block or returns null', () {
      expect(plan.blockForExerciseIndex(0)?.id, 'chest_super');
      expect(plan.blockForExerciseIndex(1)?.id, 'chest_super');
      expect(plan.blockForExerciseIndex(2), isNull);
    });

    test('validation flags out-of-range block references', () {
      const bad = WorkoutPlan(
        id: 'bad',
        name: 'Bad',
        exercises: [
          WorkoutExercise(
            id: 'a',
            name: 'A',
            sets: [WorkoutSet(targetReps: 5)],
          ),
        ],
        blocks: [
          WorkoutBlock(id: 'oops', exerciseIndices: [0, 5]),
        ],
      );
      final result = bad.validate();
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((i) => i.code == 'block_exercise_index_out_of_range'),
        isTrue,
      );
    });

    test('validation flags duplicate block ids and zero rounds', () {
      const bad = WorkoutPlan(
        id: 'bad',
        name: 'Bad',
        exercises: [
          WorkoutExercise(
            id: 'a',
            name: 'A',
            sets: [WorkoutSet(targetReps: 5)],
          ),
        ],
        blocks: [
          WorkoutBlock(id: 'dup', exerciseIndices: [0]),
          WorkoutBlock(id: 'dup', exerciseIndices: [0], rounds: 0),
        ],
      );
      final result = bad.validate();
      final codes = result.issues.map((i) => i.code).toSet();
      expect(codes.contains('block_id_duplicate'), isTrue);
      expect(codes.contains('block_rounds_invalid'), isTrue);
    });
  });
}
