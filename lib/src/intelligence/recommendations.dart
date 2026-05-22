import '../models/performed_set.dart';
import '../models/workout_set.dart';

class NextSetSuggestion {
  final int suggestedReps;
  final double? suggestedWeight;
  final int? suggestedRir;
  final String note;
  final double confidence;

  const NextSetSuggestion({
    required this.suggestedReps,
    this.suggestedWeight,
    this.suggestedRir,
    required this.note,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'suggestedReps': suggestedReps,
    if (suggestedWeight != null) 'suggestedWeight': suggestedWeight,
    if (suggestedRir != null) 'suggestedRir': suggestedRir,
    'note': note,
    'confidence': confidence,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NextSetSuggestion &&
          runtimeType == other.runtimeType &&
          suggestedReps == other.suggestedReps &&
          suggestedWeight == other.suggestedWeight &&
          suggestedRir == other.suggestedRir &&
          note == other.note &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(
    suggestedReps,
    suggestedWeight,
    suggestedRir,
    note,
    confidence,
  );
}

class RestSuggestion {
  final Duration duration;
  final String reason;

  const RestSuggestion({required this.duration, required this.reason});

  Map<String, dynamic> toJson() => {
    'duration': duration.inSeconds,
    'reason': reason,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestSuggestion &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(duration, reason);
}

class DeloadSuggestion {
  final double volumeMultiplier;
  final double intensityMultiplier;
  final String reason;

  const DeloadSuggestion({
    required this.volumeMultiplier,
    required this.intensityMultiplier,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'volumeMultiplier': volumeMultiplier,
    'intensityMultiplier': intensityMultiplier,
    'reason': reason,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeloadSuggestion &&
          runtimeType == other.runtimeType &&
          volumeMultiplier == other.volumeMultiplier &&
          intensityMultiplier == other.intensityMultiplier &&
          reason == other.reason;

  @override
  int get hashCode =>
      Object.hash(volumeMultiplier, intensityMultiplier, reason);
}

abstract class Recommendations {
  static const double _weightStepKg = 2.5;
  static const Duration _minRest = Duration(seconds: 30);

  static NextSetSuggestion fromLastSet(
    PerformedSet? last,
    WorkoutSet currentTarget,
  ) {
    if (last == null) {
      return NextSetSuggestion(
        suggestedReps: currentTarget.targetReps,
        suggestedWeight: currentTarget.targetWeight,
        suggestedRir: null,
        note: 'No prior set — using target.',
        confidence: 0.4,
      );
    }

    final metReps = last.actualReps >= currentTarget.targetReps;
    final lastRir = last.rir;
    final baseWeight = last.actualWeight ?? currentTarget.targetWeight;

    if (metReps && lastRir != null && lastRir >= 2) {
      final bumped = baseWeight == null ? null : baseWeight + _weightStepKg;
      return NextSetSuggestion(
        suggestedReps: currentTarget.targetReps,
        suggestedWeight: bumped,
        suggestedRir: lastRir,
        note: 'Bump load: last set met target with RIR ≥ 2.',
        confidence: 0.8,
      );
    }

    if (!metReps) {
      return NextSetSuggestion(
        suggestedReps: currentTarget.targetReps,
        suggestedWeight: baseWeight,
        suggestedRir: lastRir,
        note: 'Hold load: last set missed target reps.',
        confidence: 0.7,
      );
    }

    return NextSetSuggestion(
      suggestedReps: currentTarget.targetReps,
      suggestedWeight: baseWeight,
      suggestedRir: lastRir,
      note: 'Hold load: target met but RIR low.',
      confidence: 0.6,
    );
  }

  static RestSuggestion fromRpe(
    int rir, {
    Duration baseline = const Duration(seconds: 90),
  }) {
    if (rir <= 1) {
      return RestSuggestion(
        duration: baseline + const Duration(seconds: 60),
        reason: 'High effort (RIR ≤ 1) — extended rest.',
      );
    }
    if (rir <= 3) {
      return RestSuggestion(
        duration: baseline,
        reason: 'Moderate effort — baseline rest.',
      );
    }
    final shortened = baseline - const Duration(seconds: 30);
    final clamped = shortened < _minRest ? _minRest : shortened;
    return RestSuggestion(
      duration: clamped,
      reason: 'Low effort (RIR ≥ 4) — shortened rest.',
    );
  }

  static DeloadSuggestion fromFatigue({
    required int consecutiveMissedSets,
    required int weeklyVolumeTrendPct,
  }) {
    final needsDeload = consecutiveMissedSets >= 6 || weeklyVolumeTrendPct > 30;
    if (needsDeload) {
      final reason =
          consecutiveMissedSets >= 6
              ? 'High missed-set count signals accumulated fatigue.'
              : 'Weekly volume spike exceeds 30% — back off to recover.';
      return DeloadSuggestion(
        volumeMultiplier: 0.6,
        intensityMultiplier: 0.85,
        reason: reason,
      );
    }
    return const DeloadSuggestion(
      volumeMultiplier: 1.0,
      intensityMultiplier: 1.0,
      reason: 'No deload needed.',
    );
  }
}
