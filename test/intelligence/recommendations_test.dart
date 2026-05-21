import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recommendations.fromLastSet', () {
    final target = const WorkoutSet(targetReps: 8, targetWeight: 100.0);

    test('echoes target when no last set', () {
      final s = Recommendations.fromLastSet(null, target);
      expect(s.suggestedReps, 8);
      expect(s.suggestedWeight, 100.0);
      expect(s.suggestedRir, isNull);
      expect(s.confidence, lessThan(0.5));
      expect(s.note, contains('No prior'));
    });

    test('bumps weight when last met target with RIR >= 2', () {
      final last = PerformedSet(
        exerciseIndex: 0,
        setIndex: 0,
        actualReps: 8,
        actualWeight: 100.0,
        rir: 3,
        completedAt: DateTime(2026),
      );
      final s = Recommendations.fromLastSet(last, target);
      expect(s.suggestedWeight, 102.5);
      expect(s.suggestedReps, 8);
      expect(s.confidence, greaterThan(0.7));
    });

    test('holds weight when last missed reps', () {
      final last = PerformedSet(
        exerciseIndex: 0,
        setIndex: 0,
        actualReps: 6,
        actualWeight: 100.0,
        rir: 0,
        completedAt: DateTime(2026),
      );
      final s = Recommendations.fromLastSet(last, target);
      expect(s.suggestedWeight, 100.0);
      expect(s.note, contains('missed'));
    });

    test('holds weight when target met but RIR low', () {
      final last = PerformedSet(
        exerciseIndex: 0,
        setIndex: 0,
        actualReps: 8,
        actualWeight: 100.0,
        rir: 1,
        completedAt: DateTime(2026),
      );
      final s = Recommendations.fromLastSet(last, target);
      expect(s.suggestedWeight, 100.0);
    });

    test('toJson includes weight when present, drops nulls', () {
      final s = Recommendations.fromLastSet(null, target);
      final json = s.toJson();
      expect(json['suggestedReps'], 8);
      expect(json['suggestedWeight'], 100.0);
      expect(json.containsKey('suggestedRir'), isFalse);
      expect(json['confidence'], isA<double>());
    });
  });

  group('Recommendations.fromRpe', () {
    test('extends rest at RIR 0', () {
      final r = Recommendations.fromRpe(0);
      expect(r.duration, const Duration(seconds: 150));
    });

    test('baseline rest at RIR 2-3', () {
      final r = Recommendations.fromRpe(2);
      expect(r.duration, const Duration(seconds: 90));
      final r3 = Recommendations.fromRpe(3);
      expect(r3.duration, const Duration(seconds: 90));
    });

    test('shortens rest at RIR >= 4', () {
      final r = Recommendations.fromRpe(4);
      expect(r.duration, const Duration(seconds: 60));
    });

    test('clamps short rest to >= 30s', () {
      final r = Recommendations.fromRpe(
        5,
        baseline: const Duration(seconds: 40),
      );
      expect(r.duration, const Duration(seconds: 30));
    });

    test('toJson serializes seconds', () {
      final r = Recommendations.fromRpe(2);
      expect(r.toJson()['duration'], 90);
    });
  });

  group('Recommendations.fromFatigue', () {
    test('no deload at low fatigue', () {
      final d = Recommendations.fromFatigue(
        consecutiveMissedSets: 1,
        weeklyVolumeTrendPct: 5,
      );
      expect(d.volumeMultiplier, 1.0);
      expect(d.intensityMultiplier, 1.0);
    });

    test('deload triggered by missed sets', () {
      final d = Recommendations.fromFatigue(
        consecutiveMissedSets: 6,
        weeklyVolumeTrendPct: 0,
      );
      expect(d.volumeMultiplier, 0.6);
      expect(d.intensityMultiplier, 0.85);
      expect(d.reason, contains('missed'));
    });

    test('deload triggered by volume spike', () {
      final d = Recommendations.fromFatigue(
        consecutiveMissedSets: 0,
        weeklyVolumeTrendPct: 35,
      );
      expect(d.volumeMultiplier, 0.6);
      expect(d.reason, contains('volume'));
    });

    test('exactly 30% trend does not deload', () {
      final d = Recommendations.fromFatigue(
        consecutiveMissedSets: 0,
        weeklyVolumeTrendPct: 30,
      );
      expect(d.volumeMultiplier, 1.0);
    });

    test('toJson roundtrip shape', () {
      final d = Recommendations.fromFatigue(
        consecutiveMissedSets: 6,
        weeklyVolumeTrendPct: 0,
      );
      final json = d.toJson();
      expect(json['volumeMultiplier'], 0.6);
      expect(json['intensityMultiplier'], 0.85);
      expect(json['reason'], isA<String>());
    });
  });
}