import 'package:flutter/foundation.dart';

import 'performed_exercise.dart';

/// Persistable snapshot of an active workout. Stored by [RunnerStorage] and
/// reloaded on auto-resume.
@immutable
class WorkoutRunnerState {
  final String planId;
  final int currentExerciseIndex;
  final int? activeExerciseIndex;
  final int currentSetIndex;
  final bool isActive;
  final DateTime startedAt;
  final DateTime updatedAt;
  final List<PerformedExercise> performed;

  const WorkoutRunnerState({
    required this.planId,
    required this.currentExerciseIndex,
    required this.activeExerciseIndex,
    required this.currentSetIndex,
    required this.isActive,
    required this.startedAt,
    required this.updatedAt,
    required this.performed,
  });

  WorkoutRunnerState copyWith({
    int? currentExerciseIndex,
    Object? activeExerciseIndex = _noChange,
    int? currentSetIndex,
    bool? isActive,
    DateTime? updatedAt,
    List<PerformedExercise>? performed,
  }) =>
      WorkoutRunnerState(
        planId: planId,
        currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
        activeExerciseIndex: identical(activeExerciseIndex, _noChange)
            ? this.activeExerciseIndex
            : activeExerciseIndex as int?,
        currentSetIndex: currentSetIndex ?? this.currentSetIndex,
        isActive: isActive ?? this.isActive,
        startedAt: startedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        performed: performed ?? this.performed,
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'currentExerciseIndex': currentExerciseIndex,
        'activeExerciseIndex': activeExerciseIndex,
        'currentSetIndex': currentSetIndex,
        'isActive': isActive,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'performed': performed.map((e) => e.toJson()).toList(),
      };

  factory WorkoutRunnerState.fromJson(Map<String, dynamic> json) =>
      WorkoutRunnerState(
        planId: json['planId'] as String,
        currentExerciseIndex:
            (json['currentExerciseIndex'] as num?)?.toInt() ?? 0,
        activeExerciseIndex: (json['activeExerciseIndex'] as num?)?.toInt(),
        currentSetIndex: (json['currentSetIndex'] as num?)?.toInt() ?? 0,
        isActive: (json['isActive'] as bool?) ?? true,
        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        performed: (json['performed'] as List<dynamic>? ?? const [])
            .map((e) => PerformedExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

const Object _noChange = Object();
