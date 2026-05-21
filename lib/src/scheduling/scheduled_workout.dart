/// Status buckets a [ScheduledWorkout] can fall into.
///
/// `upcoming` — planned and still actionable.
/// `completed` — the user finished the workout.
/// `skipped` — the user explicitly marked it skipped.
/// `cancelled` — never started and the scheduled slot has passed
/// (see [ScheduledWorkout.derivedStatus] for the staleness rule).
enum ScheduledStatus { upcoming, completed, skipped, cancelled }

/// Threshold past which an unstarted, unskipped, uncompleted entry is
/// considered stale and treated as [ScheduledStatus.cancelled] by
/// [ScheduledWorkout.derivedStatus].
const Duration _kStaleAfter = Duration(days: 1);

/// Lightweight planning DTO above `WorkoutPlan` / `CardioPlan`.
///
/// Records the intent to run plan [planId] at [scheduledAt]. No executor is
/// attached — consumers pick the right runner via [isCardio] and pass the
/// resolved plan in themselves.
class ScheduledWorkout {
  final String id;
  final String planId;
  final String? planName;
  final bool isCardio;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? skippedAt;
  final String? notes;
  final Map<String, dynamic>? meta;

  const ScheduledWorkout({
    required this.id,
    required this.planId,
    required this.scheduledAt,
    this.planName,
    this.isCardio = false,
    this.startedAt,
    this.completedAt,
    this.skippedAt,
    this.notes,
    this.meta,
  });

  /// Status derived from the timestamps. Order of precedence:
  ///
  /// 1. [completedAt] wins over everything else.
  /// 2. [skippedAt] beats staleness.
  /// 3. If [scheduledAt] is in the past by at least [_kStaleAfter] and the
  ///    workout never started → [ScheduledStatus.cancelled].
  /// 4. Otherwise → [ScheduledStatus.upcoming].
  ScheduledStatus get derivedStatus {
    if (completedAt != null) return ScheduledStatus.completed;
    if (skippedAt != null) return ScheduledStatus.skipped;
    if (startedAt == null) {
      final now = DateTime.now();
      if (now.difference(scheduledAt) >= _kStaleAfter) {
        return ScheduledStatus.cancelled;
      }
    }
    return ScheduledStatus.upcoming;
  }

  ScheduledWorkout copyWith({
    String? id,
    String? planId,
    Object? planName = _unset,
    bool? isCardio,
    DateTime? scheduledAt,
    Object? startedAt = _unset,
    Object? completedAt = _unset,
    Object? skippedAt = _unset,
    Object? notes = _unset,
    Object? meta = _unset,
  }) {
    return ScheduledWorkout(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      planName:
          identical(planName, _unset) ? this.planName : planName as String?,
      isCardio: isCardio ?? this.isCardio,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt:
          identical(startedAt, _unset) ? this.startedAt : startedAt as DateTime?,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      skippedAt:
          identical(skippedAt, _unset) ? this.skippedAt : skippedAt as DateTime?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      meta: identical(meta, _unset)
          ? this.meta
          : meta as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        if (planName != null) 'planName': planName,
        'isCardio': isCardio,
        'scheduledAt': scheduledAt.toIso8601String(),
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (skippedAt != null) 'skippedAt': skippedAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (meta != null) 'meta': meta,
      };

  factory ScheduledWorkout.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(Object? raw) =>
        raw is String ? DateTime.parse(raw) : null;
    return ScheduledWorkout(
      id: json['id'] as String,
      planId: json['planId'] as String,
      planName: json['planName'] as String?,
      isCardio: (json['isCardio'] as bool?) ?? false,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      startedAt: parseOpt(json['startedAt']),
      completedAt: parseOpt(json['completedAt']),
      skippedAt: parseOpt(json['skippedAt']),
      notes: json['notes'] as String?,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

const Object _unset = Object();

/// Pure query helpers over a list of [ScheduledWorkout]. Apps own the storage
/// of the underlying list; these helpers never mutate the input.
abstract class ScheduledWorkoutQuery {
  /// Entries falling in `[now, now + horizon)` whose [ScheduledWorkout.derivedStatus]
  /// is [ScheduledStatus.upcoming]. Sorted ascending by [ScheduledWorkout.scheduledAt].
  static List<ScheduledWorkout> upcoming(
    List<ScheduledWorkout> all, {
    DateTime? now,
    Duration horizon = const Duration(days: 14),
  }) {
    final ref = now ?? DateTime.now();
    final end = ref.add(horizon);
    final result = <ScheduledWorkout>[];
    for (final s in all) {
      if (s.derivedStatus != ScheduledStatus.upcoming) continue;
      if (s.scheduledAt.isBefore(ref)) continue;
      if (!s.scheduledAt.isBefore(end)) continue;
      result.add(s);
    }
    result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return result;
  }

  /// Entries whose [ScheduledWorkout.scheduledAt] local-date equals
  /// `now`'s local date. Returned in chronological order.
  static List<ScheduledWorkout> today(
    List<ScheduledWorkout> all, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final result = all.where((s) {
      final at = s.scheduledAt;
      return at.year == ref.year &&
          at.month == ref.month &&
          at.day == ref.day;
    }).toList();
    result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return result;
  }
}
