import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutExercise _ex({
  required String id,
  required String name,
  ExerciseCategory? category,
  List<Muscle> muscles = const [],
  Map<String, dynamic>? meta,
}) => WorkoutExercise(
  id: id,
  name: name,
  category: category,
  muscles: muscles,
  meta: meta,
);

void main() {
  final chest = ExerciseCategory(id: 'cat-chest', name: 'Chest');
  final back = ExerciseCategory(id: 'cat-back', name: 'Back');
  final legs = ExerciseCategory(id: 'cat-legs', name: 'Legs');

  final pec = Muscle(id: 'm-pec', name: 'Pectoralis', group: 'chest');
  final tri = Muscle(id: 'm-tri', name: 'Triceps', group: 'arms');
  final lat = Muscle(id: 'm-lat', name: 'Lats', group: 'back');
  final biceps = Muscle(id: 'm-bi', name: 'Biceps', group: 'arms');
  final quad = Muscle(id: 'm-quad', name: 'Quadriceps', group: 'legs');

  final benchPress = _ex(
    id: 'bench-press',
    name: 'Bench press',
    category: chest,
    muscles: [pec, tri],
    meta: {'equipment': 'barbell'},
  );
  final bentOverRow = _ex(
    id: 'bent-row',
    name: 'Bent-over row',
    category: back,
    muscles: [lat, biceps],
    meta: {'equipment': 'barbell'},
  );
  final dumbbellCurl = _ex(
    id: 'db-curl',
    name: 'Dumbbell curl',
    category: back,
    muscles: [biceps],
    meta: {'equipment': 'dumbbell'},
  );
  final squat = _ex(
    id: 'squat',
    name: 'Squat',
    category: legs,
    muscles: [quad],
    meta: {'equipment': 'barbell'},
  );
  final pushup = _ex(
    id: 'pushup',
    name: 'Push-up',
    category: chest,
    muscles: [pec, tri],
  );

  final source = [benchPress, bentOverRow, dumbbellCurl, squat, pushup];

  group('ExerciseIndex', () {
    final index = ExerciseIndex(source);

    test('byId returns expected exercise', () {
      expect(index.byId('bench-press'), same(benchPress));
      expect(index.byId('squat'), same(squat));
    });

    test('byId returns null for unknown id', () {
      expect(index.byId('does-not-exist'), isNull);
    });

    test('byMuscle returns exercises listing that muscle id', () {
      final triceps = index.byMuscle('m-tri');
      expect(triceps, containsAll([benchPress, pushup]));
      expect(triceps.length, 2);

      final bicepsHits = index.byMuscle('m-bi');
      expect(bicepsHits, containsAll([bentOverRow, dumbbellCurl]));
      expect(bicepsHits.length, 2);
    });

    test('byMuscle returns empty list for unknown muscle', () {
      expect(index.byMuscle('m-unknown'), isEmpty);
    });

    test('byMuscleGroup aggregates across muscle ids in that group', () {
      final arms = index.byMuscleGroup('arms');
      expect(arms, containsAll([benchPress, bentOverRow, dumbbellCurl, pushup]));
      expect(arms.length, 4);

      final chestGroup = index.byMuscleGroup('chest');
      expect(chestGroup, containsAll([benchPress, pushup]));
      expect(chestGroup.length, 2);
    });

    test('byCategory returns exercises for that category id', () {
      expect(index.byCategory('cat-chest'), containsAll([benchPress, pushup]));
      expect(index.byCategory('cat-legs'), [squat]);
    });

    test('byEquipment reads from meta correctly', () {
      final barbell = index.byEquipment('barbell');
      expect(barbell, containsAll([benchPress, bentOverRow, squat]));
      expect(barbell.length, 3);
      expect(index.byEquipment('dumbbell'), [dumbbellCurl]);
    });

    test('byEquipment returns empty when nothing matches', () {
      expect(index.byEquipment('kettlebell'), isEmpty);
    });

    test("byPrefix('be') matches Bench press and Bent-over row", () {
      final hits = index.byPrefix('be');
      expect(hits, containsAll([benchPress, bentOverRow]));
      expect(hits.contains(squat), isFalse);
      expect(hits.contains(pushup), isFalse);
    });

    test('byPrefix uses only first 3 chars (lowercased)', () {
      final hits = index.byPrefix('BENCH');
      expect(hits, contains(benchPress));
      expect(hits, contains(bentOverRow));
    });

    test('byPrefix returns empty for empty input', () {
      expect(index.byPrefix(''), isEmpty);
    });

    test('muscleIds enumerates every indexed muscle', () {
      expect(
        index.muscleIds.toSet(),
        {'m-pec', 'm-tri', 'm-lat', 'm-bi', 'm-quad'},
      );
    });

    test('muscleGroups enumerates every indexed group', () {
      expect(
        index.muscleGroups.toSet(),
        {'chest', 'arms', 'back', 'legs'},
      );
    });

    test('categoryIds enumerates every indexed category', () {
      expect(
        index.categoryIds.toSet(),
        {'cat-chest', 'cat-back', 'cat-legs'},
      );
    });

    test('equipmentTypes enumerates every indexed equipment', () {
      expect(index.equipmentTypes.toSet(), {'barbell', 'dumbbell'});
    });

    test('public lookups return unmodifiable lists', () {
      final list = index.byMuscle('m-tri');
      expect(() => list.add(squat), throwsUnsupportedError);
    });

    test('handles exercises with missing meta gracefully', () {
      final noMetaIndex = ExerciseIndex([
        _ex(id: 'a', name: 'Alpha', muscles: [pec]),
      ]);
      expect(noMetaIndex.byEquipment('barbell'), isEmpty);
      expect(noMetaIndex.equipmentTypes, isEmpty);
      expect(noMetaIndex.byId('a'), isNotNull);
    });
  });

  group('CatalogSnapshot', () {
    test('CatalogSnapshot.from sets a non-null builtAt', () {
      final before = DateTime.now();
      final snap = CatalogSnapshot.from(source);
      final after = DateTime.now();
      expect(snap.builtAt, isNotNull);
      expect(snap.builtAt.isBefore(before), isFalse);
      expect(snap.builtAt.isAfter(after), isFalse);
      expect(snap.index.byId('squat'), same(squat));
    });
  });
}
