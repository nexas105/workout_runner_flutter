/// Pluggable persistence for [WorkoutRunner].
///
/// Implementations must round-trip the state and plan JSON unchanged. The
/// optional [slot] lets a single app keep multiple independent runners
/// (e.g. per user).
abstract class RunnerStorage {
  Future<void> saveState(
    Map<String, dynamic> json, {
    String slot = 'default',
  });
  Future<Map<String, dynamic>?> readState({String slot = 'default'});
  Future<void> clearState({String slot = 'default'});

  Future<void> savePlan(
    Map<String, dynamic> json, {
    String slot = 'default',
  });
  Future<Map<String, dynamic>?> readPlan({String slot = 'default'});
  Future<void> clearPlan({String slot = 'default'});
}
