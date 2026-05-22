import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 21, 12);

  WorkoutResult buildResult({
    required String planId,
    required DateTime finishedAt,
    required Map<String, List<int>> repsByExercise,
    double weightPerRep = 50.0,
  }) {
    final exercises =
        repsByExercise.entries.map((entry) {
          final sets = <PerformedSet>[];
          for (var i = 0; i < entry.value.length; i++) {
            sets.add(
              PerformedSet(
                exerciseIndex: 0,
                setIndex: i,
                actualReps: entry.value[i],
                actualWeight: weightPerRep,
                completedAt: finishedAt,
              ),
            );
          }
          return PerformedExerciseDetails(
            exerciseId: entry.key,
            exerciseName: entry.key,
            sets: sets,
          );
        }).toList();

    return WorkoutResult(
      planId: planId,
      startedAt: finishedAt.subtract(const Duration(minutes: 45)),
      finishedAt: finishedAt,
      duration: const Duration(minutes: 45),
      exercises: exercises,
    );
  }

  group('Readiness.fromHistory', () {
    test('empty history returns ready with neutral multipliers', () {
      final r = Readiness.fromHistory(const [], now: now);
      expect(r.level, ReadinessLevel.ready);
      expect(r.suggestedVolumeMultiplier, 1.0);
      expect(r.suggestedIntensityMultiplier, 1.0);
      expect(r.score, inInclusiveRange(0.65, 0.85));
      expect(r.reason, contains('No recent history'));
    });

    test('stable history stays in ready bucket', () {
      final results = [
        buildResult(
          planId: 'p',
          finishedAt: now.subtract(const Duration(days: 10)),
          repsByExercise: const {
            'squat': [8, 8, 8],
          },
        ),
        buildResult(
          planId: 'p',
          finishedAt: now.subtract(const Duration(days: 3)),
          repsByExercise: const {
            'squat': [8, 8, 8],
          },
        ),
      ];
      final r = Readiness.fromHistory(results, now: now);
      expect(r.level, ReadinessLevel.ready);
      expect(r.suggestedVolumeMultiplier, 1.0);
    });

    test('high missed-rep ratio drives toward cautious/fatigued', () {
      final results = [
        // Prior week: solid sets.
        buildResult(
          planId: 'p',
          finishedAt: now.subtract(const Duration(days: 10)),
          repsByExercise: const {
            'squat': [10, 10, 10, 10],
          },
        ),
        // Recent week: rep counts collapse far below the median.
        buildResult(
          planId: 'p',
          finishedAt: now.subtract(const Duration(days: 2)),
          repsByExercise: const {
            'squat': [4, 3, 4, 3],
          },
        ),
      ];
      final r = Readiness.fromHistory(results, now: now);
      expect(r.level, anyOf(ReadinessLevel.cautious, ReadinessLevel.fatigued));
      expect(r.suggestedVolumeMultiplier, lessThan(1.0));
      expect(r.score, lessThan(0.65));
    });

    test('RPE 10 input shifts score down', () {
      final neutral = Readiness.fromHistory(const [], now: now);
      final stressed = Readiness.fromHistory(
        const [],
        selfReportedRpe: 10,
        now: now,
      );
      expect(stressed.score, lessThan(neutral.score));
      expect(
        stressed.level,
        anyOf(ReadinessLevel.cautious, ReadinessLevel.fatigued),
      );
      expect(stressed.reason, contains('High self-reported effort'));
    });

    test('RPE 1 input shifts score up', () {
      final neutral = Readiness.fromHistory(const [], now: now);
      final easy = Readiness.fromHistory(
        const [],
        selfReportedRpe: 1,
        now: now,
      );
      expect(easy.score, greaterThan(neutral.score));
    });

    test('sleep 4h shifts score down', () {
      final neutral = Readiness.fromHistory(const [], now: now);
      final tired = Readiness.fromHistory(const [], sleepHours: 4.0, now: now);
      expect(tired.score, lessThan(neutral.score));
      expect(tired.reason, contains('sleep'));
    });

    test('sleep 8h does not penalise', () {
      final neutral = Readiness.fromHistory(const [], now: now);
      final rested = Readiness.fromHistory(const [], sleepHours: 8.0, now: now);
      expect(rested.score, equals(neutral.score));
    });

    test('ignores sessions outside the window', () {
      final results = [
        buildResult(
          planId: 'p',
          finishedAt: now.subtract(const Duration(days: 60)),
          repsByExercise: const {
            'squat': [1, 1, 1, 1],
          },
        ),
      ];
      final r = Readiness.fromHistory(results, now: now);
      // No in-window history — falls back to neutral ready.
      expect(r.level, ReadinessLevel.ready);
      expect(r.reason, contains('No recent history'));
    });

    test('respects custom window override', () {
      final results = [
        buildResult(
          planId: 'p',
          finishedAt: now.subtract(const Duration(days: 20)),
          repsByExercise: const {
            'squat': [10, 10],
          },
        ),
      ];
      final defaultWindow = Readiness.fromHistory(results, now: now);
      final wideWindow = Readiness.fromHistory(
        results,
        window: const Duration(days: 30),
        now: now,
      );
      // 20d old session is excluded from the 14d default window but included
      // in the 30d override — the wider window must therefore see signal the
      // default did not.
      expect(defaultWindow.reason, contains('No recent history'));
      expect(wideWindow.reason, isNot(contains('No recent history')));
    });

    test('scores are bounded to 0..1', () {
      final r = Readiness.fromHistory(
        const [],
        selfReportedRpe: 10,
        sleepHours: 0,
        now: now,
      );
      expect(r.score, inInclusiveRange(0.0, 1.0));
    });

    test('TrainingReadiness round-trips through JSON', () {
      final r = Readiness.fromHistory(
        const [],
        selfReportedRpe: 9,
        sleepHours: 5,
        now: now,
      );
      final restored = TrainingReadiness.fromJson(r.toJson());
      expect(restored, equals(r));
    });
  });

  group('Readiness.adjust', () {
    TrainingReadiness sample(ReadinessLevel level) => TrainingReadiness(
      level: level,
      score: switch (level) {
        ReadinessLevel.fresh => 0.95,
        ReadinessLevel.ready => 0.75,
        ReadinessLevel.cautious => 0.5,
        ReadinessLevel.fatigued => 0.2,
      },
      reason: 'test',
      suggestedVolumeMultiplier: 1.0,
      suggestedIntensityMultiplier: 1.0,
    );

    test('fresh returns 1.05 multiplier', () {
      expect(Readiness.adjust(sample(ReadinessLevel.fresh)).multiplier, 1.05);
    });

    test('ready returns 1.0 multiplier', () {
      expect(Readiness.adjust(sample(ReadinessLevel.ready)).multiplier, 1.0);
    });

    test('cautious returns 0.85 multiplier', () {
      expect(
        Readiness.adjust(sample(ReadinessLevel.cautious)).multiplier,
        0.85,
      );
    });

    test('fatigued returns 0.6 multiplier', () {
      expect(Readiness.adjust(sample(ReadinessLevel.fatigued)).multiplier, 0.6);
    });

    test('VolumeAdjustment toJson exposes multiplier and reason', () {
      final a = Readiness.adjust(sample(ReadinessLevel.cautious));
      expect(a.toJson(), {'multiplier': 0.85, 'reason': a.reason});
    });
  });
}
