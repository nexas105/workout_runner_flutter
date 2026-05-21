import 'package:flutter/foundation.dart';

import '../internal/csv.dart';
import '../internal/energy.dart';
import '../internal/schema.dart';
import 'performed_set.dart';
import 'set_type.dart';

/// Returned by [WorkoutRunner.finish] and emitted via the finished stream.
@immutable
class WorkoutResult {
  final String planId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final Duration duration;
  final List<PerformedExerciseDetails> exercises;

  const WorkoutResult({
    required this.planId,
    required this.startedAt,
    required this.finishedAt,
    required this.duration,
    required this.exercises,
  });

  /// Total number of completed sets across all exercises.
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  /// Total reps across all completed sets.
  int get totalReps => exercises.fold(
    0,
    (sum, e) => sum + e.sets.fold(0, (s, x) => s + x.actualReps),
  );

  /// Sum of (weight × reps) where weight is set.
  double get totalVolume => exercises.fold(
    0.0,
    (sum, e) =>
        sum +
        e.sets.fold(0.0, (s, x) => s + (x.actualWeight ?? 0) * x.actualReps),
  );

  /// Estimated kcal burned across the session. Walks each performed set and
  /// uses the snapshotted MET — falling back to the exercise category default
  /// or [kDefaultMet] when no value was recorded. Sets without a recorded
  /// `duration` contribute zero.
  ///
  /// `kcal ≈ MET × duration_h × bodyWeightKg`.
  double kcal({required double bodyWeightKg}) {
    if (bodyWeightKg <= 0) return 0;
    var total = 0.0;
    for (final ex in exercises) {
      final met = ex.met ?? EnergyEstimator.metForCategoryId(ex.categoryId);
      for (final s in ex.sets) {
        final d = s.duration;
        if (d == null) continue;
        total += EnergyEstimator.kcal(
          met: met,
          duration: d,
          bodyWeightKg: bodyWeightKg,
        );
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': kPluginSchemaVersion,
    'planId': planId,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'duration': duration.inSeconds,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  /// Flat per-set CSV — one row per performed set. Useful when piping results
  /// into spreadsheets or simple analytics pipelines. Columns:
  ///
  ///     planId, exerciseId, exerciseName, exerciseIndex, setIndex,
  ///     type, actualReps, actualWeight, rir, durationSec, pauseSec,
  ///     completedAt
  ///
  /// `\n` line terminators. Header row included. Empty results still emit a
  /// header so consumers can append rows without sniffing.
  String toCsv({bool includeHeader = true}) {
    final buf = StringBuffer();
    if (includeHeader) {
      buf.writeln(
        csvRow(const [
          'planId',
          'exerciseId',
          'exerciseName',
          'exerciseIndex',
          'setIndex',
          'type',
          'actualReps',
          'actualWeight',
          'rir',
          'durationSec',
          'pauseSec',
          'completedAt',
        ]),
      );
    }
    for (final ex in exercises) {
      for (final s in ex.sets) {
        buf.writeln(
          csvRow([
            planId,
            ex.exerciseId,
            ex.exerciseName,
            s.exerciseIndex,
            s.setIndex,
            s.type == SetType.working ? '' : s.type.id,
            s.actualReps,
            s.actualWeight,
            s.rir,
            s.duration?.inSeconds,
            s.pause?.inSeconds,
            s.completedAt.toIso8601String(),
          ]),
        );
      }
    }
    return buf.toString();
  }

  factory WorkoutResult.fromJson(Map<String, dynamic> json) => WorkoutResult(
    planId: json['planId'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: DateTime.parse(json['finishedAt'] as String),
    duration: Duration(seconds: (json['duration'] as num).toInt()),
    exercises:
        (json['exercises'] as List<dynamic>)
            .map(
              (e) =>
                  PerformedExerciseDetails.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
  );
}

@immutable
class PerformedExerciseDetails {
  final String exerciseId;
  final String exerciseName;
  final List<PerformedSet> sets;

  /// MET snapshot from the original [WorkoutExercise] at finish time. Used by
  /// [WorkoutResult.kcal] when computing energy expenditure. `null` means
  /// "fall back to the category default or [kDefaultMet]".
  final double? met;

  /// Category id snapshot, used as a fallback when [met] is null. Plain
  /// string to keep the result self-contained — no extra type import needed
  /// for consumers.
  final String? categoryId;

  /// Original exercise id when this slot was substituted mid-session via
  /// `WorkoutRunner.substituteExercise(...)`. `null` for first-class plan
  /// entries.
  final String? substitutedFrom;

  const PerformedExerciseDetails({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.met,
    this.categoryId,
    this.substitutedFrom,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
    if (met != null) 'met': met,
    if (categoryId != null) 'categoryId': categoryId,
    if (substitutedFrom != null) 'substitutedFrom': substitutedFrom,
  };

  factory PerformedExerciseDetails.fromJson(Map<String, dynamic> json) =>
      PerformedExerciseDetails(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        sets:
            (json['sets'] as List<dynamic>)
                .map((s) => PerformedSet.fromJson(s as Map<String, dynamic>))
                .toList(),
        met: (json['met'] as num?)?.toDouble(),
        categoryId: json['categoryId'] as String?,
        substitutedFrom: json['substitutedFrom'] as String?,
      );
}
