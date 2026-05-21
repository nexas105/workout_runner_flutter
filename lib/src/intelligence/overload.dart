import 'package:flutter/foundation.dart';

import '../models/performed_set.dart';
import '../models/set_type.dart';
import '../models/workout_result.dart';
import '../models/workout_set.dart';

enum OverloadStrategy { linear, doubleProgression, rpe }

extension OverloadStrategySerializer on OverloadStrategy {
  String get id => name;

  static OverloadStrategy fromId(String? raw) {
    if (raw == null) return OverloadStrategy.linear;
    return OverloadStrategy.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => OverloadStrategy.linear,
    );
  }
}

@immutable
class OverloadSuggestion {
  final double? suggestedWeight;
  final int suggestedReps;
  final String reason;
  final OverloadStrategy strategy;

  const OverloadSuggestion({
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.reason,
    required this.strategy,
  });

  OverloadSuggestion copyWith({
    double? suggestedWeight,
    int? suggestedReps,
    String? reason,
    OverloadStrategy? strategy,
  }) => OverloadSuggestion(
    suggestedWeight: suggestedWeight ?? this.suggestedWeight,
    suggestedReps: suggestedReps ?? this.suggestedReps,
    reason: reason ?? this.reason,
    strategy: strategy ?? this.strategy,
  );

  Map<String, dynamic> toJson() => {
    if (suggestedWeight != null) 'suggestedWeight': suggestedWeight,
    'suggestedReps': suggestedReps,
    'reason': reason,
    'strategy': strategy.id,
  };

  factory OverloadSuggestion.fromJson(Map<String, dynamic> json) =>
      OverloadSuggestion(
        suggestedWeight: (json['suggestedWeight'] as num?)?.toDouble(),
        suggestedReps: (json['suggestedReps'] as num).toInt(),
        reason: json['reason'] as String,
        strategy: OverloadStrategySerializer.fromId(json['strategy'] as String?),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverloadSuggestion &&
          runtimeType == other.runtimeType &&
          suggestedWeight == other.suggestedWeight &&
          suggestedReps == other.suggestedReps &&
          reason == other.reason &&
          strategy == other.strategy;

  @override
  int get hashCode =>
      Object.hash(suggestedWeight, suggestedReps, reason, strategy);
}

class OverloadEngine {
  static OverloadSuggestion? from(
    List<PerformedExerciseDetails> historyForExercise,
    WorkoutSet currentTarget, {
    OverloadStrategy strategy = OverloadStrategy.linear,
    double linearIncrementKg = 2.5,
    int doubleProgressionRepCap = 12,
  }) {
    if (historyForExercise.isEmpty) return null;

    final sessions = [...historyForExercise]..sort(
      (a, b) => _sessionTime(b).compareTo(_sessionTime(a)),
    );

    final lastWorking = sessions.first.sets
        .where((s) => s.type == SetType.working)
        .toList();
    if (lastWorking.isEmpty) return null;

    switch (strategy) {
      case OverloadStrategy.linear:
        return _linear(lastWorking, currentTarget, linearIncrementKg);
      case OverloadStrategy.doubleProgression:
        return _doubleProgression(
          lastWorking,
          currentTarget,
          linearIncrementKg,
          doubleProgressionRepCap,
        );
      case OverloadStrategy.rpe:
        return _rpe(lastWorking, currentTarget, linearIncrementKg);
    }
  }

  static DateTime _sessionTime(PerformedExerciseDetails s) {
    DateTime? latest;
    for (final st in s.sets) {
      if (latest == null || st.completedAt.isAfter(latest)) {
        latest = st.completedAt;
      }
    }
    return latest ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static double _lastWeight(List<PerformedSet> sets, WorkoutSet target) {
    for (final s in sets) {
      if (s.actualWeight != null) return s.actualWeight!;
    }
    return target.targetWeight ?? 0;
  }

  static bool _hitAllTargetReps(List<PerformedSet> sets, int target) =>
      sets.every((s) => s.actualReps >= target);

  static OverloadSuggestion _linear(
    List<PerformedSet> lastWorking,
    WorkoutSet target,
    double increment,
  ) {
    final base = _lastWeight(lastWorking, target);
    if (_hitAllTargetReps(lastWorking, target.targetReps)) {
      return OverloadSuggestion(
        suggestedWeight: target.targetWeight == null ? null : base + increment,
        suggestedReps: target.targetReps,
        reason: 'hit target reps on all sets — bump weight',
        strategy: OverloadStrategy.linear,
      );
    }
    return OverloadSuggestion(
      suggestedWeight: target.targetWeight == null ? null : base,
      suggestedReps: target.targetReps,
      reason: 'missed target reps — repeat weight',
      strategy: OverloadStrategy.linear,
    );
  }

  static OverloadSuggestion _doubleProgression(
    List<PerformedSet> lastWorking,
    WorkoutSet target,
    double increment,
    int repCap,
  ) {
    final base = _lastWeight(lastWorking, target);
    final hit = _hitAllTargetReps(lastWorking, target.targetReps);
    if (!hit) {
      return OverloadSuggestion(
        suggestedWeight: target.targetWeight == null ? null : base,
        suggestedReps: target.targetReps,
        reason: 'missed target reps — repeat',
        strategy: OverloadStrategy.doubleProgression,
      );
    }
    if (target.targetReps >= repCap) {
      return OverloadSuggestion(
        suggestedWeight: target.targetWeight == null ? null : base + increment,
        suggestedReps: _originalRepFloor(repCap),
        reason: 'rep cap reached — bump weight, reset reps',
        strategy: OverloadStrategy.doubleProgression,
      );
    }
    return OverloadSuggestion(
      suggestedWeight: target.targetWeight == null ? null : base,
      suggestedReps: target.targetReps + 1,
      reason: 'hit target reps — add 1 rep',
      strategy: OverloadStrategy.doubleProgression,
    );
  }

  // Conventional double-progression resets to the bottom of a 2-rep band
  // (e.g. cap 12 → restart at 8). Half the cap rounded works well for common
  // 6-10, 8-12, 10-15 schemes without requiring an extra parameter.
  static int _originalRepFloor(int repCap) =>
      (repCap / 2).ceil().clamp(1, repCap - 1);

  static OverloadSuggestion _rpe(
    List<PerformedSet> lastWorking,
    WorkoutSet target,
    double increment,
  ) {
    final base = _lastWeight(lastWorking, target);
    final missed = !_hitAllTargetReps(lastWorking, target.targetReps);
    final anyZero = lastWorking.any((s) => s.rir != null && s.rir == 0);
    final allReady = lastWorking.every((s) => s.rir != null && s.rir! >= 2);

    if (allReady && !missed) {
      return OverloadSuggestion(
        suggestedWeight: target.targetWeight == null ? null : base + increment,
        suggestedReps: target.targetReps,
        reason: 'RIR >= 2 on all sets — bump weight',
        strategy: OverloadStrategy.rpe,
      );
    }
    if (anyZero || missed) {
      return OverloadSuggestion(
        suggestedWeight: target.targetWeight == null ? null : base,
        suggestedReps: target.targetReps,
        reason: missed
            ? 'missed reps — hold weight'
            : 'RIR 0 — hold weight',
        strategy: OverloadStrategy.rpe,
      );
    }
    return OverloadSuggestion(
      suggestedWeight: target.targetWeight == null ? null : base,
      suggestedReps: target.targetReps,
      reason: 'inconclusive RIR — hold weight',
      strategy: OverloadStrategy.rpe,
    );
  }
}
