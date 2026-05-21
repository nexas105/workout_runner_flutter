import 'measurement_system.dart';

/// Result of loading a barbell for a target weight.
///
/// All weights are in the **unit you fed the calculator** — `PlateCalculator`
/// is unit-blind so a single API works for both kg and lb (the
/// [DefaultPlateSets] catalogue picks per [MeasurementSystem]). Mixing units
/// across calls is fine as long as `barWeight`, `availablePlates` and
/// `targetWeight` use the same scale.
class PlateLoading {
  /// Plates that go on **each** side of the bar (the calculator is symmetric).
  /// Ordered heaviest first by convention.
  final List<double> perSide;

  /// Weight effectively achieved given the bar + 2 × perSide. May differ from
  /// the requested target if no exact combination fits.
  final double achieved;

  /// `achieved - target`. Positive means we overshot, negative means we
  /// undershot.
  final double delta;

  /// True when the target was reached exactly (within a 0.001 epsilon).
  final bool isExact;

  /// True when there's a bar but no plates were loaded — usually because the
  /// target equals the bar weight, or no plate is small enough to fit.
  final bool isEmptyBar;

  /// True when the requested target is below the bar weight, so no loading
  /// is possible. `perSide` is empty, `achieved` equals [barWeight].
  final bool isBelowBar;

  /// The bar weight used to compute the loading. Echoed back so consumers can
  /// render "20 kg bar + …" without re-passing it.
  final double barWeight;

  const PlateLoading({
    required this.perSide,
    required this.achieved,
    required this.delta,
    required this.isExact,
    required this.isEmptyBar,
    required this.isBelowBar,
    required this.barWeight,
  });

  /// Total plate weight loaded (both sides).
  double get totalPlateWeight => achieved - barWeight;

  @override
  String toString() {
    final pretty = perSide.map(_fmtNum).join(' + ');
    return 'PlateLoading(bar: ${_fmtNum(barWeight)}, perSide: [$pretty], '
        'achieved: ${_fmtNum(achieved)}, delta: ${_fmtNum(delta)})';
  }

  static String _fmtNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

/// Pure helper that picks the largest possible plate combination per side to
/// hit a target weight on a barbell.
///
/// ```dart
/// final loading = PlateCalculator.load(
///   targetWeight: 100,
///   barWeight: 20,
///   availablePlates: DefaultPlateSets.standardKg,
/// );
/// // loading.perSide  → [25.0, 15.0]   (greedy heaviest-first)
/// // loading.achieved → 100.0
/// // loading.isExact  → true
/// ```
///
/// The calculator is unit-blind: `kg` in → `kg` out, `lb` in → `lb` out.
/// Pick a plate set from [DefaultPlateSets] or pass your own list. Plates do
/// not need to be sorted — the calculator handles that.
class PlateCalculator {
  PlateCalculator._();

  /// Tolerance for "exact" comparisons. Half a gram (= 0.0011 lb) is well
  /// below anything any real plate set can deliver, so we don't get burned by
  /// IEEE-754 noise (`0.1 + 0.2`).
  static const double _epsilon = 0.0005;

