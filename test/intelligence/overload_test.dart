import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

PerformedSet _set({
  required int setIndex,
  required int reps,
  double? weight,
  int? rir,
  DateTime? at,
  SetType type = SetType.working,
}) => PerformedSet(
  exerciseIndex: 0,
  setIndex: setIndex,
  actualReps: reps,
  actualWeight: weight,
  rir: rir,
  type: type,
  completedAt: at ?? DateTime(2026, 5, 1, 10, setIndex),
);

PerformedExerciseDetails _session(List<PerformedSet> sets) =>
    PerformedExerciseDetails(
      exerciseId: 'bench-press',
      exerciseName: 'Bench Press',
      sets: sets,
    );

void main() {
  group('OverloadEngine.from', () {
    const target = WorkoutSet(targetReps: 8, targetWeight: 100);

    test('returns null for empty history', () {
      expect(OverloadEngine.from(const [], target), isNull);
    });

    test('returns null when history has no working sets', () {
      final session = _session([
        _set(setIndex: 0, reps: 10, weight: 40, type: SetType.warmup),
      ]);
      expect(OverloadEngine.from([session], target), isNull);
    });

    group('linear strategy', () {
      test('bumps weight when last session hit target reps on all sets', () {
        final session = _session([
          _set(setIndex: 0, reps: 8, weight: 100),
          _set(setIndex: 1, reps: 8, weight: 100),
          _set(setIndex: 2, reps: 8, weight: 100),
        ]);
        final s = OverloadEngine.from([session], target)!;
        expect(s.strategy, OverloadStrategy.linear);
        expect(s.suggestedWeight, 102.5);
        expect(s.suggestedReps, 8);
      });

      test('holds weight if any set missed target reps', () {
        final session = _session([
          _set(setIndex: 0, reps: 8, weight: 100),
          _set(setIndex: 1, reps: 7, weight: 100),
        ]);
        final s = OverloadEngine.from([session], target)!;
        expect(s.suggestedWeight, 100);
        expect(s.suggestedReps, 8);
      });

      test('respects custom increment', () {
        final session = _session([_set(setIndex: 0, reps: 8, weight: 100)]);
        final s = OverloadEngine.from(
          [session],
          target,
          linearIncrementKg: 5,
        )!;
        expect(s.suggestedWeight, 105);
      });

      test('uses most recent session by completedAt', () {
        final older = _session([
          _set(setIndex: 0, reps: 6, weight: 100, at: DateTime(2026, 1, 1)),
        ]);
        final newer = _session([
          _set(setIndex: 0, reps: 8, weight: 100, at: DateTime(2026, 5, 1)),
        ]);
        // Pass in reversed order to confirm internal sort.
        final s = OverloadEngine.from([older, newer], target)!;
        expect(s.suggestedWeight, 102.5);
      });
    });

    group('doubleProgression strategy', () {
      test('adds a rep when target hit and below cap', () {
        final session = _session([
          _set(setIndex: 0, reps: 8, weight: 100),
          _set(setIndex: 1, reps: 8, weight: 100),
        ]);
        final s = OverloadEngine.from(
          [session],
          target,
          strategy: OverloadStrategy.doubleProgression,
        )!;
        expect(s.suggestedReps, 9);
        expect(s.suggestedWeight, 100);
      });

      test('bumps weight and resets reps at cap', () {
        const capped = WorkoutSet(targetReps: 12, targetWeight: 100);
        final session = _session([
          _set(setIndex: 0, reps: 12, weight: 100),
          _set(setIndex: 1, reps: 12, weight: 100),
        ]);
        final s = OverloadEngine.from(
          [session],
          capped,
          strategy: OverloadStrategy.doubleProgression,
        )!;
        expect(s.suggestedWeight, 102.5);
        expect(s.suggestedReps, lessThan(12));
        expect(s.suggestedReps, greaterThanOrEqualTo(1));
      });

      test('holds when reps missed', () {
        final session = _session([_set(setIndex: 0, reps: 7, weight: 100)]);
        final s = OverloadEngine.from(
          [session],
          target,
          strategy: OverloadStrategy.doubleProgression,
        )!;
        expect(s.suggestedWeight, 100);
        expect(s.suggestedReps, 8);
      });
    });

    group('rpe strategy', () {
      test('bumps weight when RIR >= 2 on every set', () {
        final session = _session([
          _set(setIndex: 0, reps: 8, weight: 100, rir: 3),
          _set(setIndex: 1, reps: 8, weight: 100, rir: 2),
        ]);
        final s = OverloadEngine.from(
          [session],
          target,
          strategy: OverloadStrategy.rpe,
        )!;
        expect(s.suggestedWeight, 102.5);
        expect(s.suggestedReps, 8);
      });

      test('holds weight when any set has RIR 0', () {
        final session = _session([
          _set(setIndex: 0, reps: 8, weight: 100, rir: 2),
          _set(setIndex: 1, reps: 8, weight: 100, rir: 0),
        ]);
        final s = OverloadEngine.from(
          [session],
          target,
          strategy: OverloadStrategy.rpe,
        )!;
        expect(s.suggestedWeight, 100);
      });

      test('holds weight when reps missed', () {
        final session = _session([
          _set(setIndex: 0, reps: 6, weight: 100, rir: 3),
        ]);
        final s = OverloadEngine.from(
          [session],
          target,
          strategy: OverloadStrategy.rpe,
        )!;
        expect(s.suggestedWeight, 100);
      });
    });

    test('OverloadSuggestion json round-trip', () {
      const s = OverloadSuggestion(
        suggestedWeight: 105,
        suggestedReps: 8,
        reason: 'test',
        strategy: OverloadStrategy.rpe,
      );
      final json = s.toJson();
      final back = OverloadSuggestion.fromJson(json);
      expect(back, s);
    });

    test('handles null targetWeight by returning null suggestedWeight', () {
      const bodyweight = WorkoutSet(targetReps: 10);
      final session = _session([_set(setIndex: 0, reps: 10)]);
      final s = OverloadEngine.from([session], bodyweight)!;
      expect(s.suggestedWeight, isNull);
      expect(s.suggestedReps, 10);
    });
  });
}
