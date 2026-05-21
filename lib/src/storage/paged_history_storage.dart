import '../models/cardio/cardio_result.dart';
import '../models/workout_result.dart';

/// Slice of a history sink for cursor-based iteration over large result sets.
///
/// [items] is at most `limit` long, ordered newest-first by `finishedAt`.
/// [totalCount] reflects the filtered total (after `since`), not the page.
/// [nextCursor] is an opaque token that callers pass back to fetch the next
/// page; `null` means the current page is the last one.
class HistoryPage<T> {
  final List<T> items;
  final int totalCount;
  final String? nextCursor;

  const HistoryPage({
    required this.items,
    required this.totalCount,
    required this.nextCursor,
  });

  bool get hasMore => nextCursor != null;
}

/// Optional pagination contract that sits next to [WorkoutHistoryStorage].
///
/// Implementations typically `implements WorkoutHistoryStorage,
/// PagedWorkoutHistoryStorage` so callers can opt-in to cursor paging without
/// breaking code that consumes the eager list interface. Use this when the
/// underlying store can hold thousands of results and loading the full list
/// for a single stat would be wasteful.
///
/// Contract:
///
/// * Pages are ordered newest-first by `finishedAt`.
/// * `cursor` is an opaque, implementation-defined token returned by a prior
///   call. Callers must not interpret it.
/// * `since` is a strict lower bound. When combined with a `cursor`, the
///   `since` value must match the one used to obtain the cursor — mixing
///   filters across pages is undefined behaviour.
/// * `nextCursor` is `null` exactly when no further items remain for the
///   current filter.
abstract class PagedWorkoutHistoryStorage {
  Future<HistoryPage<WorkoutResult>> pagedWorkouts({
    int limit = 50,
    String? cursor,
    DateTime? since,
  });

  Future<HistoryPage<CardioResult>> pagedCardio({
    int limit = 50,
    String? cursor,
    DateTime? since,
  });

  Future<int> workoutCountSince(DateTime? since);
  Future<int> cardioCountSince(DateTime? since);
}
