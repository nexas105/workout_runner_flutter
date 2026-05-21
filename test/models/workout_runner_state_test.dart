import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorkoutRunnerState buildState({int? activeExerciseIndex}) {
    final now = DateTime.utc(2026, 5, 21, 9, 0, 0);
    return WorkoutRunnerState(
      planId: 'plan_a',
      currentExerciseIndex: 1,
      activeExerciseIndex: activeExerciseIndex,
      currentSetIndex: 2,
      isActive: true,
      startedAt: now,
      updatedAt: now.add(const Duration(minutes: 5)),
      performed: [
        PerformedExercise(
          exerciseIndex: 0,
          exerciseName: 'Bench press',
          sets: [
            PerformedSet(
              exerciseIndex: 0,
              setIndex: 0,
              actualReps: 8,
              actualWeight: 60,
              completedAt: now.add(const Duration(minutes: 2)),
            ),
          ],
        ),
      ],
    );
  }

  group('WorkoutRunnerState JSON round-trip', () {
    test('round-trips with an active exercise index', () {
      final state = buildState(activeExerciseIndex: 1);

      final round = WorkoutRunnerState.fromJson(state.toJson());

      expect(round.planId, 'plan_a');
      expect(round.currentExerciseIndex, 1);
      expect(round.activeExerciseIndex, 1);
      expect(round.currentSetIndex, 2);
      expect(round.isActive, isTrue);
      expect(round.startedAt.toUtc(), state.startedAt);
      expect(round.updatedAt.toUtc(), state.updatedAt);
      expect(round.performed.length, 1);
      expect(round.performed.first.exerciseName, 'Bench press');
      expect(round.performed.first.sets.first.actualReps, 8);
    });

    test('round-trips with null active exercise index', () {
      final state = buildState(activeExerciseIndex: null);

      final round = WorkoutRunnerState.fromJson(state.toJson());

      expect(round.activeExerciseIndex, isNull);
      expect(round.planId, 'plan_a');
    });
  });

  group('WorkoutRunnerState.copyWith', () {
    test('omitting activeExerciseIndex preserves the existing value', () {
      final state = buildState(activeExerciseIndex: 2);

      final copy = state.copyWith(currentSetIndex: 5);

      expect(copy.activeExerciseIndex, 2);
      expect(copy.currentSetIndex, 5);
    });

    test('explicitly passing null clears activeExerciseIndex', () {
      final state = buildState(activeExerciseIndex: 2);

      final copy = state.copyWith(activeExerciseIndex: null);

      expect(copy.activeExerciseIndex, isNull);
      // Other fields retained.
      expect(copy.planId, 'plan_a');
      expect(copy.currentExerciseIndex, 1);
    });

    test('explicitly passing a value updates activeExerciseIndex', () {
      final state = buildState(activeExerciseIndex: null);

      final copy = state.copyWith(activeExerciseIndex: 3);

      expect(copy.activeExerciseIndex, 3);
    });
  });
}
