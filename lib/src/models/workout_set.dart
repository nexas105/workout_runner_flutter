import 'package:flutter/foundation.dart';

import 'set_type.dart';

@immutable
class WorkoutSet {
  final int targetReps;
  final double? targetWeight;
  final Duration? rest;
  final SetType type;

  /// Bounding duration for [SetType.amrap] / [SetType.timed] sets. The runner
  /// exposes this through `currentSetTargetDuration` so timer-based UIs can
  /// show a countdown. Other set types ignore it.
  final Duration? targetDuration;

  const WorkoutSet({
    required this.targetReps,
    this.targetWeight,
    this.rest,
    this.type = SetType.working,
    this.targetDuration,
  });

  bool get isTimed =>
      type == SetType.amrap || type == SetType.timed || targetDuration != null;

  WorkoutSet copyWith({
    int? targetReps,
    double? targetWeight,
    Duration? rest,
    SetType? type,
    Duration? targetDuration,
  }) => WorkoutSet(
    targetReps: targetReps ?? this.targetReps,
    targetWeight: targetWeight ?? this.targetWeight,
    rest: rest ?? this.rest,
    type: type ?? this.type,
    targetDuration: targetDuration ?? this.targetDuration,
  );

  Map<String, dynamic> toJson() => {
    'targetReps': targetReps,
    if (targetWeight != null) 'targetWeight': targetWeight,
    if (rest != null) 'rest': rest!.inSeconds,
    if (type != SetType.working) 'type': type.id,
    if (targetDuration != null) 'targetDuration': targetDuration!.inSeconds,
  };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    targetReps: json['targetReps'] as int,
    targetWeight: (json['targetWeight'] as num?)?.toDouble(),
    rest:
        json['rest'] == null
            ? null
            : Duration(seconds: (json['rest'] as num).toInt()),
    type: SetTypeSerializer.fromId(json['type'] as String?),
    targetDuration:
        json['targetDuration'] == null
            ? null
            : Duration(seconds: (json['targetDuration'] as num).toInt()),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSet &&
          runtimeType == other.runtimeType &&
          targetReps == other.targetReps &&
          targetWeight == other.targetWeight &&
          rest == other.rest &&
          type == other.type &&
          targetDuration == other.targetDuration;

  @override
  int get hashCode =>
      Object.hash(targetReps, targetWeight, rest, type, targetDuration);
}
