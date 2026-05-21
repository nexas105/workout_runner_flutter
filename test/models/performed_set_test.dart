import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerformedSet', () {
    test('round-trips through JSON including all optional fields', () {
      final completedAt = DateTime.utc(2026, 5, 21, 10, 30, 0);
      final set = PerformedSet(
        exerciseIndex: 1,
        setIndex: 2,
        actualReps: 9,
        actualWeight: 62.5,
        rir: 2,
        pause: const Duration(seconds: 75),
        duration: const Duration(seconds: 42),
        completedAt: completedAt,
      );

      final json = set.toJson();
      expect(json['pause'], 75);
      expect(json['duration'], 42);

      final round = PerformedSet.fromJson(json);

      expect(round.exerciseIndex, 1);
      expect(round.setIndex, 2);
      expect(round.actualReps, 9);
      expect(round.actualWeight, 62.5);
      expect(round.rir, 2);
      expect(round.pause, const Duration(seconds: 75));
      expect(round.duration, const Duration(seconds: 42));
      expect(round.completedAt.toUtc(), completedAt);
    });

    test('round-trips through JSON with only required fields', () {
      final completedAt = DateTime.utc(2026, 5, 21);
      final set = PerformedSet(
        exerciseIndex: 0,
        setIndex: 0,
        actualReps: 10,
        completedAt: completedAt,
      );

      final json = set.toJson();
      expect(json.containsKey('actualWeight'), isFalse);
      expect(json.containsKey('rir'), isFalse);
      expect(json.containsKey('pause'), isFalse);
      expect(json.containsKey('duration'), isFalse);

      final round = PerformedSet.fromJson(json);

      expect(round.actualReps, 10);
      expect(round.actualWeight, isNull);
      expect(round.rir, isNull);
      expect(round.pause, isNull);
      expect(round.duration, isNull);
    });

    test('fromJson accepts the new "pause" key', () {
      final json = {
        'exerciseIndex': 0,
        'setIndex': 0,
        'actualReps': 8,
        'pause': 60,
        'completedAt': DateTime.utc(2026, 5, 21).toIso8601String(),
      };

      final set = PerformedSet.fromJson(json);

      expect(set.pause, const Duration(seconds: 60));
    });

    test(
      'fromJson falls back to legacy "restTaken" key when "pause" missing',
      () {
        final json = {
          'exerciseIndex': 0,
          'setIndex': 0,
          'actualReps': 8,
          'restTaken': 90,
          'completedAt': DateTime.utc(2026, 5, 21).toIso8601String(),
        };

        final set = PerformedSet.fromJson(json);

        expect(set.pause, const Duration(seconds: 90));
      },
    );

    test('round-trips with a non-default set type', () {
      final completedAt = DateTime.utc(2026, 5, 21);
      final set = PerformedSet(
        exerciseIndex: 0,
        setIndex: 0,
        actualReps: 0,
        type: SetType.amrap,
        completedAt: completedAt,
      );

      final json = set.toJson();
      expect(json['type'], 'amrap');

      final round = PerformedSet.fromJson(json);
      expect(round.type, SetType.amrap);
    });

    test('toJson omits the type field for working sets', () {
      final json =
          PerformedSet(
            exerciseIndex: 0,
            setIndex: 0,
            actualReps: 10,
            completedAt: DateTime.utc(2026, 5, 21),
          ).toJson();
      expect(json.containsKey('type'), isFalse);
    });

    test(
      'fromJson prefers "pause" over legacy "restTaken" when both present',
      () {
        final json = {
          'exerciseIndex': 0,
          'setIndex': 0,
          'actualReps': 8,
          'pause': 60,
          'restTaken': 90,
          'completedAt': DateTime.utc(2026, 5, 21).toIso8601String(),
        };

        final set = PerformedSet.fromJson(json);

        expect(set.pause, const Duration(seconds: 60));
      },
    );
  });
}
