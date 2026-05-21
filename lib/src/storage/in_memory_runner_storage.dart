import 'runner_storage.dart';

/// In-memory [RunnerStorage] for tests and previews. Does not persist across
/// app restarts.
class InMemoryRunnerStorage implements RunnerStorage {
  final Map<String, Map<String, dynamic>> _states = {};
  final Map<String, Map<String, dynamic>> _plans = {};

  @override
  Future<void> saveState(
    Map<String, dynamic> json, {
    String slot = 'default',
  }) async {
    _states[slot] = Map<String, dynamic>.from(json);
  }

  @override
  Future<Map<String, dynamic>?> readState({String slot = 'default'}) async {
    final s = _states[slot];
    return s == null ? null : Map<String, dynamic>.from(s);
  }

  @override
  Future<void> clearState({String slot = 'default'}) async {
    _states.remove(slot);
  }

  @override
  Future<void> savePlan(
    Map<String, dynamic> json, {
    String slot = 'default',
  }) async {
    _plans[slot] = Map<String, dynamic>.from(json);
  }

  @override
  Future<Map<String, dynamic>?> readPlan({String slot = 'default'}) async {
    final p = _plans[slot];
    return p == null ? null : Map<String, dynamic>.from(p);
  }

  @override
  Future<void> clearPlan({String slot = 'default'}) async {
    _plans.remove(slot);
  }
}
