import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'runner_storage.dart';

/// Default [RunnerStorage] using [SharedPreferences]. Suitable for most apps.
class PrefsRunnerStorage implements RunnerStorage {
  static const _statePrefix = 'workout_runner.state.';
  static const _planPrefix = 'workout_runner.plan.';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<void> saveState(
    Map<String, dynamic> json, {
    String slot = 'default',
  }) async {
    final prefs = await _prefs;
    await prefs.setString('$_statePrefix$slot', jsonEncode(json));
  }

  @override
  Future<Map<String, dynamic>?> readState({String slot = 'default'}) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_statePrefix$slot');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> clearState({String slot = 'default'}) async {
    final prefs = await _prefs;
    await prefs.remove('$_statePrefix$slot');
  }

  @override
  Future<void> savePlan(
    Map<String, dynamic> json, {
    String slot = 'default',
  }) async {
    final prefs = await _prefs;
    await prefs.setString('$_planPrefix$slot', jsonEncode(json));
  }

  @override
  Future<Map<String, dynamic>?> readPlan({String slot = 'default'}) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_planPrefix$slot');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> clearPlan({String slot = 'default'}) async {
    final prefs = await _prefs;
    await prefs.remove('$_planPrefix$slot');
  }
}
