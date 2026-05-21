/// The unit system a UI layer wants to display values in.
///
/// All values inside the package (and inside `RunnerStorage` JSON) are stored
/// in **metric base units** — kilograms for mass, meters for distance,
/// seconds for time, seconds-per-kilometre for pace. Conversion happens only
/// when formatting for display or when accepting user input.
///
/// Pick the system once at the app boundary (per user preference) and pass
/// it into the unit helpers; nothing inside the package interprets the
/// selection for you.
enum MeasurementSystem {
  /// Kilograms, kilometres / metres, minutes per kilometre.
  metric,

  /// Pounds, miles / feet, minutes per mile.
  imperial,
}

extension MeasurementSystemSerializer on MeasurementSystem {
  String get id => name;

  /// Defensive lookup — falls back to [MeasurementSystem.metric] for unknown
  /// strings so storage with a stale enum value never crashes the app.
  static MeasurementSystem fromId(String? raw) => MeasurementSystem.values
      .firstWhere((s) => s.name == raw, orElse: () => MeasurementSystem.metric);
}
