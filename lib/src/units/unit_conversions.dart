/// Conversion factors and pure functions between metric and imperial units.
///
/// Stored values inside the package are always metric. These helpers convert
/// in either direction for UI formatting and for accepting imperial user
/// input.
///
/// All functions are pure and deterministic — no rounding is applied here;
/// the caller controls precision when it formats.
library;

import 'measurement_system.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// 1 lb = this many kilograms (NIST definition, exact).
const double kKgPerLb = 0.45359237;

/// 1 kg in pounds — reciprocal of [kKgPerLb], pre-computed for speed.
const double kLbPerKg = 1.0 / kKgPerLb;

/// 1 mile in metres (international mile, exact).
const double kMetersPerMile = 1609.344;

/// 1 foot in metres (international foot, exact).
const double kMetersPerFoot = 0.3048;

// ---------------------------------------------------------------------------
// Weight
// ---------------------------------------------------------------------------

/// Convert kilograms to pounds.
double kgToLb(double kg) => kg * kLbPerKg;

/// Convert pounds to kilograms.
double lbToKg(double lb) => lb * kKgPerLb;

/// Convert a metric (kg) value into the chosen [system]'s native weight unit
/// (kg for metric, lb for imperial). Round-trippable with [weightFromSystem].
double weightToSystem(double kg, MeasurementSystem system) =>
    system == MeasurementSystem.metric ? kg : kgToLb(kg);

/// Convert a value in the chosen [system]'s native weight unit back to
/// kilograms (the canonical storage unit).
double weightFromSystem(double value, MeasurementSystem system) =>
    system == MeasurementSystem.metric ? value : lbToKg(value);

// ---------------------------------------------------------------------------
// Distance
// ---------------------------------------------------------------------------

double metersToKm(double m) => m / 1000.0;
double kmToMeters(double km) => km * 1000.0;

double metersToMiles(double m) => m / kMetersPerMile;
double milesToMeters(double mi) => mi * kMetersPerMile;

double metersToFeet(double m) => m / kMetersPerFoot;
double feetToMeters(double ft) => ft * kMetersPerFoot;

/// Convert metres to the "long" distance unit of [system]
/// (kilometres for metric, miles for imperial).
double distanceToSystem(double meters, MeasurementSystem system) =>
    system == MeasurementSystem.metric
        ? metersToKm(meters)
        : metersToMiles(meters);

/// Convert a "long" distance value in [system]'s native unit back to metres.
double distanceFromSystem(double value, MeasurementSystem system) =>
    system == MeasurementSystem.metric
        ? kmToMeters(value)
        : milesToMeters(value);

// ---------------------------------------------------------------------------
// Pace
// ---------------------------------------------------------------------------

/// Compute pace (seconds per kilometre) from duration + distance in metres.
/// Returns `null` when either input is non-positive — callers can decide how
/// to render "no pace yet".
Duration? pacePerKm({
  required Duration duration,
  required double distanceMeters,
}) {
  if (distanceMeters <= 0 || duration.inSeconds <= 0) return null;
  final secondsPerMeter = duration.inSeconds / distanceMeters;
  return Duration(seconds: (secondsPerMeter * 1000).round());
}

/// Convert a pace in seconds-per-kilometre to seconds-per-mile.
Duration pacePerKmToPerMile(Duration perKm) =>
    Duration(seconds: (perKm.inSeconds * (kMetersPerMile / 1000.0)).round());

/// Convert a pace in seconds-per-mile to seconds-per-kilometre.
Duration pacePerMileToPerKm(Duration perMile) =>
    Duration(seconds: (perMile.inSeconds * (1000.0 / kMetersPerMile)).round());

/// Render a stored seconds-per-km pace into the chosen [system]'s native
/// pace (`min/km` for metric, `min/mi` for imperial).
Duration paceToSystem(Duration perKm, MeasurementSystem system) =>
    system == MeasurementSystem.metric ? perKm : pacePerKmToPerMile(perKm);

/// Convert a pace in [system]'s native unit back to seconds-per-kilometre.
Duration paceFromSystem(Duration value, MeasurementSystem system) =>
    system == MeasurementSystem.metric ? value : pacePerMileToPerKm(value);

// ---------------------------------------------------------------------------
// Speed (mostly a convenience for cardio readouts)
// ---------------------------------------------------------------------------

/// Compute speed in metres per second from duration + distance.
double? metersPerSecond({
  required Duration duration,
  required double distanceMeters,
}) {
  if (duration.inSeconds <= 0 || distanceMeters <= 0) return null;
  return distanceMeters / duration.inSeconds;
}

double mpsToKmh(double mps) => mps * 3.6;
double mpsToMph(double mps) => mps * 3600.0 / kMetersPerMile;

/// Convert m/s to the "speed" unit of [system] (km/h or mph).
double speedToSystem(double mps, MeasurementSystem system) =>
    system == MeasurementSystem.metric ? mpsToKmh(mps) : mpsToMph(mps);
