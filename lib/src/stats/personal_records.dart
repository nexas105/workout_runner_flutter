import '../models/cardio/cardio_result.dart';
import '../models/workout_result.dart';

/// Kinds of personal record this module can detect.
///
/// Strength-side PRs are scoped to a specific exercise. Cardio-side PRs are
/// session-wide (per `CardioResult`) and use `exerciseId == null` on
/// [PersonalRecord].
enum PrType {
  /// Heaviest weight handled on a single working set.
  maxWeight,

  /// Highest rep count achieved at the heaviest weight ever lifted.
  maxReps,

  /// Estimated one-rep max via the Epley formula
  /// (`weight × (1 + reps/30)`) — restricted to sets with reps in [1..15].
  estimated1RM,

  /// Highest single-set volume (`weight × reps`).
  bestVolumeSet,

  /// Cardio: longest total distance covered in a single session.
  longestDistance,

  /// Cardio: fastest average pace (seconds per km, lower is better) across a
  /// session that recorded distance.
  fastestPace,

  /// Cardio: longest summed working time across laps in a session.
  longestWorkTime,
}

String _prTypeId(PrType t) {
  switch (t) {
    case PrType.maxWeight:
      return 'maxWeight';
    case PrType.maxReps:
      return 'maxReps';
    case PrType.estimated1RM:
      return 'estimated1RM';
    case PrType.bestVolumeSet:
      return 'bestVolumeSet';
    case PrType.longestDistance:
      return 'longestDistance';
    case PrType.fastestPace:
      return 'fastestPace';
    case PrType.longestWorkTime:
      return 'longestWorkTime';
  }
}

PrType _prTypeFromId(String id) {
  for (final t in PrType.values) {
    if (_prTypeId(t) == id) return t;
  }
  throw ArgumentError('Unknown PrType id: $id');
}

/// A single personal record detected from history.
///
/// Pure data — no UI, no Flutter dependency. Equality is value-based on the
/// tuple ([exerciseId], [type], [value], [achievedAt], [sourceResultId]).
class PersonalRecord {
  /// Exercise the PR belongs to. `null` for cardio session-wide PRs.
  final String? exerciseId;
  final PrType type;

  /// Numeric value in [unit]:
  /// - `maxWeight`, `estimated1RM` → kilograms
  /// - `maxReps` → repetitions
  /// - `bestVolumeSet` → kilogram-reps (kg × reps)
  /// - `longestDistance` → meters
  /// - `fastestPace` → seconds per kilometer (lower is better)
  /// - `longestWorkTime` → seconds
  final double value;
  final String unit;
  final DateTime achievedAt;

  /// Stable id of the result this PR was extracted from — `planId|finishedAt`.
  /// Useful for traceability back to the originating session.
  final String sourceResultId;

  const PersonalRecord({
    required this.exerciseId,
    required this.type,
    required this.value,
    required this.unit,
    required this.achievedAt,
    required this.sourceResultId,
  });

  Map<String, dynamic> toJson() => {
    if (exerciseId != null) 'exerciseId': exerciseId,
    'type': _prTypeId(type),
    'value': value,
    'unit': unit,
    'achievedAt': achievedAt.toIso8601String(),
    'sourceResultId': sourceResultId,
  };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
    exerciseId: json['exerciseId'] as String?,
    type: _prTypeFromId(json['type'] as String),
    value: (json['value'] as num).toDouble(),
    unit: json['unit'] as String,
    achievedAt: DateTime.parse(json['achievedAt'] as String),
    sourceResultId: json['sourceResultId'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalRecord &&
          other.exerciseId == exerciseId &&
          other.type == type &&
          other.value == value &&
          other.unit == unit &&
          other.achievedAt == achievedAt &&
          other.sourceResultId == sourceResultId);

  @override
  int get hashCode => Object.hash(
    exerciseId,
    type,
    value,
    unit,
    achievedAt,
    sourceResultId,
  );

  @override
  String toString() =>
      'PersonalRecord(exerciseId: $exerciseId, type: ${_prTypeId(type)}, '
      'value: $value $unit, achievedAt: ${achievedAt.toIso8601String()})';
}

/// Pure helpers that scan workout/cardio history for personal records.
///
/// All methods are side-effect free. Order of returned PRs follows the
/// declaration order of [PrType] — callers should not rely on tie-break order
/// beyond that.
abstract class PersonalRecords {
  PersonalRecords._();

