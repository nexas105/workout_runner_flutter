import 'package:fitness_workout/fitness_workout.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

WorkoutResult _sampleWorkoutResult() {
  final finished = DateTime.utc(2026, 5, 21, 10, 0);
  return WorkoutResult(
    planId: 'plan-1',
    startedAt: DateTime.utc(2026, 5, 21, 9, 15),
    finishedAt: finished,
    duration: const Duration(minutes: 45),
    exercises: [
      PerformedExerciseDetails(
        exerciseId: 'bench',
        exerciseName: 'Bench press',
        sets: [
          PerformedSet(
            exerciseIndex: 0,
            setIndex: 0,
            actualReps: 8,
            actualWeight: 60,
            completedAt: finished,
          ),
        ],
      ),
    ],
  );
}

CardioResult _sampleCardioResult() {
  final completed = DateTime.utc(2026, 5, 21, 10, 30);
  return CardioResult(
    planId: 'cardio-1',
    planName: 'Easy run',
    discipline: CardioDiscipline.running,
    startedAt: DateTime.utc(2026, 5, 21, 10, 0),
    finishedAt: completed,
    duration: const Duration(minutes: 30),
    laps: [
      CardioLap.computed(
        intervalIndex: 0,
        duration: const Duration(minutes: 30),
        distanceMeters: 5000,
        completedAt: completed,
      ),
    ],
  );
}

WorkoutPlan _samplePlan() => const WorkoutPlan(
  id: 'plan-1',
  name: 'Push day',
  exercises: [
    WorkoutExercise(
      id: 'bench',
      name: 'Bench press',
      sets: [WorkoutSet(targetReps: 8, targetWeight: 60)],
    ),
  ],
);

CardioPlan _sampleCardioPlan() => const CardioPlan(
  id: 'cardio-1',
  name: 'Easy run',
  discipline: CardioDiscipline.running,
  intervals: [
    CardioInterval(
      id: 'int-0',
      name: 'Run',
      phase: CardioPhase.work,
      targetDistanceMeters: 5000,
    ),
  ],
);

void main() {
  group('DataExport.bundle', () {
    test('stamps current schema version and timestamp', () {
      final now = DateTime.utc(2026, 5, 21, 12, 0);
      final bundle = DataExport.bundle(exportedAt: now);
      expect(bundle.schemaVersion, kPluginSchemaVersion);
      expect(bundle.exportedAt, now);
      expect(bundle.workoutResults, isEmpty);
      expect(bundle.cardioResults, isEmpty);
      expect(bundle.workoutPlans, isEmpty);
      expect(bundle.cardioPlans, isEmpty);
    });

    test('passes through caller-provided lists', () {
      final bundle = DataExport.bundle(
        workoutResults: [_sampleWorkoutResult()],
        cardioResults: [_sampleCardioResult()],
        workoutPlans: [_samplePlan()],
        cardioPlans: [_sampleCardioPlan()],
      );
      expect(bundle.workoutResults, hasLength(1));
      expect(bundle.cardioResults, hasLength(1));
      expect(bundle.workoutPlans, hasLength(1));
      expect(bundle.cardioPlans, hasLength(1));
    });
  });

  group('DataBundle round-trip', () {
    test('preserves all four lists through toJson/fromJson', () {
      final bundle = DataExport.bundle(
        workoutResults: [_sampleWorkoutResult()],
        cardioResults: [_sampleCardioResult()],
        workoutPlans: [_samplePlan()],
        cardioPlans: [_sampleCardioPlan()],
        exportedAt: DateTime.utc(2026, 5, 21, 12, 0),
      );
      final json = bundle.toJson();
      final restored = DataBundle.fromJson(json);

      expect(restored.schemaVersion, bundle.schemaVersion);
      expect(restored.exportedAt, bundle.exportedAt);
      expect(restored.workoutResults, hasLength(1));
      expect(restored.workoutResults.first.planId, 'plan-1');
      expect(
        restored.workoutResults.first.exercises.first.exerciseName,
        'Bench press',
      );
      expect(restored.cardioResults, hasLength(1));
      expect(restored.cardioResults.first.planName, 'Easy run');
      expect(restored.workoutPlans, hasLength(1));
      expect(restored.workoutPlans.first.name, 'Push day');
      expect(restored.cardioPlans, hasLength(1));
      expect(restored.cardioPlans.first.id, 'cardio-1');
    });

    test('tolerates missing list keys', () {
      final restored = DataBundle.fromJson({
        'schemaVersion': kPluginSchemaVersion,
        'exportedAt': DateTime.utc(2026, 5, 21).toIso8601String(),
      });
      expect(restored.workoutResults, isEmpty);
      expect(restored.cardioResults, isEmpty);
      expect(restored.workoutPlans, isEmpty);
      expect(restored.cardioPlans, isEmpty);
    });
  });

  group('DataExport.toJsonString', () {
    test('produces pretty-printed valid JSON with schemaVersion', () {
      final bundle = DataExport.bundle(
        workoutResults: [_sampleWorkoutResult()],
        exportedAt: DateTime.utc(2026, 5, 21, 12, 0),
      );
      final s = DataExport.toJsonString(bundle);

      expect(s.contains('\n'), isTrue);
      expect(s.contains('  '), isTrue);

      final decoded = jsonDecode(s) as Map<String, dynamic>;
      expect(decoded['schemaVersion'], kPluginSchemaVersion);
      expect(decoded['exportedAt'], isA<String>());
      expect(decoded['workoutResults'], isA<List>());
      expect((decoded['workoutResults'] as List), hasLength(1));
    });
  });
}
