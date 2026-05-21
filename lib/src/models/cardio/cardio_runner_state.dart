import 'package:flutter/foundation.dart';

import '../../internal/schema.dart';
import 'cardio_lap.dart';

/// Persistable snapshot of an active cardio session. Mirrors
/// `WorkoutRunnerState` on the strength side.
@immutable
class CardioRunnerState {
  final String planId;
  final int currentIntervalIndex;

  /// `true` while the interval ticker is running. `false` while paused.
  final bool isActive;

  /// Wall-clock start of the whole session.
  final DateTime startedAt;

  /// Last time the snapshot was persisted.
  final DateTime updatedAt;

  /// Snapshot of total elapsed work-time at [updatedAt]. Used to restore the
  /// global timer after auto-resume without counting paused intervals twice.
  final Duration elapsed;

  /// Snapshot of time spent inside the current interval at [updatedAt]. Lets
  /// auto-resume continue the interval ticker where it left off instead of
  /// jumping back to zero.
  final Duration intervalElapsed;

  final List<CardioLap> laps;

  const CardioRunnerState({
    required this.planId,
    required this.currentIntervalIndex,
    required this.isActive,
    required this.startedAt,
    required this.updatedAt,
    required this.elapsed,
    required this.intervalElapsed,
    required this.laps,
  });

  CardioRunnerState copyWith({
    int? currentIntervalIndex,
    bool? isActive,
    DateTime? updatedAt,
    Duration? elapsed,
    Duration? intervalElapsed,
    List<CardioLap>? laps,
  }) => CardioRunnerState(
    planId: planId,
    currentIntervalIndex: currentIntervalIndex ?? this.currentIntervalIndex,
    isActive: isActive ?? this.isActive,
    startedAt: startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    elapsed: elapsed ?? this.elapsed,
    intervalElapsed: intervalElapsed ?? this.intervalElapsed,
    laps: laps ?? this.laps,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': kPluginSchemaVersion,
    'planId': planId,
    'currentIntervalIndex': currentIntervalIndex,
    'isActive': isActive,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'elapsed': elapsed.inSeconds,
    'intervalElapsed': intervalElapsed.inSeconds,
    'laps': laps.map((l) => l.toJson()).toList(),
  };

  factory CardioRunnerState.fromJson(Map<String, dynamic> json) =>
      CardioRunnerState(
        planId: json['planId'] as String,
        currentIntervalIndex:
            (json['currentIntervalIndex'] as num?)?.toInt() ?? 0,
        isActive: (json['isActive'] as bool?) ?? true,
        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        elapsed: Duration(seconds: (json['elapsed'] as num?)?.toInt() ?? 0),
        intervalElapsed: Duration(
          seconds: (json['intervalElapsed'] as num?)?.toInt() ?? 0,
        ),
        laps:
            (json['laps'] as List<dynamic>? ?? const [])
                .map((l) => CardioLap.fromJson(l as Map<String, dynamic>))
                .toList(),
      );
}
