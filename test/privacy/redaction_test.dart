import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutResult _workoutResult() {
  final finished = DateTime.utc(2026, 5, 21, 10, 0);
  return WorkoutResult(
    planId: 'push-day',
    startedAt: DateTime.utc(2026, 5, 21, 9, 15),
    finishedAt: finished,
    duration: const Duration(minutes: 45),
    exercises: [
      PerformedExerciseDetails(
        exerciseId: 'bench',
        exerciseName: 'Bench press',
        met: 6.0,
        categoryId: 'chest',
        sets: [
          PerformedSet(
            exerciseIndex: 0,
            setIndex: 0,
            actualReps: 8,
            actualWeight: 60,
            completedAt: finished,
          ),
          PerformedSet(
            exerciseIndex: 0,
            setIndex: 1,
            actualReps: 6,
            actualWeight: 65,
            completedAt: finished,
          ),
        ],
      ),
      PerformedExerciseDetails(
        exerciseId: 'pushup',
        exerciseName: 'Push up',
        sets: [
          PerformedSet(
            exerciseIndex: 1,
            setIndex: 0,
            actualReps: 15,
            completedAt: finished,
          ),
        ],
      ),
    ],
  );
}

CardioResult _cardioResult() {
  final completed = DateTime.utc(2026, 5, 21, 10, 30);
  return CardioResult(
    planId: 'easy-5k',
    planName: 'Easy 5k',
    discipline: CardioDiscipline.running,
    startedAt: DateTime.utc(2026, 5, 21, 10, 0),
    finishedAt: completed,
    duration: const Duration(minutes: 30),
    laps: [
      CardioLap.computed(
        intervalIndex: 0,
        duration: const Duration(minutes: 30),
        distanceMeters: 5000,
        avgHeartRate: 150,
        completedAt: completed,
      ),
    ],
  );
}

void main() {
  group('Redaction.anonymized (WorkoutResult)', () {
    test('clears planId and replaces exercise names with positional tags', () {
      final original = _workoutResult();
      final anon = Redaction.anonymized(original);

      expect(anon.planId, 'redacted');
      expect(anon.exercises, hasLength(2));
      expect(anon.exercises[0].exerciseName, 'exercise_0');
      expect(anon.exercises[1].exerciseName, 'exercise_1');
    });

    test('keeps durations, stats and set numbers intact', () {
      final original = _workoutResult();
      final anon = Redaction.anonymized(original);

      expect(anon.startedAt, original.startedAt);
      expect(anon.finishedAt, original.finishedAt);
      expect(anon.duration, original.duration);
      expect(anon.totalSets, original.totalSets);
      expect(anon.totalReps, original.totalReps);
      expect(anon.totalVolume, original.totalVolume);
      expect(
        anon.exercises[0].sets.map((s) => s.actualWeight).toList(),
        original.exercises[0].sets.map((s) => s.actualWeight).toList(),
      );
    });
  });

  group('Redaction.anonymizedCardio (CardioResult)', () {
    test('replaces planId and planName with redacted', () {
      final anon = Redaction.anonymizedCardio(_cardioResult());
      expect(anon.planId, 'redacted');
      expect(anon.planName, 'redacted');
    });

    test('keeps numeric stats untouched', () {
      final original = _cardioResult();
      final anon = Redaction.anonymizedCardio(original);
      expect(anon.duration, original.duration);
      expect(anon.totalLaps, original.totalLaps);
      expect(anon.totalDistanceMeters, original.totalDistanceMeters);
      expect(anon.discipline, original.discipline);
    });
  });

  group('Redaction.redactedJson', () {
    test('removes default keys at the top level', () {
      final json = <String, dynamic>{
        'planId': 'push-day',
        'planName': 'Push day',
        'duration': 600,
        'notes': 'felt strong',
        'meta': {'source': 'app'},
        'exerciseName': 'Bench press',
        'actualReps': 8,
      };
      final out = Redaction.redactedJson(json);
      expect(out.containsKey('planId'), isFalse);
      expect(out.containsKey('planName'), isFalse);
      expect(out.containsKey('notes'), isFalse);
      expect(out.containsKey('meta'), isFalse);
      expect(out.containsKey('exerciseName'), isFalse);
      expect(out['duration'], 600);
      expect(out['actualReps'], 8);
    });

    test('removes keys at any nesting depth (maps and lists)', () {
      final json = <String, dynamic>{
        'duration': 600,
        'exercises': [
          {
            'exerciseId': 'bench',
            'exerciseName': 'Bench press',
            'sets': [
              {'actualReps': 8, 'notes': 'top set'},
              {'actualReps': 6, 'notes': 'backoff'},
            ],
            'meta': {'tags': 'should be dropped'},
          },
        ],
        'wrapper': {
          'inner': {'planId': 'nested', 'kept': 'ok'},
        },
      };
      final out = Redaction.redactedJson(json);
      final exercises = out['exercises'] as List;
      final first = exercises.first as Map<String, dynamic>;
      expect(first.containsKey('exerciseName'), isFalse);
      expect(first.containsKey('meta'), isFalse);
      expect(first['exerciseId'], 'bench');
      final sets = first['sets'] as List;
      for (final s in sets.cast<Map>()) {
        expect(s.containsKey('notes'), isFalse);
        expect(s['actualReps'], isA<int>());
      }
      final inner = (out['wrapper'] as Map)['inner'] as Map;
      expect(inner.containsKey('planId'), isFalse);
      expect(inner['kept'], 'ok');
    });

    test('respects custom drop set', () {
      final json = <String, dynamic>{
        'planId': 'keep me',
        'secret': 'drop me',
        'nested': {'secret': 'gone', 'planId': 'still kept'},
      };
      final out = Redaction.redactedJson(json, drop: const {'secret'});
      expect(out['planId'], 'keep me');
      expect(out.containsKey('secret'), isFalse);
      final nested = out['nested'] as Map;
      expect(nested.containsKey('secret'), isFalse);
      expect(nested['planId'], 'still kept');
    });
  });
}