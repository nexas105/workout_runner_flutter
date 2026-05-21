import 'dart:async';

import '../models/workout_result.dart';
import '../storage/paged_history_storage.dart';

/// Lazy/streaming aggregations over a [PagedWorkoutHistoryStorage].
///
/// These helpers walk the underlying history one page at a time so apps with
/// 10k+ workouts can compute totals or render newest-first lists without ever
/// holding the full result list in memory. All entry points are pure functions
/// over the storage cursor — no internal state is retained between calls.
abstract class StreamingStats {
  /// Walks every [WorkoutResult] newest-first, accumulating
  /// [WorkoutResult.totalVolume]. Cheap to call repeatedly — the storage layer
  /// owns the actual data; this helper just pages through it.
  static Future<double> totalVolume(
    PagedWorkoutHistoryStorage storage, {
    DateTime? since,
    int pageSize = 200,
  }) async {
    var total = 0.0;
    await for (final result in walk(
      storage,
      since: since,
      pageSize: pageSize,
    )) {
      total += result.totalVolume;
    }
    return total;
  }

  /// Walks every [WorkoutResult] newest-first, counting every performed set
  /// across every exercise.
  static Future<int> totalSets(
    PagedWorkoutHistoryStorage storage, {
    DateTime? since,
    int pageSize = 200,
  }) async {
    var total = 0;
    await for (final result in walk(
      storage,
      since: since,
      pageSize: pageSize,
    )) {
      for (final ex in result.exercises) {
        total += ex.sets.length;
      }
    }
    return total;
  }

  /// Async-iterates every [WorkoutResult] newest-first. Useful for custom
  /// aggregations that want to short-circuit (`break`) once they have enough
  /// data — the next page is never fetched.
  static Stream<WorkoutResult> walk(
    PagedWorkoutHistoryStorage storage, {
    DateTime? since,
    int pageSize = 200,
  }) async* {
    final size = pageSize > 0 ? pageSize : 1;
    String? cursor;
    while (true) {
      final page = await storage.pagedWorkouts(
        limit: size,
        cursor: cursor,
        since: since,
      );
      for (final item in page.items) {
        yield item;
      }
      if (!page.hasMore) return;
      cursor = page.nextCursor;
    }
  }
}
