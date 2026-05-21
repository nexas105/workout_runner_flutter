import 'measurement_system.dart';
import 'unit_conversions.dart';

/// Static-style helpers that turn raw metric values into display strings
/// under a chosen [MeasurementSystem].
///
/// The package always stores values in metric base units. These formatters
/// are the boundary layer between storage and the UI:
///
/// ```dart
/// WorkoutRunnerUnitFormatters.weight(60.0, MeasurementSystem.imperial);
/// // → "132 lb"
/// ```
///
/// Decimals are kept minimal on purpose — for fitness UIs nobody wants to
/// stare at `132.27739…`. Override by computing the conversion yourself if
/// you want custom precision.
class WorkoutRunnerUnitFormatters {
  WorkoutRunnerUnitFormatters._();

  // -------------------------------------------------------------------------
  // Weight
  // -------------------------------------------------------------------------

  /// Format a weight stored in kilograms for the chosen [system].
  ///
  /// * metric → `"60 kg"` (or `"22.5 kg"` when fractional)
  /// * imperial → `"132 lb"`
  ///
  /// Pass [decimals] to override the default precision; pass [includeUnit]
  /// `false` to get just the number (useful when the unit label is rendered
  /// separately).
  static String weight(
    double kg,
    MeasurementSystem system, {
    int decimals = 1,
    bool includeUnit = true,
  }) {
    final value = weightToSystem(kg, system);
    final unit = system == MeasurementSystem.metric ? 'kg' : 'lb';
    final text = _formatNumber(value, decimals);
    return includeUnit ? '$text $unit' : text;
  }

  // -------------------------------------------------------------------------
  // Distance
  // -------------------------------------------------------------------------

  /// Format a distance stored in metres for the chosen [system]. Short
  /// distances (< 1 km / < 1 mile) fall back to the small unit (m or ft) so
  /// "320 m" stays "320 m" instead of becoming "0.3 km".
  static String distance(
    double meters,
    MeasurementSystem system, {
    int decimals = 2,
    bool includeUnit = true,
  }) {
    if (system == MeasurementSystem.metric) {
      if (meters < 1000) {
        final text = _formatNumber(meters, 0);
        return includeUnit ? '$text m' : text;
      }
      final text = _formatNumber(metersToKm(meters), decimals);
      return includeUnit ? '$text km' : text;
    }
    if (meters < kMetersPerMile) {
      final text = _formatNumber(metersToFeet(meters), 0);
      return includeUnit ? '$text ft' : text;
    }
    final text = _formatNumber(metersToMiles(meters), decimals);
    return includeUnit ? '$text mi' : text;
  }

  // -------------------------------------------------------------------------
  // Pace
  // -------------------------------------------------------------------------

  /// Format a pace stored as seconds-per-km for the chosen [system].
  ///
  /// * metric → `"5:30 /km"`
  /// * imperial → `"8:51 /mi"`
  ///
  /// Returns `'—'` when [perKm] is `null` (no pace recorded yet).
  static String pace(
    Duration? perKm,
    MeasurementSystem system, {
    bool includeUnit = true,
  }) {
    if (perKm == null || perKm.inSeconds <= 0) return '—';
    final converted = paceToSystem(perKm, system);
    final m = converted.inMinutes;
    final s = converted.inSeconds.remainder(60).abs();
    final mmSs = '$m:${s.toString().padLeft(2, '0')}';
    if (!includeUnit) return mmSs;
    return system == MeasurementSystem.metric ? '$mmSs /km' : '$mmSs /mi';
  }

  // -------------------------------------------------------------------------
  // Speed
  // -------------------------------------------------------------------------

  /// Format a speed (metres per second) for the chosen [system].
  ///
  /// * metric → `"12.3 km/h"`
  /// * imperial → `"7.6 mph"`
  static String speed(
    double metersPerSecond,
    MeasurementSystem system, {
    int decimals = 1,
    bool includeUnit = true,
  }) {
    final value = speedToSystem(metersPerSecond, system);
    final text = _formatNumber(value, decimals);
    if (!includeUnit) return text;
    return system == MeasurementSystem.metric ? '$text km/h' : '$text mph';
  }

  // -------------------------------------------------------------------------
  // Unit labels (used by inputs and column headers)
  // -------------------------------------------------------------------------

  static String weightUnit(MeasurementSystem system) =>
      system == MeasurementSystem.metric ? 'kg' : 'lb';

  static String longDistanceUnit(MeasurementSystem system) =>
      system == MeasurementSystem.metric ? 'km' : 'mi';

  static String shortDistanceUnit(MeasurementSystem system) =>
      system == MeasurementSystem.metric ? 'm' : 'ft';

  static String paceUnit(MeasurementSystem system) =>
      system == MeasurementSystem.metric ? '/km' : '/mi';

  static String speedUnit(MeasurementSystem system) =>
      system == MeasurementSystem.metric ? 'km/h' : 'mph';

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static String _formatNumber(double v, int decimals) {
    // Drop trailing zeros after the decimal point but keep integer 0.
    if (v == v.roundToDouble()) return v.toInt().toString();
    final rounded = double.parse(v.toStringAsFixed(decimals));
    if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
    return rounded.toString();
  }
}