  /// Detects weight-based PRs for a single [exerciseId] across [history].
  ///
  /// Returns up to four records (one per applicable [PrType]): [PrType.maxWeight],
  /// [PrType.maxReps] (top reps at the heaviest weight ever lifted),
  /// [PrType.estimated1RM] and [PrType.bestVolumeSet]. Sets without
  /// `actualWeight` are skipped — bodyweight exercises therefore produce no
  /// PRs from this method.
  static List<PersonalRecord> forExercise(
    String exerciseId,
    List<WorkoutResult> history,
  ) {
    _SetHit? maxWeight;
    _SetHit? maxRepsAtTopWeight;
    _SetHit? best1Rm;
    _SetHit? bestVolume;

    for (final result in history) {
      final src = _sourceId(result);
      for (final ex in result.exercises) {
        if (ex.exerciseId != exerciseId) continue;
        for (final s in ex.sets) {
          final weight = s.actualWeight;
          if (weight == null) continue;
          final reps = s.actualReps;
          if (reps <= 0) continue;

          // maxWeight — strictly heavier wins; on ties, the EARLIER set wins
          // (so re-hitting a previous best isn't reported as a fresh PR).
          if (_beats(maxWeight, weight, s.completedAt)) {
            maxWeight = _SetHit(weight, s.completedAt, src);
          }

          // bestVolumeSet — weight × reps, strictly greater wins; ties: earlier.
          final volume = weight * reps;
          if (_beats(bestVolume, volume, s.completedAt)) {
            bestVolume = _SetHit(volume, s.completedAt, src);
          }

          // estimated1RM via Epley, only for reps in [1..15] inclusive.
          if (reps >= 1 && reps <= 15) {
            final e1rm = weight * (1 + reps / 30.0);
            if (_beats(best1Rm, e1rm, s.completedAt)) {
              best1Rm = _SetHit(e1rm, s.completedAt, src);
            }
          }
        }
      }
    }

    if (maxWeight == null) return const [];

    // maxReps PR is scoped to the heaviest weight ever lifted on this
    // exercise: find the largest rep count recorded at that weight. On ties
    // the earlier-in-time set wins so re-hits don't masquerade as fresh PRs.
    final topWeight = maxWeight.value;
    for (final result in history) {
      final src = _sourceId(result);
      for (final ex in result.exercises) {
        if (ex.exerciseId != exerciseId) continue;
        for (final s in ex.sets) {
          if (s.actualWeight != topWeight) continue;
          final reps = s.actualReps.toDouble();
          if (reps <= 0) continue;
          if (_beats(maxRepsAtTopWeight, reps, s.completedAt)) {
            maxRepsAtTopWeight = _SetHit(reps, s.completedAt, src);
          }
        }
      }
    }

    final prs = <PersonalRecord>[
      PersonalRecord(
        exerciseId: exerciseId,
        type: PrType.maxWeight,
        value: maxWeight.value,
        unit: 'kg',
        achievedAt: maxWeight.at,
        sourceResultId: maxWeight.sourceId,
      ),
      if (maxRepsAtTopWeight != null)
        PersonalRecord(
          exerciseId: exerciseId,
          type: PrType.maxReps,
          value: maxRepsAtTopWeight.value,
          unit: 'reps',
          achievedAt: maxRepsAtTopWeight.at,
          sourceResultId: maxRepsAtTopWeight.sourceId,
        ),
      if (best1Rm != null)
        PersonalRecord(
          exerciseId: exerciseId,
          type: PrType.estimated1RM,
          value: best1Rm.value,
          unit: 'kg',
          achievedAt: best1Rm.at,
          sourceResultId: best1Rm.sourceId,
        ),
      if (bestVolume != null)
        PersonalRecord(
          exerciseId: exerciseId,
          type: PrType.bestVolumeSet,
          value: bestVolume.value,
          unit: 'kg·reps',
          achievedAt: bestVolume.at,
          sourceResultId: bestVolume.sourceId,
        ),
    ];
    return prs;
  }

  /// FlatMap of [forExercise] across every distinct `exerciseId` that appears
  /// in [history]. Exercise iteration order follows the first occurrence in
  /// the history list so output is deterministic.
  static List<PersonalRecord> forAllExercises(List<WorkoutResult> history) {
    final seen = <String>{};
    final order = <String>[];
    for (final r in history) {
      for (final ex in r.exercises) {
        if (seen.add(ex.exerciseId)) order.add(ex.exerciseId);
      }
    }
    final out = <PersonalRecord>[];
    for (final id in order) {
      out.addAll(forExercise(id, history));
    }
    return out;
  }

