import '../models/cardio/cardio_result.dart';
import '../models/workout_result.dart';
import 'workout_history_storage.dart';

/// In-memory [WorkoutHistoryStorage] for tests, demos and prototypes.
///
/// Not persisted across app launches — wire your own [WorkoutHistoryStorage]
/// (SQLite, Hive, Supabase, …) for production. Implementations should match
/// this one's ordering contract: newest-first by `finishedAt`.
class InMemoryWorkoutHistoryStorage implements WorkoutHistoryStorage {
  final List<WorkoutResult> _workouts = [];
  final List<CardioResult> _cardio = [];

  int get workoutCount => _workouts.length;
  int get cardioCount => _cardio.length;

  @override
  Future<void> saveWorkout(WorkoutResult result) async {
    _workouts.add(result);
  }

  @override
  Future<void> saveCardio(CardioResult result) async {
    _cardio.add(result);
  }

  @override
  Future<List<WorkoutResult>> recentWorkouts({
    int? limit,
    DateTime? since,
  }) async {
    return _filterAndOrder(
      _workouts,
      sinceAccessor: (r) => r.finishedAt,
      since: since,
      limit: limit,
    );
  }

  @override
  Future<List<CardioResult>> recentCardio({int? limit, DateTime? since}) async {
    return _filterAndOrder(
      _cardio,
      sinceAccessor: (r) => r.finishedAt,
      since: since,
      limit: limit,
    );
  }

  @override
  Future<void> clear() async {
    _workouts.clear();
    _cardio.clear();
  }

  List<T> _filterAndOrder<T>(
    List<T> source, {
    required DateTime Function(T) sinceAccessor,
    DateTime? since,
    int? limit,
  }) {
    final filtered =
        since == null
            ? source.toList()
            : source.where((r) => sinceAccessor(r).isAfter(since)).toList();
    filtered.sort((a, b) => sinceAccessor(b).compareTo(sinceAccessor(a)));
    if (limit != null && filtered.length > limit) {
      return filtered.take(limit).toList();
    }
    return filtered;
  }
}
