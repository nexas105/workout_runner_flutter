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
  final pec = Muscle(id: 'm-pec', name: 'Pectoralis Major', group: 'chest');
  final triceps = Muscle(id: 'm-tri', name: 'Triceps', group: 'arms');
  final lats = Muscle(id: 'm-lat', name: 'Latissimus Dorsi', group: 'back');

  final benchBarbell = _ex(
    id: 'bench-bb',
    name: 'Barbell Bench Press',
    category: chest,
    muscles: [pec, triceps],
    meta: {'movementPattern': 'horizontalPush', 'equipment': 'barbell'},
  );
  final benchDumbbell = _ex(
    id: 'bench-db',
    name: 'Dumbbell Bench Press',
    category: chest,
    muscles: [pec, triceps],
    meta: {'movementPattern': 'HorizontalPush', 'equipment': 'dumbbell'},
  );
  final benchMachine = _ex(
    id: 'bench-mc',
    name: 'Machine Chest Press',
    category: chest,
    muscles: [pec, triceps],
    meta: {'movementPattern': 'horizontalPush', 'equipment': 'machine'},
  );
  final pushUp = _ex(
    id: 'pushup',
    name: 'Push Up',
    category: chest,
    muscles: [pec, triceps],
    meta: {'movementPattern': 'horizontalPush', 'equipment': 'bodyweight'},
  );
  final pecDeck = _ex(
    id: 'pec-deck',
    name: 'Pec Deck',
    category: chest,
    muscles: [pec],
    meta: {'movementPattern': 'horizontalFly', 'equipment': 'machine'},
  );
  final dip = _ex(
    id: 'dip',
    name: 'Dip',
    category: chest,
    muscles: [triceps],
    meta: {'equipment': 'bodyweight'},
  );
  final pullUp = _ex(
    id: 'pullup',
    name: 'Pull Up',
    category: back,
    muscles: [lats],
    meta: {'movementPattern': 'verticalPull', 'equipment': 'bodyweight'},
  );

  final catalog = [
    benchBarbell,
    benchDumbbell,
    benchMachine,
    pushUp,
    pecDeck,
    dip,
    pullUp,
  ];

  test('source exercise is excluded from results', () {
    final results = ExerciseAlternatives.forExercise(benchBarbell, catalog);
    expect(results.any((s) => s.exercise.id == benchBarbell.id), isFalse);
  });

  test('same movement pattern ranks above same muscle group', () {
    final results = ExerciseAlternatives.forExercise(benchBarbell, catalog);
    final benchDbIdx = results.indexWhere(
      (s) => s.exercise.id == benchDumbbell.id,
    );
    final pecDeckIdx = results.indexWhere(
      (s) => s.exercise.id == pecDeck.id,
    );
    expect(benchDbIdx, greaterThanOrEqualTo(0));
    expect(pecDeckIdx, greaterThanOrEqualTo(0));
    expect(benchDbIdx, lessThan(pecDeckIdx));

    final benchDbScore = results[benchDbIdx];
    final pecDeckScore = results[pecDeckIdx];
    expect(
      benchDbScore.match,
      AlternativeMatch.sameMovementDifferentEquipment,
    );
    expect(benchDbScore.score, 0.8);
    expect(pecDeckScore.match, AlternativeMatch.sameMuscleGroup);
    expect(pecDeckScore.score, 0.6);
  });

  test('same movement & same equipment scores 1.0', () {
    final extraBarbell = _ex(
      id: 'incline-bb',
      name: 'Incline Barbell Press',
      category: chest,
      muscles: [pec],
      meta: {'movementPattern': 'horizontalPush', 'equipment': 'barbell'},
    );
    final results = ExerciseAlternatives.forExercise(benchBarbell, [
      ...catalog,
      extraBarbell,
    ]);
    final top = results.first;
    expect(top.exercise.id, extraBarbell.id);
    expect(top.score, 1.0);
    expect(top.match, AlternativeMatch.sameMovementSameEquipment);
  });

  test('available equipment filters out unavailable alternatives', () {
    final results = ExerciseAlternatives.forExercise(
      benchBarbell,
      catalog,
      availableEquipment: {'bodyweight', 'dumbbell'},
    );
    final ids = results.map((s) => s.exercise.id).toSet();
    expect(ids.contains(benchMachine.id), isFalse);
    expect(ids.contains(pecDeck.id), isFalse);
    expect(ids.contains(benchDumbbell.id), isTrue);
    expect(ids.contains(pushUp.id), isTrue);
  });

  test('returns at most limit results, sorted by score then name', () {
    final results = ExerciseAlternatives.forExercise(
      benchBarbell,
      catalog,
      limit: 3,
    );
    expect(results.length, 3);
    for (var i = 1; i < results.length; i++) {
      final prev = results[i - 1];
      final cur = results[i];
      expect(prev.score >= cur.score, isTrue);
      if (prev.score == cur.score) {
        expect(
          prev.exercise.name.toLowerCase().compareTo(
                cur.exercise.name.toLowerCase(),
              ) <=
              0,
          isTrue,
        );
      }
    }
  });

  test('alphabetical tie-break within same score', () {
    final a = _ex(
      id: 'a',
      name: 'Alpha Press',
      category: chest,
      muscles: [pec],
      meta: {'movementPattern': 'horizontalPush', 'equipment': 'cable'},
    );
    final b = _ex(
      id: 'b',
      name: 'Bravo Press',
      category: chest,
      muscles: [pec],
      meta: {'movementPattern': 'horizontalPush', 'equipment': 'cable'},
    );
    final results = ExerciseAlternatives.forExercise(benchBarbell, [a, b]);
    expect(results.first.exercise.id, 'a');
    expect(results[1].exercise.id, 'b');
  });

  test('sameCategoryFallback when no movement or muscle match', () {
    final source = _ex(
      id: 'src',
      name: 'Source',
      category: chest,
      muscles: [Muscle(id: 'unique', name: 'Unique', group: 'unique-grp')],
      meta: {'movementPattern': 'unique'},
    );
    final fallback = _ex(
      id: 'fb',
      name: 'Fallback Exercise',
      category: chest,
      muscles: [Muscle(id: 'other', name: 'Other', group: 'other-grp')],
    );
    final results = ExerciseAlternatives.forExercise(source, [fallback]);
    expect(results.length, 1);
    expect(results.first.match, AlternativeMatch.sameCategoryFallback);
    expect(results.first.score, 0.3);
  });

  test('group() wraps alternatives ordered by score', () {
    final group = ExerciseAlternatives.group(benchBarbell, catalog);
    expect(group.source.id, benchBarbell.id);
    expect(group.alternatives.isNotEmpty, isTrue);
    final ranked = ExerciseAlternatives.forExercise(benchBarbell, catalog);
    expect(
      group.alternatives.map((e) => e.id).toList(),
      ranked.map((s) => s.exercise.id).toList(),
    );
  });
}
