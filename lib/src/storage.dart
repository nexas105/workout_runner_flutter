import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class RunnerStorage {
  //Runnser State
  Future<void> saveState({
    String key = "default",
    required Map<String, dynamic> json,
  });
  Future<Map<String, dynamic>?> readState({String key = "default"});
  Future<void> clearState({String key = "default"});

  // der Plan
  Future<void> savePlan({
    String key = "default",
    required Map<String, dynamic> json,
  });
  Future<Map<String, dynamic>?> readPlan({String key = "default"});
  Future<void> clearPlan({String key = "default"});
}

class PrefsRunnerStorage implements RunnerStorage {
  static const _prefix = 'workout_runner_state_';
  static const _prefix_plan = 'workout_plan_';

  @override
  Future<void> saveState({
    String key = "default",
    required Map<String, dynamic> json,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('$_prefix$key', jsonEncode(json));
  }

  @override
  Future<Map<String, dynamic>?> readState({String key = "default"}) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('$_prefix$key');
    return s == null ? null : (jsonDecode(s) as Map<String, dynamic>);
  }

  @override
  Future<void> clearState({String key = "default"}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  @override
  Future<void> savePlan({
    String key = "default",
    required Map<String, dynamic> json,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('$_prefix_plan$key', jsonEncode(json));
  }

  @override
  Future<Map<String, dynamic>?> readPlan({String key = "default"}) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('$_prefix_plan$key');
    return s == null ? null : (jsonDecode(s) as Map<String, dynamic>);
  }

  @override
  Future<void> clearPlan({String key = "default"}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix_plan$key');
  }
}
