import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _ws({
  int reps = 8,
  double? weight = 100,
  SetType type = SetType.working,
}) => WorkoutSet(targetReps: reps, targetWeight: weight, type: type);

WorkoutExercise _ex(String id, List<WorkoutSet> sets) =>
    WorkoutExercise(id: id, name: 'Ex $id', sets: sets);

WorkoutPlan _plan({int workingSets = 4}) {
  final sets = List<WorkoutSet>.generate(
    workingSets,
    (_) => _ws(reps: 10, weight: 100),
  );
  return WorkoutPlan(
    id: 'push',
    name: 'Push Day',
    exercises: [_ex('a', sets), _ex('b', sets), _ex('c', sets)],
  );
}

void main() {
  group('DeloadPlan.from', () {
    test('balanced keeps ceil(sets * 0.6) and reduces reps/weight', () {
      final p = _plan(workingSets: 4);
      final d = DeloadPlan.from(p, strategy: DeloadStrategy.balanced);

      expect(d.exercises.length, 3);
      for (final ex in d.exercises) {
        expect(ex.sets.length, 3);
        for (final s in ex.sets) {
          expect(s.targetReps, 9);
          expect(s.targetWeight, 70.0);
          expect(s.type, SetType.working);
        }
      }
    });

    test('volume strategy reduces sets more than weight', () {
      final p = _plan(workingSets: 4);
      final d = DeloadPlan.from(p, strategy: DeloadStrategy.volume);

      final origSets = p.exercises.first.sets.length;
      final newSets = d.exercises.first.sets.length;
      final setReduction = (origSets - newSets) / origSets;

      final origW = p.exercises.first.sets.first.targetWeight!;
      final newW = d.exercises.first.sets.first.targetWeight!;
      final weightReduction = (origW - newW) / origW;

      expect(setReduction, greaterThan(weightReduction));
      expect(newSets, 2);
    });

    test('intensity strategy reduces weight more than sets', () {
      final p = _plan(workingSets: 4);
      final d = DeloadPlan.from(p, strategy: DeloadStrategy.intensity);

      final origSets = p.exercises.first.sets.length;
      final newSets = d.exercises.first.sets.length;
      final setReduction = (origSets - newSets) / origSets;

      final origW = p.exercises.first.sets.first.targetWeight!;
      final newW = d.exercises.first.sets.first.targetWeight!;
      final weightReduction = (origW - newW) / origW;

      expect(weightReduction, greaterThan(setReduction));
    });

    test('plan id and name signal deload', () {
      final p = _plan();
      final d = DeloadPlan.from(p);
      expect(d.id, contains('deload'));
      expect(d.name, contains('Deload'));
    });

    test('warmup sets are preserved verbatim', () {
      final warm1 = _ws(reps: 15, weight: 40, type: SetType.warmup);
      final warm2 = _ws(reps: 10, weight: 60, type: SetType.warmup);
      final working = List<WorkoutSet>.generate(
        4,
        (_) => _ws(reps: 8, weight: 120),
      );
      final plan = WorkoutPlan(
        id: 'p',
        name: 'P',
        exercises: [
          _ex('bp', [warm1, warm2, ...working]),
        ],
      );

      final d = DeloadPlan.from(plan, strategy: DeloadStrategy.balanced);
      final sets = d.exercises.single.sets;

      expect(sets.first, warm1);
      expect(sets[1], warm2);
      expect(sets.length, 2 + 3);
      for (final s in sets.skip(2)) {
        expect(s.type, SetType.working);
        expect(s.targetReps, lessThan(8));
        expect(s.targetWeight, lessThan(120));
      }
    });

    test('null targetWeight stays null after deload', () {
      final p = WorkoutPlan(
        id: 'bw',
        name: 'BW',
        exercises: [
          _ex('pu', [_ws(reps: 20, weight: null), _ws(reps: 20, weight: null)]),
        ],
      );
      final d = DeloadPlan.from(p, strategy: DeloadStrategy.balanced);
      for (final s in d.exercises.single.sets) {
        expect(s.targetWeight, isNull);
      }
    });

    test('idSuffix overrides default suffix', () {
      final p = _plan();
      final d = DeloadPlan.from(p, idSuffix: '_week6');
      expect(d.id, 'push_week6');
    });

    test('weight rounded to nearest 0.5 kg', () {
      final p = WorkoutPlan(
        id: 'r',
        name: 'R',
        exercises: [
          _ex('x', [_ws(reps: 8, weight: 102.5)]),
        ],
      );
      final d = DeloadPlan.from(
        p,
        config: const DeloadConfig(
          setMultiplier: 1.0,
          weightMultiplier: 0.73,
          repMultiplier: 1.0,
        ),
      );
      final w = d.exercises.single.sets.single.targetWeight!;
      expect(w, 75.0);
      expect((w * 2) % 1, 0);
    });
  });
}
