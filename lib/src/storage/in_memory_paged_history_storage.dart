import 'dart:convert';

import '../models/cardio/cardio_result.dart';
import '../models/workout_result.dart';
import 'paged_history_storage.dart';
import 'workout_history_storage.dart';

/// In-memory history sink that implements both the eager
/// [WorkoutHistoryStorage] contract and the cursor-based
/// [PagedWorkoutHistoryStorage] contract.
///
/// The cursor is an opaque base64 token wrapping the next item index in the
/// sorted, filtered view. Callers must treat it as a black box — the encoding
/// is intentionally not part of the public contract.
class InMemoryPagedHistoryStorage
    implements WorkoutHistoryStorage, PagedWorkoutHistoryStorage {
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
      finishedAt: (r) => r.finishedAt,
      since: since,
      limit: limit,
    );
  }

  @override
  Future<List<CardioResult>> recentCardio({int? limit, DateTime? since}) async {
    return _filterAndOrder(
      _cardio,
      finishedAt: (r) => r.finishedAt,
      since: since,
      limit: limit,
    );
  }

  @override
  Future<void> clear() async {
    _workouts.clear();
    _cardio.clear();
  }

  @override
  Future<HistoryPage<WorkoutResult>> pagedWorkouts({
    int limit = 50,
    String? cursor,
    DateTime? since,
  }) async {
    return _page<WorkoutResult>(
      _workouts,
      finishedAt: (r) => r.finishedAt,
      limit: limit,
      cursor: cursor,
      since: since,
    );
  }

  @override
  Future<HistoryPage<CardioResult>> pagedCardio({
    int limit = 50,
    String? cursor,
    DateTime? since,
  }) async {
    return _page<CardioResult>(
      _cardio,
      finishedAt: (r) => r.finishedAt,
      limit: limit,
      cursor: cursor,
      since: since,
    );
  }

  @override
  Future<int> workoutCountSince(DateTime? since) async =>
      _countSince(_workouts, (r) => r.finishedAt, since);

  @override
  Future<int> cardioCountSince(DateTime? since) async =>
      _countSince(_cardio, (r) => r.finishedAt, since);

  HistoryPage<T> _page<T>(
    List<T> source, {
    required DateTime Function(T) finishedAt,
    required int limit,
    required String? cursor,
    required DateTime? since,
  }) {
    if (limit <= 0) {
      return HistoryPage<T>(
        items: const [],
        totalCount: _countSince(source, finishedAt, since),
        nextCursor: null,
      );
    }
    final ordered = _filterAndOrder(
      source,
      finishedAt: finishedAt,
      since: since,
      limit: null,
    );
    final start = cursor == null ? 0 : _decodeCursor(cursor);
    if (start >= ordered.length) {
      return HistoryPage<T>(
        items: const [],
        totalCount: ordered.length,
        nextCursor: null,
      );
    }
    final end =
        (start + limit) > ordered.length ? ordered.length : (start + limit);
    final slice = ordered.sublist(start, end);
    final next = end < ordered.length ? _encodeCursor(end) : null;
    return HistoryPage<T>(
      items: slice,
      totalCount: ordered.length,
      nextCursor: next,
    );
  }

  int _countSince<T>(
    List<T> source,
    DateTime Function(T) finishedAt,
    DateTime? since,
  ) {
    if (since == null) return source.length;
    var n = 0;
    for (final item in source) {
      if (finishedAt(item).isAfter(since)) n++;
    }
    return n;
  }

  List<T> _filterAndOrder<T>(
    List<T> source, {
    required DateTime Function(T) finishedAt,
    DateTime? since,
    int? limit,
  }) {
    final filtered =
        since == null
            ? source.toList()
            : source.where((r) => finishedAt(r).isAfter(since)).toList();
    filtered.sort((a, b) => finishedAt(b).compareTo(finishedAt(a)));
    if (limit != null && filtered.length > limit) {
      return filtered.take(limit).toList();
    }
    return filtered;
  }

  static String _encodeCursor(int index) =>
      base64Url.encode(utf8.encode(index.toString()));

  static int _decodeCursor(String cursor) {
    try {
      final decoded = utf8.decode(base64Url.decode(cursor));
      final parsed = int.tryParse(decoded);
      if (parsed == null || parsed < 0) return 0;
      return parsed;
    } catch (_) {
      return 0;
    }
  }
}
