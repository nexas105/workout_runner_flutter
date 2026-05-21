import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutExercise _ex({
  required String id,
  required String name,
  String? description,
  ExerciseCategory? category,
  List<Muscle> muscles = const [],
  Map<String, dynamic>? meta,
}) => WorkoutExercise(
  id: id,
  name: name,
  description: description,
  category: category,
  muscles: muscles,
  meta: meta,
);

void main() {
  final chest = ExerciseCategory(id: 'cat-chest', name: 'Chest');
  final back = ExerciseCategory(id: 'cat-back', name: 'Back');
  final pectoralis = Muscle(
    id: 'm-pec',
    name: 'Pectoralis Major',
    group: 'chest',
  );
  final triceps = Muscle(id: 'm-tri', name: 'Triceps', group: 'arms');
  final lats = Muscle(id: 'm-lat', name: 'Latissimus Dorsi', group: 'back');

  final source = <WorkoutExercise>[
    _ex(
      id: 'bench',
      name: 'Bench Press',
      description: 'Flat barbell pressing movement',
      category: chest,
      muscles: [pectoralis, triceps],
      meta: {
        'aliases': ['BP', 'Flat Bench'],
        'equipment': 'barbell',
        'movementPattern': 'push',
      },
    ),
    _ex(
      id: 'incline-bench',
      name: 'Incline Bench Press',
      category: chest,
      muscles: [pectoralis, triceps],
      meta: {
        'equipment': 'barbell',
        'movementPattern': 'push',
      },
    ),
    _ex(
      id: 'pullup',
      name: 'Pull Up',
      description: 'Bodyweight back movement',
      category: back,
      muscles: [lats],
      meta: {
        'aliases': ['Chin Over Bar'],
        'equipment': 'bodyweight',
        'movementPattern': 'pull',
      },
    ),
    _ex(
      id: 'row',
      name: 'Bent Over Row',
      category: back,
      muscles: [lats],
      meta: {
        'equipment': 'barbell',
        'movementPattern': 'pull',
      },
    ),
  ];

  group('ExerciseSearch.query', () {
    test('empty text returns the full list, preserving order', () {
      final result = ExerciseSearch.query(source, '');
      expect(result, equals(source));
      final whitespace = ExerciseSearch.query(source, '   ');
      expect(whitespace, equals(source));
    });

    test('multi-token AND match across name and category', () {
      final result = ExerciseSearch.query(source, 'bench chest');
      expect(result.map((e) => e.id), ['bench', 'incline-bench']);
    });

    test('alias hit via meta', () {
      final result = ExerciseSearch.query(source, 'bp');
      expect(result.map((e) => e.id), contains('bench'));
      expect(result.first.id, 'bench');
    });

    test('exact name match ranks before prefix and contains', () {
      final result = ExerciseSearch.query(source, 'bench press');
      expect(result.first.id, 'bench');
      expect(result.map((e) => e.id), containsAll(['bench', 'incline-bench']));
    });

    test('non-matching token excludes the exercise', () {
      final result = ExerciseSearch.query(source, 'bench nonsense');
      expect(result, isEmpty);
    });

    test('matches description', () {
      final result = ExerciseSearch.query(source, 'bodyweight');
      expect(result.map((e) => e.id), ['pullup']);
    });
  });

  group('ExerciseSearch.filter', () {
    test('by category', () {
      final result = ExerciseSearch.filter(source, categoryId: 'cat-back');
      expect(result.map((e) => e.id), ['pullup', 'row']);
    });

    test('by muscle requires all listed muscles', () {
      final result = ExerciseSearch.filter(
        source,
        muscleIds: {'m-pec', 'm-tri'},
      );
      expect(result.map((e) => e.id), ['bench', 'incline-bench']);

      final none = ExerciseSearch.filter(source, muscleIds: {'m-pec', 'm-lat'});
      expect(none, isEmpty);
    });

    test('by category and muscle combined', () {
      final result = ExerciseSearch.filter(
        source,
        categoryId: 'cat-chest',
        muscleIds: {'m-pec'},
      );
      expect(result.map((e) => e.id), ['bench', 'incline-bench']);
    });

    test('by equipment via meta', () {
      final result = ExerciseSearch.filter(
        source,
        equipmentMetaKey: 'bodyweight',
      );
      expect(result.map((e) => e.id), ['pullup']);
    });

    test('by movement pattern via meta', () {
      final result = ExerciseSearch.filter(
        source,
        movementPatternMetaKey: 'pull',
      );
      expect(result.map((e) => e.id), ['pullup', 'row']);
    });
  });

  group('ExerciseSearch.suggest', () {
    test('prefix matches come first', () {
      final result = ExerciseSearch.suggest(source, 'be');
      expect(result, contains('Bench Press'));
      expect(result.first, 'Bench Press');
    });

    test('alias suggestions surface', () {
      final result = ExerciseSearch.suggest(source, 'flat');
      expect(result, contains('Flat Bench'));
    });

    test('limit caps the result size', () {
      final result = ExerciseSearch.suggest(source, 'b', limit: 2);
      expect(result.length, 2);
    });

    test('empty partial returns nothing', () {
      expect(ExerciseSearch.suggest(source, ''), isEmpty);
      expect(ExerciseSearch.suggest(source, '   '), isEmpty);
    });
  });
}
