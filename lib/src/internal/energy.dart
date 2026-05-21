/// Energy expenditure helpers. Pure functions, no Flutter dependency.
///
/// Estimates use the classic MET formula:
///
///     kcal ≈ MET × duration_h × bodyWeightKg
///
/// MET values are approximations from the Compendium of Physical Activities
/// (2024 update). Treat results as *estimates* — they're useful for trend
/// charts and motivation, not for nutrition or medical decisions.
library;

import '../models/cardio/cardio_plan.dart';

/// Default MET value when nothing else is known. Picks the middle of the
/// "light-moderate calisthenics" band so kcal output stays plausible for any
/// strength session that doesn't bother to specify MET per exercise.
const double kDefaultMet = 4.0;

/// Default MET by [ExerciseCategory.id]. Strength sits at 6 (Compendium
/// 02050), calisthenics/core 4, mobility 2.5.
const Map<String, double> kDefaultMetByCategoryId = {
  'strength': 6.0,
  'core': 4.5,
  'hiit': 8.5,
  'mobility': 2.5,
  'cardio': 7.0,
};

/// Default MET by [CardioDiscipline]. Running pace-adjustment is *not* applied
/// here — the value is an average for a moderate session. Apps that need
/// pace-adjusted MET should pass `met` explicitly on the [CardioInterval].
const Map<CardioDiscipline, double> kDefaultMetByDiscipline = {
  CardioDiscipline.running: 9.0,
  CardioDiscipline.cycling: 7.5,
  CardioDiscipline.rowing: 7.0,
  CardioDiscipline.swimming: 8.0,
  CardioDiscipline.jumpRope: 11.0,
  CardioDiscipline.walk: 3.5,
  CardioDiscipline.mixed: 6.5,
};

abstract class EnergyEstimator {
  EnergyEstimator._();

  /// kcal for a single segment given a MET value, segment duration and the
  /// user's body weight. Returns 0 for non-positive inputs.
  static double kcal({
    required double met,
    required Duration duration,
    required double bodyWeightKg,
  }) {
    if (met <= 0 || bodyWeightKg <= 0) return 0;
    final seconds = duration.inSeconds;
    if (seconds <= 0) return 0;
    return met * (seconds / 3600.0) * bodyWeightKg;
  }

  /// Resolve the MET to use for a strength exercise based on its explicit MET
  /// (preferred), the exercise category's default, or [kDefaultMet].
  static double metForCategoryId(String? categoryId) {
    if (categoryId == null) return kDefaultMet;
    return kDefaultMetByCategoryId[categoryId] ?? kDefaultMet;
  }

  /// Resolve the MET to use for a cardio interval based on the discipline.
  static double metForDiscipline(CardioDiscipline discipline) =>
      kDefaultMetByDiscipline[discipline] ?? kDefaultMet;
}
