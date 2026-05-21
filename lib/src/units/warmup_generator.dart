import '../models/set_type.dart';
import '../models/workout_set.dart';

/// Pre-baked ramp shape for [WarmupGenerator.forSet].
///
/// Each strategy is a list of `(percentOfWorkingWeight, reps)` pairs. The top
/// working set itself is never included — these are *warm-up* sets to do
/// **before** the main set(s).
enum WarmupStrategy {
  /// Default, conservative ramp. 4 sets, evenly spaced from light to ~85 %.
  /// Good for general fitness, machine work, smaller lifts.
  linear,

  /// Heavier, low-rep ramp typical of powerlifting routines. 4 sets at
  /// 50 / 70 / 85 / 92 % × 5 / 3 / 2 / 1 reps. Higher CNS prep, less volume.
  powerlifting,

  /// Volume-friendly ramp for hypertrophy work. 3 sets at 45 / 60 / 75 % × 12
  /// / 10 / 8 reps. Keeps blood in the muscle without burning glycogen.
  hypertrophy,
}

/// Pure helper that emits a list of warm-up `WorkoutSet`s leading into a
/// given working set.
///
/// ```dart
/// final warmup = WarmupGenerator.forSet(
///   workingWeight: 100,
///   workingReps: 5,
///   strategy: WarmupStrategy.powerlifting,
///   barWeight: 20,
///   roundTo: 2.5,
/// );
/// // → [
/// //     WorkoutSet(targetReps: 5, targetWeight: 50,  type: SetType.warmup),
/// //     WorkoutSet(targetReps: 3, targetWeight: 70,  type: SetType.warmup),
/// //     WorkoutSet(targetReps: 2, targetWeight: 85,  type: SetType.warmup),
/// //     WorkoutSet(targetReps: 1, targetWeight: 92.5,type: SetType.warmup),
/// //   ]
/// ```
///
/// The generator is **deterministic** and free of randomness — same inputs
/// always produce the same output. Tag the resulting sets with whichever
/// `rest` the consumer wants (passed in once, applied to every warm-up set).
class WarmupGenerator {
  WarmupGenerator._();

  // -------------------------------------------------------------------------
  // Strategy tables
  // -------------------------------------------------------------------------

  // Each entry is (percentOfWorkingWeight, repsAtThatPercent).
  static const List<(double, int)> _linear = [
    (0.40, 8),
    (0.55, 6),
    (0.70, 4),
    (0.85, 2),
  ];

  static const List<(double, int)> _powerlifting = [
    (0.50, 5),
    (0.70, 3),
    (0.85, 2),
    (0.925, 1),
  ];

  static const List<(double, int)> _hypertrophy = [
    (0.45, 12),
    (0.60, 10),
    (0.75, 8),
  ];

  static List<(double, int)> _tableFor(WarmupStrategy strategy) {
    switch (strategy) {
      case WarmupStrategy.linear:
        return _linear;
      case WarmupStrategy.powerlifting:
        return _powerlifting;
      case WarmupStrategy.hypertrophy:
        return _hypertrophy;
    }
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Generate warm-up sets that lead into a working set of
  /// `[workingReps]` × `[workingWeight]`.
  ///
  /// * Returns an **empty list** when [workingWeight] is `null`, zero or
  ///   below the supplied [barWeight] — bodyweight / bar-only sets do not
  ///   need a programmatic warm-up.
  /// * Returns an empty list when [workingReps] ≤ 0.
  /// * Each emitted set is tagged with [SetType.warmup]. The given [rest] is
  ///   attached as the post-set pause.
  /// * [roundTo] snaps each warm-up weight up to the nearest multiple — set
  ///   to a plate increment (`2.5` kg, `5` lb, `1.25` kg) to keep loads
  ///   realistic. Use `null` to keep the raw percentage.
  /// * Sets below [barWeight] (after rounding) are dropped, because you
  ///   can't actually load less than an empty bar on a barbell lift.
  static List<WorkoutSet> forSet({
    required double? workingWeight,
    required int workingReps,
    WarmupStrategy strategy = WarmupStrategy.linear,
    double? barWeight,
    double? roundTo,
    Duration rest = const Duration(seconds: 60),
  }) {
    if (workingWeight == null || workingWeight <= 0) return const [];
    if (workingReps <= 0) return const [];
    if (barWeight != null && workingWeight <= barWeight) return const [];

    final table = _tableFor(strategy);
    final result = <WorkoutSet>[];
    double? lastWeight;
    for (final (pct, reps) in table) {
      final raw = workingWeight * pct;
      final weight = _round(raw, roundTo);
      if (barWeight != null && weight < barWeight) continue;
      // Skip plateaus — when rounding collapses two warm-up steps onto the
      // same weight, emit just one.
      if (lastWeight != null && _close(weight, lastWeight)) continue;
      lastWeight = weight;
      result.add(
        WorkoutSet(
          targetReps: reps,
          targetWeight: weight,
          rest: rest,
          type: SetType.warmup,
        ),
      );
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Snap [value] **up** to the nearest [step]. `step == null` leaves the
  /// value untouched; non-positive [step] is also treated as "no rounding".
  static double _round(double value, double? step) {
    if (step == null || step <= 0) return value;
    final n = (value / step).ceil();
    return n * step;
  }

  static bool _close(double a, double b) => (a - b).abs() < 1e-6;
}
