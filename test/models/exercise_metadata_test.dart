import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutExercise metadata', () {
    test('round-trips equipment, movement pattern, difficulty and aliases', () {
      const e = WorkoutExercise(
        id: 'bench',
        name: 'Bench press',
        equipment: ExerciseEquipment.barbell,
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.intermediate,
        unilateral: false,
        aliases: ['flat bench', 'bench'],
        searchTerms: ['horizontal push', 'chest'],
      );

      final round = WorkoutExercise.fromJson(e.toJson());
      expect(round.equipment, ExerciseEquipment.barbell);
      expect(round.movementPattern, MovementPattern.push);
      expect(round.difficulty, ExerciseDifficulty.intermediate);
      expect(round.aliases, ['flat bench', 'bench']);
      expect(round.searchTerms, ['horizontal push', 'chest']);
    });

    test('unilateral defaults to false and is preserved through JSON', () {
      const lunge = WorkoutExercise(
        id: 'lunge',
        name: 'Lunge',
        movementPattern: MovementPattern.lunge,
        unilateral: true,
      );
      expect(WorkoutExercise.fromJson(lunge.toJson()).unilateral, isTrue);

      const back = WorkoutExercise(id: 'a', name: 'A');
      expect(WorkoutExercise.fromJson(back.toJson()).unilateral, isFalse);
    });

    test('aliases / searchTerms are lowercased and trimmed on read', () {
      final raw = {
        'id': 'a',
        'name': 'A',
        'muscles': const [],
        'sets': const [],
        'aliases': ['  Flat Bench  ', 'BENCH'],
        'searchTerms': ['Chest'],
      };
      final e = WorkoutExercise.fromJson(raw);
      expect(e.aliases, ['flat bench', 'bench']);
      expect(e.searchTerms, ['chest']);
    });

    test('legacy meta-only payload still parses equipment/aliases', () {
      final legacy = {
        'id': 'a',
        'name': 'A',
        'muscles': const [],
        'sets': const [],
        'meta': {
          'equipment': 'dumbbell',
          'movementPattern': 'pull',
          'aliases': ['dumbbell row'],
        },
      };
      final e = WorkoutExercise.fromJson(legacy);
      expect(e.equipment, ExerciseEquipment.dumbbell);
      expect(e.movementPattern, MovementPattern.pull);
      expect(e.aliases, ['dumbbell row']);
    });

    test('unknown enum ids fall back gracefully', () {
      final raw = {
        'id': 'a',
        'name': 'A',
        'muscles': const [],
        'sets': const [],
        'equipment': 'mysterytron',
        'movementPattern': 'mysterypattern',
        'difficulty': 'godlike',
      };
      final e = WorkoutExercise.fromJson(raw);
      // Unknown equipment lands on `other`, unknown movement/difficulty → null.
      expect(e.equipment, ExerciseEquipment.other);
      expect(e.movementPattern, isNull);
      expect(e.difficulty, isNull);
    });
  });
}
