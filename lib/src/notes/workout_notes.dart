import '../models/workout_exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_result.dart';

abstract class WorkoutNotes {
  static String? readSessionNote(WorkoutPlan plan) {
    final raw = plan.meta?['sessionNote'];
    return raw is String ? raw : null;
  }

  static WorkoutPlan writeSessionNote(WorkoutPlan plan, String? note) {
    final next = <String, dynamic>{...?plan.meta};
    if (note == null) {
      next.remove('sessionNote');
    } else {
      next['sessionNote'] = note;
    }
    return plan.copyWith(meta: next.isEmpty ? null : next);
  }

  static String? readExerciseNote(WorkoutExercise ex) {
    final raw = ex.meta?['note'];
    return raw is String ? raw : null;
  }

  static WorkoutExercise writeExerciseNote(WorkoutExercise ex, String? note) {
    final next = <String, dynamic>{...?ex.meta};
    if (note == null) {
      next.remove('note');
    } else {
      next['note'] = note;
    }
    return ex.copyWith(meta: next.isEmpty ? null : next);
  }

  static String setNoteKey(int exerciseIndex, int setIndex) =>
      '$exerciseIndex.$setIndex';

  /// Best-effort read of a session note attached to the first performed
  /// exercise's `meta` map. `PerformedExerciseDetails` has no `meta` field
  /// today, so this returns `null` until the model exposes one — kept here
  /// so callers can wire the helper now and not change the call site later.
  static String? readResultSessionNote(WorkoutResult result) {
    if (result.exercises.isEmpty) return null;
    final first = result.exercises.first;
    final dyn = first as dynamic;
    try {
      final meta = dyn.meta;
      if (meta is Map) {
        final raw = meta['sessionNote'];
        if (raw is String) return raw;
      }
    } catch (_) {}
    return null;
  }
}
