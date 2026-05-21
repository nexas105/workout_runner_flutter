import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutResult _result({
  required String planId,
  required DateTime finishedAt,
  Duration duration = const Duration(minutes: 30),
  List<PerformedExerciseDetails> exercises = const [],
}) => WorkoutResult(
  planId: planId,
  startedAt: finishedAt.subtract(duration),
  finishedAt: finishedAt,
  duration: duration,
  exercises: exercises,
);

PerformedSet _set({
  required int exerciseIndex,
  required int setIndex,
  required int reps,
  double? weight,
  DateTime? at,
  Duration? duration,
}) => PerformedSet(
  exerciseIndex: exerciseIndex,
  setIndex: setIndex,
  actualReps: reps,
  actualWeight: weight,
  completedAt: at ?? DateTime.utc(2026, 5, 21),
  duration: duration,
);

void main() {
  group('WorkoutStats totals', () {
    test('empty list returns neutral totals', () {
      expect(WorkoutStats.totalVolume(const []), 0);
      expect(WorkoutStats.totalSets(const []), 0);
      expect(WorkoutStats.totalReps(const []), 0);
      expect(WorkoutStats.totalDuration(const []), Duration.zero);
      expect(WorkoutStats.totalKcal(const [], bodyWeightKg: 80), 0);
      expect(WorkoutStats.volumePerExercise(const []), isEmpty);
    });

    test('sums across multiple results', () {
      final r1 = _result(
        planId: 'p1',
        finishedAt: DateTime.utc(2026, 5, 20, 10),
        duration: const Duration(minutes: 30),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            sets: [
              _set(exerciseIndex: 0, setIndex: 0, reps: 8, weight: 60),
              _set(exerciseIndex: 0, setIndex: 1, reps: 8, weight: 60),
            ],
          ),
        ],
      );
      final r2 = _result(
        planId: 'p2',
        finishedAt: DateTime.utc(2026, 5, 21, 10),
        duration: const Duration(minutes: 45),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'squat',
            exerciseName: 'Squat',
            sets: [
              _set(exerciseIndex: 0, setIndex: 0, reps: 5, weight: 100),
              _set(exerciseIndex: 0, setIndex: 1, reps: 5, weight: 100),
              _set(exerciseIndex: 0, setIndex: 2, reps: 5, weight: 100),
            ],
          ),
        ],
      );

      expect(WorkoutStats.totalVolume([r1, r2]), 960 + 1500);
      expect(WorkoutStats.totalSets([r1, r2]), 5);
      expect(WorkoutStats.totalReps([r1, r2]), 31);
      expect(
        WorkoutStats.totalDuration([r1, r2]),
        const Duration(minutes: 75),
      );
    });

    test('totalKcal accumulates per-result kcal', () {
      final ex = PerformedExerciseDetails(
        exerciseId: 'bench',
        exerciseName: 'Bench',
        met: 6.0,
        sets: [
          _set(
            exerciseIndex: 0,
            setIndex: 0,
            reps: 8,
            weight: 60,
            duration: const Duration(seconds: 60),
          ),
        ],
      );
      final r = _result(
        planId: 'p1',
        finishedAt: DateTime.utc(2026, 5, 20, 10),
        exercises: [ex],
      );
      final single = r.kcal(bodyWeightKg: 80);
      expect(WorkoutStats.totalKcal([r, r], bodyWeightKg: 80), single * 2);
      expect(WorkoutStats.totalKcal([r], bodyWeightKg: 0), 0);
    });

    test('volumePerExercise aggregates by exerciseId', () {
      final r1 = _result(
        planId: 'p1',
        finishedAt: DateTime.utc(2026, 5, 20, 10),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            sets: [_set(exerciseIndex: 0, setIndex: 0, reps: 8, weight: 60)],
          ),
        ],
      );
      final r2 = _result(
        planId: 'p2',
        finishedAt: DateTime.utc(2026, 5, 21, 10),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            sets: [_set(exerciseIndex: 0, setIndex: 0, reps: 5, weight: 70)],
          ),
          PerformedExerciseDetails(
            exerciseId: 'squat',
            exerciseName: 'Squat',
            sets: [_set(exerciseIndex: 0, setIndex: 0, reps: 5, weight: 100)],
          ),
        ],
      );
      final map = WorkoutStats.volumePerExercise([r1, r2]);
      expect(map['bench'], 480 + 350);
      expect(map['squat'], 500);
      expect(map.length, 2);
    });
  });

  group('WorkoutStats.streakDays', () {
    test('empty list returns 0', () {
      expect(
        WorkoutStats.streakDays(const [], now: DateTime(2026, 5, 21)),
        0,
      );
    });

    test('consecutive days including today', () {
      final now = DateTime(2026, 5, 21, 18);
      final results = [
        _result(planId: 'a', finishedAt: DateTime(2026, 5, 19, 10)),
        _result(planId: 'b', finishedAt: DateTime(2026, 5, 20, 10)),
        _result(planId: 'c', finishedAt: DateTime(2026, 5, 21, 10)),
      ];
      expect(WorkoutStats.streakDays(results, now: now), 3);
    });

    test('anchor at yesterday still counts streak', () {
      final now = DateTime(2026, 5, 21, 18);
      final results = [
        _result(planId: 'a', finishedAt: DateTime(2026, 5, 19, 10)),
        _result(planId: 'b', finishedAt: DateTime(2026, 5, 20, 10)),
      ];
      expect(WorkoutStats.streakDays(results, now: now), 2);
    });

    test('gap of one full day breaks the streak', () {
      final now = DateTime(2026, 5, 21, 18);
      final results = [
        _result(planId: 'a', finishedAt: DateTime(2026, 5, 18, 10)),
        _result(planId: 'b', finishedAt: DateTime(2026, 5, 20, 10)),
        _result(planId: 'c', finishedAt: DateTime(2026, 5, 21, 10)),
      ];
      // 19th is missing -> streak from today: 21, 20 = 2
      expect(WorkoutStats.streakDays(results, now: now), 2);
    });

    test('most recent result older than yesterday returns 0', () {
      final now = DateTime(2026, 5, 21, 18);
      final results = [
        _result(planId: 'a', finishedAt: DateTime(2026, 5, 18, 10)),
        _result(planId: 'b', finishedAt: DateTime(2026, 5, 19, 10)),
      ];
      expect(WorkoutStats.streakDays(results, now: now), 0);
    });

    test('multiple workouts on the same day count once', () {
      final now = DateTime(2026, 5, 21, 23);
      final results = [
        _result(planId: 'a', finishedAt: DateTime(2026, 5, 21, 8)),
        _result(planId: 'b', finishedAt: DateTime(2026, 5, 21, 18)),
      ];
      expect(WorkoutStats.streakDays(results, now: now), 1);
    });
  });

  group('WorkoutStats.weeklySummary', () {
    test('empty list returns zeroed summary for window', () {
      final start = DateTime.utc(2026, 5, 14);
      final summary = WorkoutStats.weeklySummary(
        const [],
        weekStart: start,
      );
      expect(summary.workoutCount, 0);
      expect(summary.totalSets, 0);
      expect(summary.totalReps, 0);
      expect(summary.totalVolume, 0);
      expect(summary.totalDuration, Duration.zero);
      expect(summary.start, start);
      expect(summary.end, start.add(const Duration(days: 7)));
    });

    test('only counts results inside [start, end)', () {
      final start = DateTime.utc(2026, 5, 14);
      final inside1 = _result(
        planId: 'a',
        finishedAt: DateTime.utc(2026, 5, 14, 0, 0, 1),
        duration: const Duration(minutes: 30),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            sets: [_set(exerciseIndex: 0, setIndex: 0, reps: 8, weight: 60)],
          ),
        ],
      );
      final inside2 = _result(
        planId: 'b',
        finishedAt: DateTime.utc(2026, 5, 20, 23, 59),
        duration: const Duration(minutes: 20),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'squat',
            exerciseName: 'Squat',
            sets: [_set(exerciseIndex: 0, setIndex: 0, reps: 5, weight: 100)],
          ),
        ],
      );
      // exactly at end -> excluded (half-open window)
      final boundary = _result(
        planId: 'c',
        finishedAt: start.add(const Duration(days: 7)),
        duration: const Duration(minutes: 10),
      );
      final before = _result(
        planId: 'd',
        finishedAt: DateTime.utc(2026, 5, 13, 23),
        duration: const Duration(minutes: 10),
      );

      final summary = WorkoutStats.weeklySummary(
        [inside1, inside2, boundary, before],
        weekStart: start,
      );
      expect(summary.workoutCount, 2);
      expect(summary.totalSets, 2);
      expect(summary.totalReps, 13);
      expect(summary.totalVolume, 480 + 500);
      expect(summary.totalDuration, const Duration(minutes: 50));
    });

    test('roundtrips via toJson/fromJson', () {
      final summary = WeeklyWorkoutSummary(
        start: DateTime.utc(2026, 5, 14),
        end: DateTime.utc(2026, 5, 21),
        workoutCount: 3,
        totalSets: 9,
        totalReps: 60,
        totalVolume: 3600.5,
        totalDuration: const Duration(minutes: 95),
      );
      final copy = WeeklyWorkoutSummary.fromJson(summary.toJson());
      expect(copy, summary);
    });
  });
}
