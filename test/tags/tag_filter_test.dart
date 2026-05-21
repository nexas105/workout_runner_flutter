import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _plan(String id, List<String>? tags) => WorkoutPlan(
  id: id,
  name: id,
  exercises: const [],
  meta: tags == null ? null : {'tags': tags},
);

CardioPlan _cardioPlan(String id, List<String>? tags) => CardioPlan(
  id: id,
  name: id,
  intervals: const [
    CardioInterval(id: 'i1', name: 'i1'),
  ],
  meta: tags == null ? null : {'tags': tags},
);

CardioResult _cardioResult(String id, List<String>? tags) => CardioResult(
  planId: id,
  planName: id,
  discipline: CardioDiscipline.mixed,
  startedAt: DateTime.utc(2026, 1, 1),
  finishedAt: DateTime.utc(2026, 1, 1, 0, 30),
  duration: const Duration(minutes: 30),
  laps: const [],
  meta: tags == null ? null : {'tags': tags},
);

void main() {
  group('TagFilter.apply', () {
    final items = [
      _plan('a', ['strength', 'gym']),
      _plan('b', ['cardio', 'home']),
      _plan('c', ['strength', 'home']),
      _plan('d', null),
    ];

    test('any returns items sharing at least one filter tag', () {
      final out = TagFilter.apply<WorkoutPlan>(
        items,
        (p) => p.meta,
        ['strength'],
      );
      expect(out.map((p) => p.id), ['a', 'c']);
    });

    test('any matches the union across multiple filter tags', () {
      final out = TagFilter.apply<WorkoutPlan>(
        items,
        (p) => p.meta,
        ['strength', 'cardio'],
      );
      expect(out.map((p) => p.id), ['a', 'b', 'c']);
    });

    test('all requires every filter tag to be present', () {
      final out = TagFilter.apply<WorkoutPlan>(
        items,
        (p) => p.meta,
        ['strength', 'home'],
        mode: TagMatchMode.all,
      );
      expect(out.map((p) => p.id), ['c']);
    });

    test('none excludes items with any matching tag', () {
      final out = TagFilter.apply<WorkoutPlan>(
        items,
        (p) => p.meta,
        ['strength'],
        mode: TagMatchMode.none,
      );
      expect(out.map((p) => p.id), ['b', 'd']);
    });

    test('empty filter returns no items for any/all', () {
      expect(
        TagFilter.apply<WorkoutPlan>(items, (p) => p.meta, const []),
        isEmpty,
      );
      expect(
        TagFilter.apply<WorkoutPlan>(
          items,
          (p) => p.meta,
          const [],
          mode: TagMatchMode.all,
        ),
        isEmpty,
      );
    });

    test('empty filter returns everything for none', () {
      final out = TagFilter.apply<WorkoutPlan>(
        items,
        (p) => p.meta,
        const [],
        mode: TagMatchMode.none,
      );
      expect(out.length, items.length);
    });

    test('filter tags are normalized like stored tags', () {
      final out = TagFilter.apply<WorkoutPlan>(
        items,
        (p) => p.meta,
        ['  STRENGTH '],
      );
      expect(out.map((p) => p.id), ['a', 'c']);
    });
  });

  group('TagFilter.filterPlans', () {
    test('forwards to WorkoutPlan.meta', () {
      final plans = [
        _plan('a', ['gym']),
        _plan('b', ['home']),
      ];
      final out = TagFilter.filterPlans(plans, ['gym']);
      expect(out.map((p) => p.id), ['a']);
    });
  });

  group('TagFilter.filterResults', () {
    test('treats results as untagged (any/all → empty)', () {
      final results = <WorkoutResult>[
        WorkoutResult(
          planId: 'a',
          startedAt: DateTime.utc(2026, 1, 1),
          finishedAt: DateTime.utc(2026, 1, 1, 1),
          duration: const Duration(hours: 1),
          exercises: const [],
        ),
      ];
      expect(TagFilter.filterResults(results, ['gym']), isEmpty);
      expect(
        TagFilter.filterResults(results, ['gym'], mode: TagMatchMode.none),
        hasLength(1),
      );
    });
  });

  group('TagFilter.filterCardioPlans', () {
    test('filters by CardioPlan.meta tags', () {
      final plans = [
        _cardioPlan('a', ['hiit']),
        _cardioPlan('b', ['liss']),
      ];
      final out = TagFilter.filterCardioPlans(plans, ['hiit']);
      expect(out.map((p) => p.id), ['a']);
    });
  });

  group('TagFilter.filterCardioResults', () {
    test('filters by CardioResult.meta tags', () {
      final results = [
        _cardioResult('a', ['hiit', 'morning']),
        _cardioResult('b', ['liss']),
        _cardioResult('c', null),
      ];

      final any = TagFilter.filterCardioResults(results, ['hiit']);
      expect(any.map((r) => r.planId), ['a']);

      final all = TagFilter.filterCardioResults(
        results,
        ['hiit', 'morning'],
        mode: TagMatchMode.all,
      );
      expect(all.map((r) => r.planId), ['a']);

      final none = TagFilter.filterCardioResults(
        results,
        ['hiit'],
        mode: TagMatchMode.none,
      );
      expect(none.map((r) => r.planId), ['b', 'c']);
    });
  });
}