  /// Compute the loading that gets closest to (but not over) [targetWeight].
  ///
  /// * Returns an empty per-side list when [targetWeight] is at or below
  ///   [barWeight].
  /// * Plates of weight `<= 0` are silently skipped.
  /// * [availablePlates] is treated as an infinite supply by default.
  ///   Pass a `plateCounts` map to model a finite gym rack.
  ///
  /// The algorithm is greedy from heaviest plate down — optimal for the
  /// standard "halving" plate sets (1.25 / 2.5 / 5 / 10 / 15 / 20 kg, or
  /// 2.5 / 5 / 10 / 25 / 35 / 45 lb). For exotic plate sets where greedy
  /// would miss an exact match, callers can fall back to their own solver.
  static PlateLoading load({
    required double targetWeight,
    required double barWeight,
    required List<double> availablePlates,
    Map<double, int>? plateCounts,
  }) {
    if (targetWeight < barWeight - _epsilon) {
      return PlateLoading(
        perSide: const [],
        achieved: barWeight,
        delta: barWeight - targetWeight,
        isExact: false,
        isEmptyBar: true,
        isBelowBar: true,
        barWeight: barWeight,
      );
    }

    final perSideTarget = (targetWeight - barWeight) / 2.0;
    if (perSideTarget <= _epsilon) {
      return PlateLoading(
        perSide: const [],
        achieved: barWeight,
        delta: barWeight - targetWeight,
        isExact: (barWeight - targetWeight).abs() <= _epsilon,
        isEmptyBar: true,
        isBelowBar: false,
        barWeight: barWeight,
      );
    }

    // Defensive copy + sort heaviest-first, drop non-positive entries.
    final plates =
        availablePlates.where((p) => p > 0).toList()
          ..sort((a, b) => b.compareTo(a));

    // Per-side budget. We pick plates one at a time, deducting from the
    // per-side budget and from the optional supply map.
    final supply =
        plateCounts == null
            ? null
            : <double, int>{...plateCounts}; // mutable shallow copy

    final perSide = <double>[];
    var remaining = perSideTarget;
    for (final plate in plates) {
      while (remaining + _epsilon >= plate) {
        if (supply != null) {
          final stock = supply[plate] ?? 0;
          // A pair of plates is loaded simultaneously (one per side), so we
          // need at least 2 in stock.
          if (stock < 2) break;
          supply[plate] = stock - 2;
        }
        perSide.add(plate);
        remaining -= plate;
      }
    }

    final loaded = perSide.fold<double>(0, (a, b) => a + b);
    final achieved = barWeight + 2 * loaded;
    final delta = achieved - targetWeight;
    return PlateLoading(
      perSide: List<double>.unmodifiable(perSide),
      achieved: achieved,
      delta: delta,
      isExact: delta.abs() <= _epsilon,
      isEmptyBar: perSide.isEmpty,
      isBelowBar: false,
      barWeight: barWeight,
    );
  }
}

/// Bar weight presets — pure constants, in their native unit.
class DefaultBars {
  DefaultBars._();

  /// Olympic men's barbell — 20 kg.
  static const double mensOlympicKg = 20.0;

  /// Olympic women's barbell — 15 kg.
  static const double womensOlympicKg = 15.0;

  /// EZ-curl bar — ~7 kg (varies; consumers can override).
  static const double ezCurlKg = 7.0;

  /// Standard 45 lb Olympic bar.
  static const double mensOlympicLb = 45.0;

  /// 35 lb Olympic bar (women's / training).
  static const double womensOlympicLb = 35.0;
}

/// Catalogue of built-in plate sets. All values are pure constants — apps
/// can pass their own lists to [PlateCalculator.load] without depending on
/// these.
class DefaultPlateSets {
  DefaultPlateSets._();

  /// Standard metric Olympic plate set (kg).
  /// Covers commercial-gym and home-gym kits.
  static const List<double> standardKg = [
    25.0,
    20.0,
    15.0,
    10.0,
    5.0,
    2.5,
    1.25,
    0.5,
  ];

  /// Standard imperial Olympic plate set (lb).
  static const List<double> standardLb = [
    45.0,
    35.0,
    25.0,
    10.0,
    5.0,
    2.5,
    1.25,
  ];

  /// Picks the matching plate set for the chosen [MeasurementSystem].
  static List<double> forSystem(MeasurementSystem system) =>
      system == MeasurementSystem.metric ? standardKg : standardLb;

  /// Picks the conventional Olympic bar weight for the chosen
  /// [MeasurementSystem]. Use `DefaultBars.*` directly when you need a
  /// non-standard bar.
  static double defaultBarForSystem(MeasurementSystem system) =>
      system == MeasurementSystem.metric
          ? DefaultBars.mensOlympicKg
          : DefaultBars.mensOlympicLb;
}
