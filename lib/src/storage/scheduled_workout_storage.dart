import 'dart:async';

import '../scheduling/scheduled_workout.dart';

/// Optional storage for [ScheduledWorkout] entries. Apps wire this to whatever
/// key/value persistence layer they prefer (SharedPreferences, Hive, sqflite …).
///
/// Implementations should:
///
/// * key entries by [ScheduledWorkout.id] (upsert replaces by id),
/// * return [all] sorted ascending by [ScheduledWorkout.scheduledAt].
abstract class ScheduledWorkoutStorage {
  Future<void> upsert(ScheduledWorkout scheduled);
  Future<ScheduledWorkout?> read(String id);
  Future<List<ScheduledWorkout>> all();
  Future<void> remove(String id);
  Future<void> clear();
}

/// In-memory [ScheduledWorkoutStorage] for tests, demos and prototypes.
///
/// Not persisted across launches — wire a SharedPreferences/Hive-backed
/// implementation for production use.
class InMemoryScheduledWorkoutStorage implements ScheduledWorkoutStorage {
  final Map<String, ScheduledWorkout> _entries = <String, ScheduledWorkout>{};

  @override
  Future<void> upsert(ScheduledWorkout scheduled) async {
    _entries[scheduled.id] = scheduled;
  }

  @override
  Future<ScheduledWorkout?> read(String id) async {
    return _entries[id];
  }

  @override
  Future<List<ScheduledWorkout>> all() async {
    final list =
        _entries.values.toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  @override
  Future<void> remove(String id) async {
    _entries.remove(id);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}