  /// Cardio PRs across [history]:
  /// * [PrType.longestDistance] — biggest `totalDistanceMeters` (>0).
  /// * [PrType.fastestPace] — lowest result-level `avgPacePerKm` across
  ///   sessions that actually recorded distance.
  /// * [PrType.longestWorkTime] — biggest summed lap time per session.
  ///
  /// Returns up to three records. Empty history yields an empty list.
  static List<PersonalRecord> forCardio(List<CardioResult> history) {
    _CardioHit? longestDistance;
    _CardioHit? fastestPace;
    _CardioHit? longestWorkTime;

    for (final r in history) {
      final src = _cardioSourceId(r);
      final at = r.finishedAt;

      final dist = r.totalDistanceMeters;
      if (dist > 0 && _beatsCardio(longestDistance, dist, at, higherWins: true)) {
        longestDistance = _CardioHit(dist, at, src);
      }

      final pace = r.avgPacePerKm;
      if (pace != null && pace.inSeconds > 0) {
        final paceSecs = pace.inSeconds.toDouble();
        if (_beatsCardio(fastestPace, paceSecs, at, higherWins: false)) {
          fastestPace = _CardioHit(paceSecs, at, src);
        }
      }

      final work = r.totalWorkTime.inSeconds.toDouble();
      if (work > 0 &&
          _beatsCardio(longestWorkTime, work, at, higherWins: true)) {
        longestWorkTime = _CardioHit(work, at, src);
      }
    }

    return <PersonalRecord>[
      if (longestDistance != null)
        PersonalRecord(
          exerciseId: null,
          type: PrType.longestDistance,
          value: longestDistance.value,
          unit: 'm',
          achievedAt: longestDistance.at,
          sourceResultId: longestDistance.sourceId,
        ),
      if (fastestPace != null)
        PersonalRecord(
          exerciseId: null,
          type: PrType.fastestPace,
          value: fastestPace.value,
          unit: 's/km',
          achievedAt: fastestPace.at,
          sourceResultId: fastestPace.sourceId,
        ),
      if (longestWorkTime != null)
        PersonalRecord(
          exerciseId: null,
          type: PrType.longestWorkTime,
          value: longestWorkTime.value,
          unit: 's',
          achievedAt: longestWorkTime.at,
          sourceResultId: longestWorkTime.sourceId,
        ),
    ];
  }

  /// Returns the subset of PRs that were *first* achieved inside [result]'s
  /// session window (`[startedAt, finishedAt]`, inclusive).
  ///
  /// Computed as `forAllExercises([result, ...priorHistory])` filtered by
  /// `achievedAt` falling within the window — so a PR that ties an earlier
  /// best is **not** reported as new (only strictly-greater values win in
  /// [forExercise]).
  static List<PersonalRecord> newRecordsIn(
    WorkoutResult result,
    List<WorkoutResult> priorHistory,
  ) {
    final combined = <WorkoutResult>[result, ...priorHistory];
    final all = forAllExercises(combined);
    final from = result.startedAt;
    final to = result.finishedAt;
    return [
      for (final pr in all)
        if (!pr.achievedAt.isBefore(from) && !pr.achievedAt.isAfter(to)) pr,
    ];
  }
}

String _sourceId(WorkoutResult r) =>
    '${r.planId}|${r.finishedAt.toIso8601String()}';

String _cardioSourceId(CardioResult r) =>
    '${r.planId}|${r.finishedAt.toIso8601String()}';

/// True when [candidate] should replace [current]: strictly greater value, or
/// equal value with an earlier timestamp. Used so re-hitting a previous PR
/// does not register as a fresh achievement.
bool _beats(_SetHit? current, double candidate, DateTime at) {
  if (current == null) return true;
  if (candidate > current.value) return true;
  if (candidate == current.value && at.isBefore(current.at)) return true;
  return false;
}

/// Cardio variant — set [higherWins] to false for metrics where lower is
/// better (e.g. pace seconds-per-km).
bool _beatsCardio(
  _CardioHit? current,
  double candidate,
  DateTime at, {
  required bool higherWins,
}) {
  if (current == null) return true;
  final strictBetter =
      higherWins ? candidate > current.value : candidate < current.value;
  if (strictBetter) return true;
  if (candidate == current.value && at.isBefore(current.at)) return true;
  return false;
}

class _SetHit {
  final double value;
  final DateTime at;
  final String sourceId;
  const _SetHit(this.value, this.at, this.sourceId);
}

class _CardioHit {
  final double value;
  final DateTime at;
  final String sourceId;
  const _CardioHit(this.value, this.at, this.sourceId);
}
