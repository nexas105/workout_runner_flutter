import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutResult totals', () {
    final completedAt = DateTime.utc(2026, 5, 21, 11, 0, 0);

    PerformedSet set({
      required int exerciseIndex,
      required int setIndex,
      required int reps,
      double? weight,
    }) => PerformedSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      actualReps: reps,
      actualWeight: weight,
      completedAt: completedAt,
    );

    WorkoutResult buildResult() => WorkoutResult(
      planId: 'plan_a',
      startedAt: completedAt.subtract(const Duration(minutes: 30)),
      finishedAt: completedAt,
      duration: const Duration(minutes: 30),
      exercises: [
        PerformedExerciseDetails(
          exerciseId: 'ex_bench',
          exerciseName: 'Bench press',
          sets: [
            set(exerciseIndex: 0, setIndex: 0, reps: 8, weight: 60),
            set(exerciseIndex: 0, setIndex: 1, reps: 8, weight: 60),
            set(exerciseIndex: 0, setIndex: 2, reps: 6, weight: 65),
          ],
        ),
        PerformedExerciseDetails(
          exerciseId: 'ex_pullups',
          exerciseName: 'Pull-ups',
          sets: [
            // Bodyweight: no weight set, must not count toward volume.
            set(exerciseIndex: 1, setIndex: 0, reps: 10),
            set(exerciseIndex: 1, setIndex: 1, reps: 8),
          ],
        ),
      ],
    );

    test('totalSets counts every performed set across exercises', () {
      expect(buildResult().totalSets, 5);
    });

    test('totalReps sums actual reps across all performed sets', () {
      // 8 + 8 + 6 + 10 + 8
      expect(buildResult().totalReps, 40);
    });

    test('totalVolume sums weight * reps and ignores null weights', () {
      // 60*8 + 60*8 + 65*6 + 0*10 + 0*8 = 480 + 480 + 390 = 1350
      expect(buildResult().totalVolume, 1350.0);
    });

    test('totals are zero for an empty result', () {
      final empty = WorkoutResult(
        planId: 'empty',
        startedAt: completedAt,
        finishedAt: completedAt,
        duration: Duration.zero,
        exercises: const [],
      );

      expect(empty.totalSets, 0);
      expect(empty.totalReps, 0);
      expect(empty.totalVolume, 0.0);
    });
  });

  group('WorkoutResult.toCsv', () {
    final completedAt = DateTime.utc(2026, 5, 21, 11, 0, 0);

    test('emits one header row plus one row per performed set', () {
      final result = WorkoutResult(
        planId: 'plan_a',
        startedAt: completedAt.subtract(const Duration(minutes: 30)),
        finishedAt: completedAt,
        duration: const Duration(minutes: 30),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'ex_bench',
            exerciseName: 'Bench, press',
            sets: [
              PerformedSet(
                exerciseIndex: 0,
                setIndex: 0,
                actualReps: 8,
                actualWeight: 60.0,
                pause: const Duration(seconds: 90),
                type: SetType.warmup,
                completedAt: completedAt,
              ),
              PerformedSet(
                exerciseIndex: 0,
                setIndex: 1,
                actualReps: 6,
                actualWeight: 65.0,
                completedAt: completedAt,
              ),
            ],
          ),
        ],
      );

      final csv = result.toCsv();
      final lines = csv.trim().split('\n');
      expect(lines.length, 3);
      expect(lines.first.startsWith('planId,exerciseId'), isTrue);
      // Comma in exercise name should be quoted.
      expect(lines[1].contains('"Bench, press"'), isTrue);
      expect(lines[1].split(',').contains('warmup'), isTrue);
      // Working-type row omits the type marker (empty column between setIndex
      // and actualReps).
      expect(lines[2].contains(',,'), isTrue);
    });

    test('header-only output when there are no performed sets', () {
      final empty = WorkoutResult(
        planId: 'p',
        startedAt: completedAt,
        finishedAt: completedAt,
        duration: Duration.zero,
        exercises: const [],
      );

      final lines = empty.toCsv().trim().split('\n');
      expect(lines.length, 1);
      expect(lines.first.startsWith('planId'), isTrue);
    });

    test('includeHeader: false skips the header row', () {
      final empty = WorkoutResult(
        planId: 'p',
        startedAt: completedAt,
        finishedAt: completedAt,
        duration: Duration.zero,
        exercises: const [],
      );
      expect(empty.toCsv(includeHeader: false), '');
    });
  });
}
