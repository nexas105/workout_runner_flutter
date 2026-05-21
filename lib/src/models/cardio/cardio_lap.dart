import 'package:flutter/foundation.dart';

/// A completed interval as actually executed by the user. Counterpart of
/// `PerformedSet` on the strength side.
@immutable
class CardioLap {
  /// Index in [CardioPlan.intervals] this lap was based on.
  final int intervalIndex;

  /// Wall-clock duration actually spent on the interval.
  final Duration duration;

  /// Actual distance covered, in meters. `null` when not measured.
  final double? distanceMeters;

  /// Average heart rate during the interval, if known.
  final int? avgHeartRate;

  /// Average pace in seconds-per-km (computed from duration/distance when both
  /// are present, but consumers can override).
  final Duration? avgPacePerKm;

  /// Free-form perceived effort (0..10 RPE).
  final int? rpe;

  /// When the lap was completed (wall clock).
  final DateTime completedAt;

  /// MET snapshot from the originating [CardioInterval] at finish time. Used
  /// by [CardioResult.kcal] when computing energy expenditure. `null` falls
  /// back to the discipline default.
  final double? met;

  const CardioLap({
    required this.intervalIndex,
    required this.duration,
    this.distanceMeters,
    this.avgHeartRate,
    this.avgPacePerKm,
    this.rpe,
    required this.completedAt,
    this.met,
  });

  /// Convenience constructor that derives [avgPacePerKm] from duration+distance
  /// when both are present.
  factory CardioLap.computed({
    required int intervalIndex,
    required Duration duration,
    double? distanceMeters,
    int? avgHeartRate,
    int? rpe,
    DateTime? completedAt,
    double? met,
  }) {
    Duration? pace;
    if (distanceMeters != null &&
        distanceMeters > 0 &&
        duration.inSeconds > 0) {
      final secondsPerMeter = duration.inSeconds / distanceMeters;
      pace = Duration(seconds: (secondsPerMeter * 1000).round());
    }
    return CardioLap(
      intervalIndex: intervalIndex,
      duration: duration,
      distanceMeters: distanceMeters,
      avgHeartRate: avgHeartRate,
      avgPacePerKm: pace,
      rpe: rpe,
      completedAt: completedAt ?? DateTime.now(),
      met: met,
    );
  }

  CardioLap copyWith({
    int? intervalIndex,
    Duration? duration,
    double? distanceMeters,
    int? avgHeartRate,
    Duration? avgPacePerKm,
    int? rpe,
    DateTime? completedAt,
    double? met,
  }) => CardioLap(
    intervalIndex: intervalIndex ?? this.intervalIndex,
    duration: duration ?? this.duration,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    avgHeartRate: avgHeartRate ?? this.avgHeartRate,
    avgPacePerKm: avgPacePerKm ?? this.avgPacePerKm,
    rpe: rpe ?? this.rpe,
    completedAt: completedAt ?? this.completedAt,
    met: met ?? this.met,
  );

  Map<String, dynamic> toJson() => {
    'intervalIndex': intervalIndex,
    'duration': duration.inSeconds,
    if (distanceMeters != null) 'distanceMeters': distanceMeters,
    if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
    if (avgPacePerKm != null) 'avgPacePerKm': avgPacePerKm!.inSeconds,
    if (rpe != null) 'rpe': rpe,
    'completedAt': completedAt.toIso8601String(),
    if (met != null) 'met': met,
  };

  factory CardioLap.fromJson(Map<String, dynamic> json) => CardioLap(
    intervalIndex: (json['intervalIndex'] as num).toInt(),
    duration: Duration(seconds: (json['duration'] as num).toInt()),
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    avgHeartRate: (json['avgHeartRate'] as num?)?.toInt(),
    avgPacePerKm:
        json['avgPacePerKm'] == null
            ? null
            : Duration(seconds: (json['avgPacePerKm'] as num).toInt()),
    rpe: (json['rpe'] as num?)?.toInt(),
    completedAt: DateTime.parse(json['completedAt'] as String),
    met: (json['met'] as num?)?.toDouble(),
  );
}
