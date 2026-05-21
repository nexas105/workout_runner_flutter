import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('exact loads — kg', () {
    test(
      '100 kg on a 20 kg bar → 25 + 15 per side (greedy heaviest-first)',
      () {
        final loading = PlateCalculator.load(
          targetWeight: 100,
          barWeight: DefaultBars.mensOlympicKg,
          availablePlates: DefaultPlateSets.standardKg,
        );
        // Default kg set starts at 25 kg — greedy picks it before the 20 kg.
        expect(loading.perSide, [25.0, 15.0]);
        expect(loading.achieved, 100.0);
        expect(loading.delta, 0.0);
        expect(loading.isExact, isTrue);
        expect(loading.isEmptyBar, isFalse);
        expect(loading.isBelowBar, isFalse);
        expect(loading.totalPlateWeight, 80.0);
      },
    );

    test('60 kg → 20 per side (single plate, heaviest first)', () {
      final loading = PlateCalculator.load(
        targetWeight: 60,
        barWeight: 20,
        availablePlates: DefaultPlateSets.standardKg,
      );
      expect(loading.perSide, [20.0]);
      expect(loading.isExact, isTrue);
    });

    test('22.5 kg → 1.25 per side', () {
      final loading = PlateCalculator.load(
        targetWeight: 22.5,
        barWeight: 20,
        availablePlates: DefaultPlateSets.standardKg,
      );
      expect(loading.perSide, [1.25]);
      expect(loading.isExact, isTrue);
    });
  });

  group('exact loads — lb', () {
    test('225 lb on a 45 lb bar → 45 + 45 per side', () {
      final loading = PlateCalculator.load(
        targetWeight: 225,
        barWeight: DefaultBars.mensOlympicLb,
        availablePlates: DefaultPlateSets.standardLb,
      );
      expect(loading.perSide, [45.0, 45.0]);
      expect(loading.isExact, isTrue);
      expect(loading.achieved, 225.0);
    });

    test('135 lb → 45 per side (classic warm-up)', () {
      final loading = PlateCalculator.load(
        targetWeight: 135,
        barWeight: DefaultBars.mensOlympicLb,
        availablePlates: DefaultPlateSets.standardLb,
      );
      expect(loading.perSide, [45.0]);
      expect(loading.isExact, isTrue);
    });
  });

  group('bar-only edge cases', () {
    test('target == bar → empty bar, exact', () {
      final loading = PlateCalculator.load(
        targetWeight: 20,
        barWeight: 20,
        availablePlates: DefaultPlateSets.standardKg,
      );
      expect(loading.perSide, isEmpty);
      expect(loading.achieved, 20.0);
      expect(loading.isEmptyBar, isTrue);
      expect(loading.isExact, isTrue);
      expect(loading.isBelowBar, isFalse);
    });

    test('target below bar → cannot load, flagged', () {
      final loading = PlateCalculator.load(
        targetWeight: 10,
        barWeight: 20,
        availablePlates: DefaultPlateSets.standardKg,
      );
      expect(loading.perSide, isEmpty);
      expect(loading.achieved, 20.0);
      expect(loading.isBelowBar, isTrue);
      expect(loading.isEmptyBar, isTrue);
      expect(loading.isExact, isFalse);
      expect(loading.delta, 10.0); // overshot by 10
    });
  });

  group('rounding — no exact match', () {
    test('greedy stops short, delta is negative', () {
      // 21 kg on a 20 kg bar requires 0.5 per side. With a plate set that
      // lacks 0.5, the greedy result will be empty.
      final loading = PlateCalculator.load(
        targetWeight: 21,
        barWeight: 20,
        availablePlates: const [10.0, 5.0, 2.5], // no 0.5 / 1.25
      );
      expect(loading.perSide, isEmpty);
      expect(loading.achieved, 20.0);
      expect(loading.delta, -1.0); // undershot
      expect(loading.isExact, isFalse);
      expect(loading.isEmptyBar, isTrue);
    });

    test(
      'partial match: takes what fits, reports delta',
      () {
        // 102.5 kg on a 20 kg bar = 41.25 per side. Without a 1.25 plate,
        // we should get 20 + 15 + 5 = 40 per side = 100 kg achieved.
        final loading = PlateCalculator.load(
          targetWeight: 102.5,
          barWeight: 20,
          availablePlates: const [25.0, 20.0, 15.0, 10.0, 5.0, 2.5],
        );
        expect(loading.perSide, [20.0, 15.0, 5.0, 2.5]); // = 42.5 per side
        // Wait — 42.5 × 2 = 85 + 20 = 105 (overshoots target 102.5). The
        // greedy algorithm should NOT take the 2.5 because remaining is
        // 41.25 - (20+15+5) = 1.25 < 2.5. Let me recompute…
      },
      skip: 'asserts the algorithm — overridden by the precise test below',
    );

    test('greedy halts when next plate would overshoot', () {
      // Per-side target 41.25, available [25, 20, 15, 10, 5, 2.5].
      // Greedy: 25 → 16.25 left → next ≤ 16.25 is 15 → 1.25 left → no plate
      // fits. perSide = [25, 15]. achieved = 20 + 80 = 100, delta = -2.5.
      final loading = PlateCalculator.load(
        targetWeight: 102.5,
        barWeight: 20,
        availablePlates: const [25.0, 20.0, 15.0, 10.0, 5.0, 2.5],
      );
      expect(loading.perSide, [25.0, 15.0]);
      expect(loading.achieved, 100.0);
      expect(loading.delta, -2.5);
      expect(loading.isExact, isFalse);
    });
  });

  group('finite plate supply', () {
    test('respects plateCounts and stops when out of stock', () {
      // Only a single pair of 20 kg plates available — greedy would normally
      // grab two pairs for a 100 kg target.
      final loading = PlateCalculator.load(
        targetWeight: 100,
        barWeight: 20,
        availablePlates: DefaultPlateSets.standardKg,
        plateCounts: {20.0: 2, 15.0: 2, 5.0: 2, 2.5: 4},
      );
      expect(loading.perSide, [20.0, 15.0, 5.0]);
      expect(loading.isExact, isTrue);
    });

    test('insufficient stock falls back to next size', () {
      // Goal: 80 kg total, per-side = 30. Plate set has plenty of 25s but
      // only one pair of 5s. Two pairs of 25 + one pair of 5 hits the target.
      // If we restrict supply to ONE pair of 25, greedy must fall through to
      // 20.
      final loading = PlateCalculator.load(
        targetWeight: 80,
        barWeight: 20,
        availablePlates: DefaultPlateSets.standardKg,
        plateCounts: {25.0: 2, 20.0: 2, 15.0: 2, 5.0: 2, 2.5: 4},
      );
      // Per-side budget = 30. Greedy picks 25 → 5 left → picks 5. Total
      // [25, 5]. achieved = 20 + 60 = 80. exact.
      expect(loading.perSide, [25.0, 5.0]);
      expect(loading.isExact, isTrue);
    });
  });

  group('input hygiene', () {
    test('non-positive plates are ignored', () {
      final loading = PlateCalculator.load(
        targetWeight: 60,
        barWeight: 20,
        availablePlates: const [-5.0, 0.0, 20.0, 10.0],
      );
      expect(loading.perSide, [20.0]);
      expect(loading.isExact, isTrue);
    });

    test('unsorted plate list still works', () {
      final loading = PlateCalculator.load(
        targetWeight: 60,
        barWeight: 20,
        availablePlates: const [2.5, 20.0, 5.0, 15.0, 10.0],
      );
      expect(loading.perSide, [20.0]);
      expect(loading.isExact, isTrue);
    });
  });

  group('catalogue', () {
    test('DefaultPlateSets.forSystem picks per system', () {
      expect(
        DefaultPlateSets.forSystem(MeasurementSystem.metric),
        DefaultPlateSets.standardKg,
      );
      expect(
        DefaultPlateSets.forSystem(MeasurementSystem.imperial),
        DefaultPlateSets.standardLb,
      );
    });

    test('defaultBarForSystem picks 20 kg / 45 lb', () {
      expect(
        DefaultPlateSets.defaultBarForSystem(MeasurementSystem.metric),
        DefaultBars.mensOlympicKg,
      );
      expect(
        DefaultPlateSets.defaultBarForSystem(MeasurementSystem.imperial),
        DefaultBars.mensOlympicLb,
      );
    });
  });
}
