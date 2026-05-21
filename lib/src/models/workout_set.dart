import 'package:flutter/foundation.dart';

@immutable
class WorkoutSet {
  final int targetReps;
  final double? targetWeight;
  final Duration? rest;

  const WorkoutSet({
    required this.targetReps,
    this.targetWeight,
    this.rest,
  });

  WorkoutSet copyWith({int? targetReps, double? targetWeight, Duration? rest}) =>
      WorkoutSet(
        targetReps: targetReps ?? this.targetReps,
        targetWeight: targetWeight ?? this.targetWeight,
        rest: rest ?? this.rest,
      );

  Map<String, dynamic> toJson() => {
        'targetReps': targetReps,
        if (targetWeight != null) 'targetWeight': targetWeight,
        if (rest != null) 'rest': rest!.inSeconds,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        targetReps: json['targetReps'] as int,
        targetWeight: (json['targetWeight'] as num?)?.toDouble(),
        rest: json['rest'] == null
            ? null
            : Duration(seconds: (json['rest'] as num).toInt()),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSet &&
          runtimeType == other.runtimeType &&
          targetReps == other.targetReps &&
          targetWeight == other.targetWeight &&
          rest == other.rest;

  @override
  int get hashCode => Object.hash(targetReps, targetWeight, rest);
}
