import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _planA() => const WorkoutPlan(
  id: 'a',
  name: 'A',
  exercises: [
    WorkoutExercise(
      id: 'bench',
      name: 'Bench',
      sets: [WorkoutSet(targetReps: 8)],
    ),
    WorkoutExercise(
      id: 'press',
      name: 'OHP',
      sets: [WorkoutSet(targetReps: 6)],
    ),
  ],
);

WorkoutPlan _planB() => const WorkoutPlan(
  id: 'b',
  name: 'B',
  exercises: [
    WorkoutExercise(
      id: 'squat',
      name: 'Squat',
      sets: [WorkoutSet(targetReps: 5)],
    ),
  ],
);

void main() {
  late WorkoutRunner runner;

  setUp(() => runner = WorkoutRunner(storage: InMemoryRunnerStorage()));
  tearDown(() async {
    await runner.cancel();
    runner.dispose();
  });

  test('replacePlan preserves performed sets by default', () async {
    await runner.start(_planA());
    runner.setActiveExercise(0);
    runner.startSet(0, 0);
    await runner.finishCurrentSet(reps: 8, rest: Duration.zero);
    expect(runner.state!.performed, isNotEmpty);

    final ok = await runner.replacePlan(_planA());
    expect(ok, isTrue);
    expect(runner.state!.performed, isNotEmpty);
  });

  test(
    'replacePlan clears performed when preservePerformed is false',
    () async {
      await runner.start(_planA());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

      final ok = await runner.replacePlan(_planB(), preservePerformed: false);
      expect(ok, isTrue);
      expect(runner.plan!.id, 'b');
      expect(runner.state!.performed, isEmpty);
      expect(runner.activeExerciseIndex, isNull);
    },
  );

  test('replacePlan caps activeExerciseIndex when out of range', () async {
    await runner.start(_planA());
    runner.setActiveExercise(1);
    expect(runner.activeExerciseIndex, 1);

    final ok = await runner.replacePlan(_planB());
    expect(ok, isTrue);
    // planB has only 1 exercise → previously active idx 1 must be cleared.
    expect(runner.activeExerciseIndex, isNull);
  });

  test('replacePlan returns false when no plan is active', () async {
    final ok = await runner.replacePlan(_planA());
    expect(ok, isFalse);
  });
}
