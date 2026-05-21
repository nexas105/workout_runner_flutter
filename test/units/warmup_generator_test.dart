import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('linear strategy', () {
    test('produces 4 sets at ascending weights and descending reps', () {
      final sets = WarmupGenerator.forSet(workingWeight: 100, workingReps: 8);
      expect(sets, hasLength(4));
      // Reps descend
      expect(sets.map((s) => s.targetReps).toList(), [8, 6, 4, 2]);
      // Weights ascend
      final weights = sets.map((s) => s.targetWeight!).toList();
      for (var i = 1; i < weights.length; i++) {
        expect(weights[i] > weights[i - 1], isTrue);
      }
      // Last warm-up weight is below the working weight
      expect(weights.last < 100, isTrue);
    });

    test('all sets are tagged SetType.warmup', () {
      final sets = WarmupGenerator.forSet(workingWeight: 80, workingReps: 5);
      expect(sets.every((s) => s.type == SetType.warmup), isTrue);
    });

    test('rest is applied to every set', () {
      final sets = WarmupGenerator.forSet(
        workingWeight: 80,
        workingReps: 5,
        rest: const Duration(seconds: 90),
      );
      expect(sets.every((s) => s.rest == const Duration(seconds: 90)), isTrue);
    });
  });

  group('powerlifting strategy', () {
    test('ends at a single rep singles', () {
      final sets = WarmupGenerator.forSet(
        workingWeight: 200,
        workingReps: 1,
        strategy: WarmupStrategy.powerlifting,
      );
      expect(sets, hasLength(4));
      expect(sets.last.targetReps, 1);
      // Top warm-up should be ≈ 92.5% (= 185)
      expect(sets.last.targetWeight, closeTo(185.0, 0.5));
    });
  });

  group('hypertrophy strategy', () {
    test('produces 3 sets with higher reps', () {
      final sets = WarmupGenerator.forSet(
        workingWeight: 60,
        workingReps: 12,
        strategy: WarmupStrategy.hypertrophy,
      );
      expect(sets, hasLength(3));
      expect(sets.map((s) => s.targetReps).toList(), [12, 10, 8]);
    });
  });

  group('rounding (roundTo)', () {
    test('snaps each warm-up weight up to a plate increment', () {
      final sets = WarmupGenerator.forSet(
        workingWeight: 100,
        workingReps: 5,
        strategy: WarmupStrategy.powerlifting,
        roundTo: 2.5,
      );
      // 50 / 70 / 85 / 92.5 — all already multiples of 2.5
      expect(sets.map((s) => s.targetWeight).toList(), [
        50.0,
        70.0,
        85.0,
        92.5,
      ]);
    });

    test('rounds awkward weights up', () {
      final sets = WarmupGenerator.forSet(
        workingWeight: 102.5,
        workingReps: 5,
        strategy: WarmupStrategy.linear,
        roundTo: 2.5,
      );
      // raw  → 41.0  56.375  71.75  87.125
      // round→ 42.5  57.5    72.5   87.5
      expect(sets.map((s) => s.targetWeight).toList(), [
        42.5,
        57.5,
        72.5,
        87.5,
      ]);
    });

    test('null roundTo keeps raw percentages', () {
      final sets = WarmupGenerator.forSet(
        workingWeight: 100,
        workingReps: 5,
        strategy: WarmupStrategy.linear,
        roundTo: null,
      );
      // IEEE-754: 100 * 0.55 = 55.00000000000001 — use closeTo, not `==`.
      expect(sets[0].targetWeight, closeTo(40.0, 1e-9));
      expect(sets[1].targetWeight, closeTo(55.0, 1e-9));
    });
  });

  group('bar weight clamp', () {
    test('drops warm-up sets that would be below an empty bar', () {
      // Working weight 30 with a 20 kg bar — only the 0.85 step ≥ 20 survives.
      final sets = WarmupGenerator.forSet(
        workingWeight: 30,
        workingReps: 5,
        barWeight: 20,
      );
      // 12, 16.5, 21, 25.5 → after barWeight clamp: 21, 25.5 (2 sets)
      expect(sets, hasLength(2));
      expect(sets.first.targetWeight! >= 20, isTrue);
    });

    test('working weight equal to bar weight → no warm-up', () {
      final sets = WarmupGenerator.forSet(
        workingWeight: 20,
        workingReps: 5,
        barWeight: 20,
      );
      expect(sets, isEmpty);
    });

    test('working weight below bar weight → no warm-up', () {
      final sets = WarmupGenerator.forSet(
        workingWeight: 15,
        workingReps: 5,
        barWeight: 20,
      );
      expect(sets, isEmpty);
    });
  });

  group('plateau dedupe', () {
    test('rounding collapses identical neighbouring weights', () {
      // Hypertrophy table: 45/60/75 % × workingWeight=10 with roundTo=5
      // raw → 4.5 / 6.0 / 7.5 → round-up 5 / 10 / 10  → expect dedupe.
      final sets = WarmupGenerator.forSet(
        workingWeight: 10,
        workingReps: 8,
        strategy: WarmupStrategy.hypertrophy,
        roundTo: 5,
      );
      // Sets should have unique weights after dedupe.
      final weights = sets.map((s) => s.targetWeight).toList();
      expect(weights.toSet().length, weights.length);
    });
  });

  group('input hygiene', () {
    test('null workingWeight → empty', () {
      expect(
        WarmupGenerator.forSet(workingWeight: null, workingReps: 5),
        isEmpty,
      );
    });

    test('zero workingWeight → empty', () {
      expect(WarmupGenerator.forSet(workingWeight: 0, workingReps: 5), isEmpty);
    });

    test('zero workingReps → empty', () {
      expect(
        WarmupGenerator.forSet(workingWeight: 100, workingReps: 0),
        isEmpty,
      );
    });

    test('negative workingReps → empty', () {
      expect(
        WarmupGenerator.forSet(workingWeight: 100, workingReps: -5),
        isEmpty,
      );
    });
  });
}
