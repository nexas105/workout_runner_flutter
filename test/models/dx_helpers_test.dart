import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutPlan DX helpers', () {
    const plan = WorkoutPlan(
      id: 'plan_a',
      name: 'Push day',
      exercises: [
        WorkoutExercise(
          id: 'bench',
          name: 'Bench',
          sets: [
            WorkoutSet(targetReps: 8, rest: Duration(seconds: 90)),
            WorkoutSet(targetReps: 8, rest: Duration(seconds: 90)),
          ],
        ),
        WorkoutExercise(
          id: 'plank',
          name: 'Plank',
          sets: [
            WorkoutSet(
              targetReps: 0,
              type: SetType.timed,
              targetDuration: Duration(seconds: 45),
            ),
          ],
        ),
      ],
    );

    test('totalTargetSets sums sets across exercises', () {
      expect(plan.totalTargetSets, 3);
    });

    test('estimatedDuration uses targetDuration when present, default work otherwise', () {
      // 2 working sets: 30s work + 90s rest = 120s × 2 = 240s
      // 1 timed set: 45s work + 0 rest = 45s
      // Total: 285s
      expect(plan.estimatedDuration, const Duration(seconds: 285));
    });

    test('previewSummary mentions exercise / set / minute counts', () {
      final summary = plan.previewSummary;
      expect(summary, contains('2 exercises'));
      expect(summary, contains('3 sets'));
      expect(summary, contains('~4 min'));
    });

    test('cloneWithId changes only the id', () {
      final fork = plan.cloneWithId('plan_b');
      expect(fork.id, 'plan_b');
      expect(fork.name, plan.name);
      expect(fork.exercises, plan.exercises);
    });
  });

  group('WorkoutExercise.cloneWithId', () {
    test('changes only the id', () {
      const e = WorkoutExercise(id: 'a', name: 'A');
      expect(e.cloneWithId('b').id, 'b');
    });
  });

  group('CardioPlanBuilder', () {
    test('builds a plan with warmup, work intervals, rest and cooldown', () {
      final plan = CardioPlanBuilder(
        'Intervals',
        discipline: CardioDiscipline.running,
      )
          .warmup(duration: const Duration(minutes: 5))
          .interval(
            name: '400m',
            duration: const Duration(minutes: 2),
            met: 11,
          )
          .rest(duration: const Duration(minutes: 1))
          .interval(
            name: '400m',
            duration: const Duration(minutes: 2),
            met: 11,
          )
          .cooldown(duration: const Duration(minutes: 5))
          .build();

      expect(plan.intervals.length, 5);
      expect(plan.intervals.first.phase, CardioPhase.warmup);
      expect(plan.intervals.last.phase, CardioPhase.cooldown);
      // duplicate "400m" id must be unique
      final ids = plan.intervals.map((i) => i.id).toSet();
      expect(ids.length, plan.intervals.length);
    });

    test('CardioPlan.previewSummary includes interval count and minutes', () {
      final plan = CardioPlanBuilder('Easy run')
          .interval(name: 'Easy', duration: const Duration(minutes: 30))
          .build();
      expect(plan.previewSummary, contains('1 interval'));
      expect(plan.previewSummary, contains('~30 min'));
    });

    test('CardioPlan.cloneWithId changes only the id', () {
      final plan = CardioPlanBuilder('A').build();
      expect(plan.cloneWithId('b').id, 'b');
    });
  });
}
