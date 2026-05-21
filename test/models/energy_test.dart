import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final completedAt = DateTime.utc(2026, 5, 21, 12, 0, 0);

  group('WorkoutResult.kcal', () {
    test('zero body weight short-circuits to 0', () {
      final r = WorkoutResult(
        planId: 'p',
        startedAt: completedAt,
        finishedAt: completedAt,
        duration: const Duration(minutes: 30),
        exercises: const [],
      );
      expect(r.kcal(bodyWeightKg: 0), 0);
      expect(r.kcal(bodyWeightKg: -5), 0);
    });

    test(
      'uses snapshotted MET per exercise and skips sets without duration',
      () {
        final r = WorkoutResult(
          planId: 'p',
          startedAt: completedAt,
          finishedAt: completedAt,
          duration: Duration.zero,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'ex',
              exerciseName: 'Bench',
              met: 6.0,
              sets: [
                PerformedSet(
                  exerciseIndex: 0,
                  setIndex: 0,
                  actualReps: 8,
                  duration: const Duration(minutes: 1),
                  completedAt: completedAt,
                ),
                PerformedSet(
                  exerciseIndex: 0,
                  setIndex: 1,
                  actualReps: 8,
                  completedAt: completedAt,
                ),
              ],
            ),
          ],
        );

        // 6 MET × (60s / 3600) × 80 kg = 8 kcal exactly.
        expect(r.kcal(bodyWeightKg: 80), closeTo(8.0, 1e-9));
      },
    );

    test('falls back to category default when met is null', () {
      // categoryId "strength" → 6 MET by default. Same expected number as the
      // previous test confirms the fallback path is engaged.
      final r = WorkoutResult(
        planId: 'p',
        startedAt: completedAt,
        finishedAt: completedAt,
        duration: Duration.zero,
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'ex',
            exerciseName: 'Bench',
            categoryId: 'strength',
            sets: [
              PerformedSet(
                exerciseIndex: 0,
                setIndex: 0,
                actualReps: 8,
                duration: const Duration(minutes: 1),
                completedAt: completedAt,
              ),
            ],
          ),
        ],
      );
      expect(r.kcal(bodyWeightKg: 80), closeTo(8.0, 1e-9));
    });
  });

  group('CardioResult.kcal', () {
    CardioResult buildResult({
      required List<CardioLap> laps,
      CardioDiscipline d = CardioDiscipline.running,
    }) => CardioResult(
      planId: 'p',
      planName: 'p',
      discipline: d,
      startedAt: completedAt,
      finishedAt: completedAt,
      duration: Duration.zero,
      laps: laps,
    );

    test('uses snapshotted MET per lap', () {
      final r = buildResult(
        laps: [
          CardioLap.computed(
            intervalIndex: 0,
            duration: const Duration(minutes: 10),
            met: 9.0,
            completedAt: completedAt,
          ),
        ],
      );
      // 9 × (600/3600) × 75 = 112.5
      expect(r.kcal(bodyWeightKg: 75), closeTo(112.5, 1e-9));
    });

    test('falls back to discipline default when lap.met is null', () {
      // walk discipline default = 3.5 MET; 3.5 × (600/3600) × 75 = 43.75
      final r = buildResult(
        d: CardioDiscipline.walk,
        laps: [
          CardioLap.computed(
            intervalIndex: 0,
            duration: const Duration(minutes: 10),
            completedAt: completedAt,
          ),
        ],
      );
      expect(r.kcal(bodyWeightKg: 75), closeTo(43.75, 1e-9));
    });
  });
}
