import 'package:flutter/foundation.dart';

import '../../internal/csv.dart';
import '../../internal/energy.dart';
import '../../internal/schema.dart';
import 'cardio_lap.dart';
import 'cardio_plan.dart';

/// Returned by `CardioRunner.finish` and emitted via its finished stream.
/// Counterpart of `WorkoutResult` on the strength side.
@immutable
class CardioResult {
  final String planId;
  final String planName;
  final CardioDiscipline discipline;
  final DateTime startedAt;
  final DateTime finishedAt;
  final Duration duration;
  final List<CardioLap> laps;

  /// Verbatim copy of `CardioPlan.meta` at finish time. Useful when consumers
  /// tag plans with their own fields (level, source, app feature, …) and want
  /// them back on the result without re-joining.
  final Map<String, dynamic>? meta;

  const CardioResult({
    required this.planId,
    required this.planName,
    required this.discipline,
    required this.startedAt,
    required this.finishedAt,
    required this.duration,
    required this.laps,
    this.meta,
  });

  int get totalLaps => laps.length;

  Duration get totalWorkTime =>
      laps.fold(Duration.zero, (acc, l) => acc + l.duration);

  double get totalDistanceMeters =>
      laps.fold(0.0, (acc, l) => acc + (l.distanceMeters ?? 0));

  /// Estimated kcal burned across the session. Walks each lap and uses its
  /// snapshotted MET, falling back to the discipline default. Laps with zero
  /// duration contribute nothing.
  double kcal({required double bodyWeightKg}) {
    if (bodyWeightKg <= 0) return 0;
    final fallback = EnergyEstimator.metForDiscipline(discipline);
    var total = 0.0;
    for (final lap in laps) {
      total += EnergyEstimator.kcal(
        met: lap.met ?? fallback,
        duration: lap.duration,
        bodyWeightKg: bodyWeightKg,
      );
    }
    return total;
  }

  /// Average pace (seconds per km) across laps that had a distance recorded.
  /// Returns `null` when no laps reported distance.
  Duration? get avgPacePerKm {
    final timed = laps.where(
      (l) => (l.distanceMeters ?? 0) > 0 && l.duration.inSeconds > 0,
    );
    if (timed.isEmpty) return null;
    final totalSeconds = timed.fold<int>(0, (a, l) => a + l.duration.inSeconds);
    final totalMeters = timed.fold<double>(0, (a, l) => a + l.distanceMeters!);
    if (totalMeters <= 0) return null;
    return Duration(seconds: ((totalSeconds / totalMeters) * 1000).round());
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': kPluginSchemaVersion,
    'planId': planId,
    'planName': planName,
    'discipline': discipline.id,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'duration': duration.inSeconds,
    'laps': laps.map((l) => l.toJson()).toList(),
    if (meta != null) 'meta': meta,
  };

  factory CardioResult.fromJson(Map<String, dynamic> json) => CardioResult(
    planId: json['planId'] as String,
    planName: json['planName'] as String? ?? '',
    discipline: CardioDisciplineSerializer.fromId(
      json['discipline'] as String? ?? 'mixed',
    ),
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: DateTime.parse(json['finishedAt'] as String),
    duration: Duration(seconds: (json['duration'] as num).toInt()),
    laps:
        (json['laps'] as List<dynamic>)
            .map((l) => CardioLap.fromJson(l as Map<String, dynamic>))
            .toList(),
    meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
  );

  /// Flat per-lap CSV. Columns:
  ///
  ///     planId, planName, discipline, lapIndex, intervalIndex,
  ///     durationSec, distanceMeters, avgPaceSecPerKm, avgHeartRate,
  ///     rpe, completedAt
  ///
  /// `\n` line terminators. Header row included by default.
  String toCsv({bool includeHeader = true}) {
    final buf = StringBuffer();
    if (includeHeader) {
      buf.writeln(
        csvRow(const [
          'planId',
          'planName',
          'discipline',
          'lapIndex',
          'intervalIndex',
          'durationSec',
          'distanceMeters',
          'avgPaceSecPerKm',
          'avgHeartRate',
          'rpe',
          'completedAt',
        ]),
      );
    }
    for (var i = 0; i < laps.length; i++) {
      final l = laps[i];
      buf.writeln(
        csvRow([
          planId,
          planName,
          discipline.id,
          i,
          l.intervalIndex,
          l.duration.inSeconds,
          l.distanceMeters,
          l.avgPacePerKm?.inSeconds,
          l.avgHeartRate,
          l.rpe,
          l.completedAt.toIso8601String(),
        ]),
      );
    }
    return buf.toString();
  }
}
