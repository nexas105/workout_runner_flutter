import '../models/cardio/cardio_result.dart';
import '../models/workout_result.dart';

abstract class Redaction {
  static WorkoutResult anonymized(WorkoutResult r) => WorkoutResult(
    planId: 'redacted',
    startedAt: r.startedAt,
    finishedAt: r.finishedAt,
    duration: r.duration,
    exercises: [
      for (var i = 0; i < r.exercises.length; i++)
        PerformedExerciseDetails(
          exerciseId: r.exercises[i].exerciseId,
          exerciseName: 'exercise_$i',
          sets: r.exercises[i].sets,
          met: r.exercises[i].met,
          categoryId: r.exercises[i].categoryId,
        ),
    ],
  );

  // Dart cannot overload on parameter type, so the cardio variant gets a
  // suffix while keeping a parallel shape to [anonymized].
  static CardioResult anonymizedCardio(CardioResult r) => CardioResult(
    planId: 'redacted',
    planName: 'redacted',
    discipline: r.discipline,
    startedAt: r.startedAt,
    finishedAt: r.finishedAt,
    duration: r.duration,
    laps: r.laps,
    meta: r.meta,
  );

  static Map<String, dynamic> redactedJson(
    Map<String, dynamic> json, {
    Set<String> drop = const {
      'planId',
      'planName',
      'exerciseName',
      'notes',
      'meta',
    },
  }) {
    final out = <String, dynamic>{};
    json.forEach((key, value) {
      if (drop.contains(key)) return;
      out[key] = _walk(value, drop);
    });
    return out;
  }

  static Object? _walk(Object? value, Set<String> drop) {
    if (value is Map) {
      final m = <String, dynamic>{};
      value.forEach((k, v) {
        final ks = k.toString();
        if (drop.contains(ks)) return;
        m[ks] = _walk(v, drop);
      });
      return m;
    }
    if (value is List) {
      return value.map((e) => _walk(e, drop)).toList();
    }
    return value;
  }
}
