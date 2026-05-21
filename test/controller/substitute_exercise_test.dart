import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _plan() => const WorkoutPlan(
      id: 'p',
      name: 'Push',
      exercises: [
        WorkoutExercise(
          id: 'bench',
          name: 'Bench',
          sets: [WorkoutSet(targetReps: 8, targetWeight: 60)],
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

  test('substituteExercise swaps the exercise and stamps substitutedFrom',
      () async {
    await runner.start(_plan());

    final ok = await runner.substituteExercise(
      0,
      const WorkoutExercise(
        id: 'incline_db',
        name: 'Incline DB press',
        sets: [WorkoutSet(targetReps: 8, targetWeight: 22.5)],
      ),
    );

    expect(ok, isTrue);
    expect(runner.plan!.exercises.first.id, 'incline_db');

    runner.setActiveExercise(0);
    runner.startSet(0, 0);
    await runner.finishCurrentSet(reps: 8, weight: 22.5, rest: Duration.zero);

    final result = await runner.finish();
    expect(result, isNotNull);
    expect(result!.exercises.first.exerciseId, 'incline_db');
    expect(result.exercises.first.substitutedFrom, 'bench');
  });

  test('substituteExercise refuses when sets have been performed', () async {
    await runner.start(_plan());
    runner.setActiveExercise(0);
    runner.startSet(0, 0);
    await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

    final ok = await runner.substituteExercise(
      0,
      const WorkoutExercise(id: 'other', name: 'Other'),
    );
    expect(ok, isFalse);
    expect(runner.plan!.exercises.first.id, 'bench');
  });

  test('substituteExercise is a no-op when ids match', () async {
    await runner.start(_plan());
    expect(
      await runner.substituteExercise(
        0,
        const WorkoutExercise(id: 'bench', name: 'Bench redux'),
      ),
      isTrue,
    );
  });
}
