import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('schemaVersion stamping', () {
    test('WorkoutPlan stamps current schema version', () {
      const plan = WorkoutPlan(id: 'p', name: 'p', exercises: []);
      expect(plan.toJson()['schemaVersion'], kPluginSchemaVersion);
    });

    test('WorkoutResult stamps current schema version', () {
      final result = WorkoutResult(
        planId: 'p',
        startedAt: DateTime.utc(2026),
        finishedAt: DateTime.utc(2026),
        duration: Duration.zero,
        exercises: const [],
      );
      expect(result.toJson()['schemaVersion'], kPluginSchemaVersion);
    });

    test('CardioResult stamps current schema version', () {
      final result = CardioResult(
        planId: 'p',
        planName: 'p',
        discipline: CardioDiscipline.running,
        startedAt: DateTime.utc(2026),
        finishedAt: DateTime.utc(2026),
        duration: Duration.zero,
        laps: const [],
      );
      expect(result.toJson()['schemaVersion'], kPluginSchemaVersion);
    });

    test('WorkoutRunnerState stamps current schema version', () {
      final state = WorkoutRunnerState(
        planId: 'p',
        currentExerciseIndex: 0,
        activeExerciseIndex: null,
        currentSetIndex: 0,
        isActive: true,
        startedAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        performed: const [],
      );
      expect(state.toJson()['schemaVersion'], kPluginSchemaVersion);
    });
  });

  group('legacy JSON (no schemaVersion) still parses', () {
    test('WorkoutPlan from a v0 payload', () {
      final legacy = {
        'id': 'p',
        'name': 'p',
        'exercises': [
          {
            'id': 'ex',
            'name': 'Ex',
            'muscles': [],
            'sets': [
              {'targetReps': 8},
            ],
          },
        ],
      };
      final plan = WorkoutPlan.fromJson(legacy);
      expect(plan.exercises.single.sets.single.targetReps, 8);
      expect(plan.exercises.single.sets.single.type, SetType.working);
    });

    test('WorkoutResult from a v0 payload', () {
      final legacy = {
        'planId': 'p',
        'startedAt': DateTime.utc(2026).toIso8601String(),
        'finishedAt': DateTime.utc(2026).toIso8601String(),
        'duration': 0,
        'exercises': const [],
      };
      final result = WorkoutResult.fromJson(legacy);
      expect(result.totalSets, 0);
    });

    test('WorkoutRunnerState from a v0 payload (no pausedFor)', () {
      final legacy = {
        'planId': 'p',
        'currentExerciseIndex': 0,
        'activeExerciseIndex': null,
        'currentSetIndex': 0,
        'isActive': true,
        'startedAt': DateTime.utc(2026).toIso8601String(),
        'updatedAt': DateTime.utc(2026).toIso8601String(),
        'performed': const [],
      };
      final state = WorkoutRunnerState.fromJson(legacy);
      expect(state.pausedFor, Duration.zero);
    });
  });
}
