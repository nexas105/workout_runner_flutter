import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutSet', () {
    test('round-trips through JSON with all fields', () {
      const set = WorkoutSet(
        targetReps: 8,
        targetWeight: 60.0,
        rest: Duration(seconds: 90),
      );

      final round = WorkoutSet.fromJson(set.toJson());

      expect(round.targetReps, 8);
      expect(round.targetWeight, 60.0);
      expect(round.rest, const Duration(seconds: 90));
    });

    test('round-trips through JSON with only required field', () {
      const set = WorkoutSet(targetReps: 10);

      final round = WorkoutSet.fromJson(set.toJson());

      expect(round.targetReps, 10);
      expect(round.targetWeight, isNull);
      expect(round.rest, isNull);
      expect(round.type, SetType.working);
      expect(round.targetDuration, isNull);
    });

    test('default type is working and omitted from JSON', () {
      const set = WorkoutSet(targetReps: 8);
      expect(set.type, SetType.working);
      expect(set.toJson().containsKey('type'), isFalse);
    });

    test('round-trips warmup/amrap/timed with target duration', () {
      const warmup = WorkoutSet(targetReps: 5, type: SetType.warmup);
      const amrap = WorkoutSet(
        targetReps: 0,
        type: SetType.amrap,
        targetDuration: Duration(seconds: 60),
      );
      const timed = WorkoutSet(
        targetReps: 0,
        type: SetType.timed,
        targetDuration: Duration(seconds: 45),
      );

      expect(WorkoutSet.fromJson(warmup.toJson()).type, SetType.warmup);

      final amrapRound = WorkoutSet.fromJson(amrap.toJson());
      expect(amrapRound.type, SetType.amrap);
      expect(amrapRound.targetDuration, const Duration(seconds: 60));
      expect(amrapRound.isTimed, isTrue);

      final timedRound = WorkoutSet.fromJson(timed.toJson());
      expect(timedRound.type, SetType.timed);
      expect(timedRound.targetDuration, const Duration(seconds: 45));
    });

    test('unknown type id falls back to working', () {
      final raw = {'targetReps': 8, 'type': 'mystery'};
      expect(WorkoutSet.fromJson(raw).type, SetType.working);
    });
  });

  group('WorkoutExercise', () {
    test('round-trips through JSON with category and muscles', () {
      final exercise = WorkoutExercise(
        id: 'ex_bench',
        name: 'Bench press',
        description: 'Flat barbell bench press',
        category: DefaultCategories.strength,
        muscles: const [DefaultMuscles.chest, DefaultMuscles.triceps],
        sets: const [
          WorkoutSet(
            targetReps: 8,
            targetWeight: 60,
            rest: Duration(seconds: 90),
          ),
          WorkoutSet(
            targetReps: 8,
            targetWeight: 60,
            rest: Duration(seconds: 90),
          ),
        ],
        notes: 'pause at chest',
        meta: const {'tag': 'main'},
      );

      final round = WorkoutExercise.fromJson(exercise.toJson());

      expect(round.id, 'ex_bench');
      expect(round.name, 'Bench press');
      expect(round.description, 'Flat barbell bench press');
      expect(round.category, isNotNull);
      expect(round.category!.id, DefaultCategories.strength.id);
      expect(round.muscles.length, 2);
      expect(round.muscles[0].id, DefaultMuscles.chest.id);
      expect(round.muscles[1].id, DefaultMuscles.triceps.id);
      expect(round.sets.length, 2);
      expect(round.sets.first.targetReps, 8);
      expect(round.sets.first.targetWeight, 60);
      expect(round.notes, 'pause at chest');
      expect(round.meta, equals({'tag': 'main'}));
    });

    test('round-trips through JSON without category', () {
      const exercise = WorkoutExercise(
        id: 'ex_pushups',
        name: 'Push-ups',
        sets: [WorkoutSet(targetReps: 12)],
      );

      final round = WorkoutExercise.fromJson(exercise.toJson());

      expect(round.id, 'ex_pushups');
      expect(round.category, isNull);
      expect(round.muscles, isEmpty);
      expect(round.sets.length, 1);
    });

    test('copyWith overrides only specified fields', () {
      const exercise = WorkoutExercise(
        id: 'ex1',
        name: 'Bench',
        sets: [WorkoutSet(targetReps: 8)],
      );

      final copy = exercise.copyWith(
        name: 'Incline bench',
        sets: const [WorkoutSet(targetReps: 10)],
      );

      expect(copy.id, 'ex1');
      expect(copy.name, 'Incline bench');
      expect(copy.sets.first.targetReps, 10);
    });
  });

  group('WorkoutPlan', () {
    test('round-trips through JSON with nested exercises', () {
      final plan = WorkoutPlan(
        id: 'plan_a',
        name: 'Plan A',
        description: 'Upper body',
        exercises: const [
          WorkoutExercise(
            id: 'ex_bench',
            name: 'Bench press',
            category: ExerciseCategory(id: 'cat_strength', name: 'Strength'),
            muscles: [Muscle(id: 'm_chest', name: 'Chest', group: 'upper')],
            sets: [WorkoutSet(targetReps: 8, targetWeight: 60)],
          ),
        ],
        meta: const {'level': 'beginner'},
      );

      final round = WorkoutPlan.fromJson(plan.toJson());

      expect(round.id, 'plan_a');
      expect(round.name, 'Plan A');
      expect(round.description, 'Upper body');
      expect(round.exercises.length, 1);
      expect(round.exercises.first.id, 'ex_bench');
      expect(round.exercises.first.category?.name, 'Strength');
      expect(round.exercises.first.muscles.first.group, 'upper');
      expect(round.meta, equals({'level': 'beginner'}));
    });

    test('JSON-string round-trip via toJsonString / fromJsonString', () {
      final plan = WorkoutPlan(
        id: 'p1',
        name: 'P',
        exercises: const [
          WorkoutExercise(
            id: 'e1',
            name: 'E',
            sets: [WorkoutSet(targetReps: 5)],
          ),
        ],
      );

      final round = WorkoutPlan.fromJsonString(plan.toJsonString());

      expect(round.id, 'p1');
      expect(round.exercises.first.id, 'e1');
    });

    test('copyWith overrides only specified fields', () {
      const plan = WorkoutPlan(id: 'p1', name: 'Original', exercises: []);

      final copy = plan.copyWith(
        name: 'Renamed',
        exercises: const [WorkoutExercise(id: 'e1', name: 'E')],
      );

      expect(copy.id, 'p1');
      expect(copy.name, 'Renamed');
      expect(copy.exercises.length, 1);
    });
  });
}
