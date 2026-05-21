import '../models/cardio/cardio_result.dart';
import '../models/workout_result.dart';

/// Optional history sink for finished workouts and cardio sessions.
///
/// `WorkoutRunner` / `CardioRunner` do NOT depend on this — pass results from
/// the `finished` stream (or `onFinished` callback) to a [WorkoutHistoryStorage]
/// implementation yourself. The interface exists so consumers can build stats,
/// progressive overload suggestions, and PR detection on top of a single
/// abstraction instead of re-implementing storage glue per app.
///
/// Implementations should:
///
/// * order recent results newest-first (by `finishedAt`),
/// * honour [since] as a strict lower bound when provided,
/// * treat a `null`/missing [limit] as "no cap".
abstract class WorkoutHistoryStorage {
  Future<void> saveWorkout(WorkoutResult result);
  Future<void> saveCardio(CardioResult result);

  Future<List<WorkoutResult>> recentWorkouts({int? limit, DateTime? since});
  Future<List<CardioResult>> recentCardio({int? limit, DateTime? since});

  Future<void> clear();
}
