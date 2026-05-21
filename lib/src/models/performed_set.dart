import 'package:flutter/foundation.dart';

/// A set that has been executed by the user (with actual values).
@immutable
class PerformedSet {
  final int exerciseIndex;
  final int setIndex;
  final int actualReps;
  final double? actualWeight;
  final int? rir;
  final Duration? pause;
  final Duration? duration;
  final DateTime completedAt;

  const PerformedSet({
    required this.exerciseIndex,
    required this.setIndex,
    required this.actualReps,
    this.actualWeight,
    this.rir,
    this.pause,
    this.duration,
    required this.completedAt,
  });

  PerformedSet copyWith({
    int? exerciseIndex,
    int? setIndex,
    int? actualReps,
    double? actualWeight,
    int? rir,
    Duration? pause,
    Duration? duration,
    DateTime? completedAt,
  }) =>
      PerformedSet(
        exerciseIndex: exerciseIndex ?? this.exerciseIndex,
        setIndex: setIndex ?? this.setIndex,
        actualReps: actualReps ?? this.actualReps,
        actualWeight: actualWeight ?? this.actualWeight,
        rir: rir ?? this.rir,
        pause: pause ?? this.pause,
        duration: duration ?? this.duration,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'exerciseIndex': exerciseIndex,
        'setIndex': setIndex,
        'actualReps': actualReps,
        if (actualWeight != null) 'actualWeight': actualWeight,
        if (rir != null) 'rir': rir,
        if (pause != null) 'pause': pause!.inSeconds,
        if (duration != null) 'duration': duration!.inSeconds,
        'completedAt': completedAt.toIso8601String(),
      };

  factory PerformedSet.fromJson(Map<String, dynamic> json) => PerformedSet(
        exerciseIndex: (json['exerciseIndex'] as num).toInt(),
        setIndex: (json['setIndex'] as num).toInt(),
        actualReps: (json['actualReps'] as num).toInt(),
        actualWeight: (json['actualWeight'] as num?)?.toDouble(),
        rir: (json['rir'] as num?)?.toInt(),
        pause: _readDuration(json, 'pause', fallback: 'restTaken'),
        duration: _readDuration(json, 'duration'),
        completedAt: DateTime.parse(json['completedAt'] as String),
      );

  static Duration? _readDuration(
    Map<String, dynamic> json,
    String key, {
    String? fallback,
  }) {
    final raw = json[key] ?? (fallback != null ? json[fallback] : null);
    if (raw == null) return null;
    return Duration(seconds: (raw as num).toInt());
  }
}
