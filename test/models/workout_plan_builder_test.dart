import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutPlanBuilder', () {
    test('builds a plan with fluent exercise and set calls', () {
      final plan =
          WorkoutPlanBuilder('Push Day')
              .exercise('Bench Press')
              .set(reps: 8, weight: 80, rest: const Duration(seconds: 90))
              .set(reps: 8, weight: 80)
              .exercise('Shoulder Press')
              .set(reps: 10)
              .build();

      expect(plan.id, 'push-day');
      expect(plan.name, 'Push Day');
      expect(plan.exercises, hasLength(2));
      expect(plan.exercises.first.id, 'bench-press');
      expect(plan.exercises.first.sets, hasLength(2));
      expect(plan.exercises.first.sets.first.targetReps, 8);
      expect(plan.exercises.first.sets.first.targetWeight, 80);
      expect(plan.exercises.first.sets.first.rest, const Duration(seconds: 90));
      expect(plan.exercises.last.id, 'shoulder-press');
      expect(plan.exercises.last.sets.single.targetReps, 10);
    });

    test('deduplicates generated exercise ids', () {
      final plan =
          WorkoutPlanBuilder('Plan')
              .exercise('Bench Press')
              .set(reps: 8)
              .exercise('Bench Press')
              .set(reps: 10)
              .build();

      expect(plan.exercises.map((e) => e.id), ['bench-press', 'bench-press-2']);
    });

    test('throws when adding a set before an exercise', () {
      final builder = WorkoutPlanBuilder('Plan');

      expect(() => builder.set(reps: 10), throwsStateError);
    });
  });

  group('WorkoutPlan validation', () {
    test('validates a usable plan', () {
      final plan =
          WorkoutPlanBuilder(
            'Leg Day',
          ).exercise('Squat').set(reps: 5, weight: 100).build();

      final result = plan.validate();

      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('reports errors and warnings', () {
      const plan = WorkoutPlan(
        id: '',
        name: '',
        exercises: [
          WorkoutExercise(id: 'duplicate', name: 'No sets'),
          WorkoutExercise(
            id: 'duplicate',
            name: 'Bad set',
            sets: [WorkoutSet(targetReps: 0, targetWeight: -1)],
          ),
        ],
      );

      final result = plan.validate();

      expect(result.isValid, isFalse);
      expect(result.hasWarnings, isTrue);
      expect(result.errors.map((i) => i.code), contains('plan_id_empty'));
      expect(result.errors.map((i) => i.code), contains('plan_name_empty'));
      expect(
        result.errors.map((i) => i.code),
        contains('exercise_id_duplicate'),
      );
      expect(result.errors.map((i) => i.code), contains('set_reps_invalid'));
      expect(result.errors.map((i) => i.code), contains('set_weight_invalid'));
      expect(
        result.warnings.map((i) => i.code),
        contains('exercise_sets_empty'),
      );
    });
  });
}
