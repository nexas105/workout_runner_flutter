import 'dart:convert';

import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _workoutPlan(String id, {String name = 'Push day'}) => WorkoutPlan(
  id: id,
  name: name,
  exercises: [
    WorkoutExercise(
      id: 'bench',
      name: 'Bench',
      sets: const [
        WorkoutSet(targetReps: 8, rest: Duration(seconds: 90)),
        WorkoutSet(targetReps: 8, rest: Duration(seconds: 90)),
      ],
    ),
  ],
);

CardioPlan _cardioPlan(String id, {String name = 'Easy run'}) => CardioPlan(
  id: id,
  name: name,
  discipline: CardioDiscipline.running,
  intervals: const [
    CardioInterval(
      id: 'warmup',
      name: 'Warm-up',
      targetDuration: Duration(minutes: 5),
    ),
    CardioInterval(
      id: 'work',
      name: 'Work',
      targetDuration: Duration(minutes: 20),
    ),
  ],
);

Map<String, dynamic> _bundle({
  List<WorkoutPlan> workouts = const [],
  List<CardioPlan> cardio = const [],
}) => {
  'schemaVersion': kPluginSchemaVersion,
  'workoutPlans': workouts.map((p) => p.toJson()).toList(),
  'cardioPlans': cardio.map((p) => p.toJson()).toList(),
};

void main() {
  group('WorkoutImport.fromBundle', () {
    test('imports 2 workout plans + 1 cardio plan from a happy bundle', () {
      final bundle = _bundle(
        workouts: [_workoutPlan('plan_a'), _workoutPlan('plan_b')],
        cardio: [_cardioPlan('cardio_a')],
      );

      final result = WorkoutImport.fromBundle(bundle);

      expect(result.hasErrors, isFalse);
      expect(result.importedWorkouts, hasLength(2));
      expect(result.importedCardio, hasLength(1));
      expect(result.total, 3);
      expect(
        result.importedWorkouts.map((p) => p.id),
        containsAll(<String>['plan_a', 'plan_b']),
      );
      expect(result.importedCardio.single.id, 'cardio_a');
      expect(result.skippedIds, isEmpty);
      expect(result.duplicatedIds, isEmpty);
    });

    test(
      'skip policy: conflicting id is added to skippedIds and not imported',
      () {
        final bundle = _bundle(workouts: [_workoutPlan('plan_a')]);

        final result = WorkoutImport.fromBundle(
          bundle,
          existingPlanIds: const ['plan_a'],
        );

        expect(result.importedWorkouts, isEmpty);
        expect(result.skippedIds, ['plan_a']);
        expect(result.duplicatedIds, isEmpty);
        expect(result.hasErrors, isFalse);
      },
    );

    test(
      'duplicate policy: assigns _imported_1 suffix for first collision',
      () {
        final bundle = _bundle(workouts: [_workoutPlan('plan_a')]);

        final result = WorkoutImport.fromBundle(
          bundle,
          policy: ImportConflictPolicy.duplicate,
          existingPlanIds: const ['plan_a'],
        );

        expect(result.importedWorkouts, hasLength(1));
        expect(result.importedWorkouts.single.id, 'plan_a_imported_1');
        expect(result.duplicatedIds, ['plan_a_imported_1']);
        expect(result.skippedIds, isEmpty);
      },
    );

    test('duplicate policy: bumps suffix when _imported_1 is also taken', () {
      final bundle = _bundle(workouts: [_workoutPlan('plan_a')]);
      final result = WorkoutImport.fromBundle(
        bundle,
        policy: ImportConflictPolicy.duplicate,
        existingPlanIds: const ['plan_a', 'plan_a_imported_1'],
      );
      expect(result.importedWorkouts.single.id, 'plan_a_imported_2');
    });

    test(
      'replace policy: keeps original id, no skipped/duplicated entries',
      () {
        final bundle = _bundle(workouts: [_workoutPlan('plan_a', name: 'New')]);

        final result = WorkoutImport.fromBundle(
          bundle,
          policy: ImportConflictPolicy.replace,
          existingPlanIds: const ['plan_a'],
        );

        expect(result.importedWorkouts.single.id, 'plan_a');
        expect(result.importedWorkouts.single.name, 'New');
        expect(result.skippedIds, isEmpty);
        expect(result.duplicatedIds, isEmpty);
      },
    );

    test(
      'malformed plan produces an ImportError but siblings still import',
      () {
        final bundle = <String, dynamic>{
          'schemaVersion': kPluginSchemaVersion,
          'workoutPlans': <dynamic>[
            <String, dynamic>{'id': 'broken', 'name': 'No exercises field'},
            _workoutPlan('plan_ok').toJson(),
          ],
          'cardioPlans': <dynamic>[],
        };

        final result = WorkoutImport.fromBundle(bundle);

        expect(result.importedWorkouts, hasLength(1));
        expect(result.importedWorkouts.single.id, 'plan_ok');
        expect(result.errors, hasLength(1));
        expect(result.errors.single.planId, 'broken');
        expect(result.errors.single.key, 'workoutPlans[0]');
        expect(result.hasErrors, isTrue);
      },
    );
  });

  group('WorkoutImport.fromJsonString', () {
    test('parses a valid JSON string bundle', () {
      final encoded = jsonEncode(_bundle(workouts: [_workoutPlan('plan_a')]));
      final result = WorkoutImport.fromJsonString(encoded);

      expect(result.importedWorkouts.single.id, 'plan_a');
      expect(result.hasErrors, isFalse);
    });

    test('bad top-level JSON yields a single ImportError and no imports', () {
      final result = WorkoutImport.fromJsonString('{not valid json');

      expect(result.importedWorkouts, isEmpty);
      expect(result.importedCardio, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single.key, 'json');
      expect(result.hasErrors, isTrue);
    });
  });

  group('ImportError / ImportResult JSON shape', () {
    test('ImportError.toJson includes planId only when present', () {
      expect(const ImportError(key: 'k', message: 'm').toJson(), {
        'key': 'k',
        'message': 'm',
      });
      expect(const ImportError(key: 'k', message: 'm', planId: 'p').toJson(), {
        'key': 'k',
        'message': 'm',
        'planId': 'p',
      });
    });

    test('ImportResult.toJson roundtrips through jsonEncode', () {
      final result = WorkoutImport.fromBundle(
        _bundle(workouts: [_workoutPlan('plan_a')]),
      );
      final encoded = jsonEncode(result.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['importedWorkouts'], hasLength(1));
      expect(decoded['skippedIds'], isEmpty);
    });
  });
}
