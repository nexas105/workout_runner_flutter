/// Current schema version stamped into every persistable top-level JSON
/// payload (`WorkoutPlan`, `WorkoutResult`, `CardioResult`, runner states).
///
/// Bump this when an irreversible JSON shape change ships. The `fromJson`
/// factories must keep parsing the previous version's payloads — that's the
/// whole point of having a number to dispatch on.
library;

const int kPluginSchemaVersion = 1;

int readSchemaVersion(Map<String, dynamic> json) {
  final raw = json['schemaVersion'];
  if (raw is num) return raw.toInt();
  return 0;
}
