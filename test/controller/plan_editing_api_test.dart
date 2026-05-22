import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _plan() => const WorkoutPlan(
  id: 'p',
  name: 'Push',
  exercises: [
    WorkoutExercise(
      id: 'bench',
      name: 'Bench',
      sets: [
        WorkoutSet(targetReps: 8, targetWeight: 60),
        WorkoutSet(targetReps: 8, targetWeight: 60),
      ],
    ),
    WorkoutExercise(
      id: 'press',
      name: 'OHP',
      sets: [WorkoutSet(targetReps: 6, targetWeight: 40)],
    ),
  ],
);

void main() {
  late InMemoryRunnerStorage storage;
  late WorkoutRunner runner;

  setUp(() {
    storage = InMemoryRunnerStorage();
    runner = WorkoutRunner(storage: storage);
  });

  tearDown(() async {
    await runner.cancel();
    runner.dispose();
  });

  group('addExercise', () {
    test('appends a new exercise', () async {
      await runner.start(_plan());
      final ok = await runner.addExercise(
        const WorkoutExercise(
          id: 'row',
          name: 'Row',
          sets: [WorkoutSet(targetReps: 10)],
        ),
      );
      expect(ok, isTrue);
      expect(runner.plan!.exercises.length, 3);
      expect(runner.plan!.exercises.last.id, 'row');
    });

    test('refuses duplicate ids', () async {
      await runner.start(_plan());
      final ok = await runner.addExercise(
        const WorkoutExercise(id: 'bench', name: 'Dup'),
      );
      expect(ok, isFalse);
    });
  });

  group('removeExercise', () {
    test('removes a non-performed exercise', () async {
      await runner.start(_plan());
      final ok = await runner.removeExercise(1);
      expect(ok, isTrue);
      expect(runner.plan!.exercises.map((e) => e.id).toList(), ['bench']);
    });

    test('refuses removal when sets have been performed', () async {
      await runner.start(_plan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

      final ok = await runner.removeExercise(0);
      expect(ok, isFalse);
      expect(runner.plan!.exercises.length, 2);
    });
  });

  group('moveExercise', () {
    test('reorders exercises and remaps performed-set indices', () async {
      await runner.start(_plan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

      final ok = await runner.moveExercise(0, 1);
      expect(ok, isTrue);
      expect(runner.plan!.exercises.first.id, 'press');
      expect(runner.plan!.exercises.last.id, 'bench');
      // The performed entry should now live at the new exerciseIndex 1.
      expect(runner.getPerformedSet(0, 0), isNull);
      expect(runner.getPerformedSet(1, 0), isNotNull);
    });

    test('same-index move is a no-op', () async {
      await runner.start(_plan());
      expect(await runner.moveExercise(0, 0), isTrue);
    });

    test('out-of-range indices return false', () async {
      await runner.start(_plan());
      expect(await runner.moveExercise(0, 99), isFalse);
    });
  });

  group('replaceSet', () {
    test('overwrites a non-performed set', () async {
      await runner.start(_plan());
      final ok = await runner.replaceSet(
        0,
        1,
        const WorkoutSet(targetReps: 5, targetWeight: 80),
      );
      expect(ok, isTrue);
      expect(runner.plan!.exercises[0].sets[1].targetReps, 5);
      expect(runner.plan!.exercises[0].sets[1].targetWeight, 80);
    });

    test('refuses to overwrite a performed set', () async {
      await runner.start(_plan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

      final ok = await runner.replaceSet(0, 0, const WorkoutSet(targetReps: 1));
      expect(ok, isFalse);
    });
  });

  group('duplicateSet / reorderSets', () {
    test('duplicateSet inserts a clone and returns its index', () async {
      await runner.start(_plan());
      final newIndex = await runner.duplicateSet(0, 0);
      expect(newIndex, 1);
      expect(runner.plan!.exercises[0].sets.length, 3);
      expect(
        runner.plan!.exercises[0].sets[1].targetWeight,
        runner.plan!.exercises[0].sets[0].targetWeight,
      );
    });

    test('reorderSets refuses to move a performed set', () async {
      await runner.start(_plan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

      final ok = await runner.reorderSets(0, 0, 1);
      expect(ok, isFalse);
    });

    test('reorderSets moves non-performed sets', () async {
      await runner.start(_plan());
      await runner.duplicateSet(0, 0); // now 3 working sets
      final ok = await runner.reorderSets(0, 0, 2);
      expect(ok, isTrue);
      expect(runner.plan!.exercises[0].sets.length, 3);
    });
  });
}
