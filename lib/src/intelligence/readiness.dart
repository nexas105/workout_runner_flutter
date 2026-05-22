import '../models/performed_set.dart';
import '../models/workout_result.dart';

/// Coarse readiness bucket derived from training history.
///
/// This is a **training heuristic**, not medical or diagnostic advice. The
/// signal is intended to inform volume/intensity choices for the next session
/// — never to gate recovery or substitute for clinical judgement.
enum ReadinessLevel {
  /// Recent load is low or trending down with clean execution — room to push.
  fresh,

  /// Stable load and execution — proceed as planned.
  ready,

  /// Mild fatigue markers — consider trimming volume slightly.
  cautious,

  /// Multiple fatigue markers stacked — back off this session.
  fatigued,
}

/// Snapshot of training readiness derived from recent [WorkoutResult]s and
/// optional self-reported signals (RPE, sleep).
///
/// This is a heuristic for training auto-regulation, **not** a medical or
/// diagnostic readout. Consumers should surface the multipliers as
/// suggestions, not commands. See [Readiness.fromHistory] for how the score
/// is composed. Cross-link: pair with `DeloadSuggestion` (Phase 4.4) when a
/// stronger back-off is warranted.
class TrainingReadiness {
  /// Bucketed readiness level derived from [score].
  final ReadinessLevel level;

  /// Composite score in `0.0..1.0` where higher = fresher.
  final double score;

  /// Short, user-facing rationale (no medical claims).
  final String reason;

  /// Suggested volume multiplier in `0.6..1.1` for the next session.
  final double suggestedVolumeMultiplier;

  /// Suggested intensity multiplier in `0.85..1.05` for the next session.
  final double suggestedIntensityMultiplier;

  const TrainingReadiness({
    required this.level,
    required this.score,
    required this.reason,
    required this.suggestedVolumeMultiplier,
    required this.suggestedIntensityMultiplier,
  });

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'score': score,
    'reason': reason,
    'suggestedVolumeMultiplier': suggestedVolumeMultiplier,
    'suggestedIntensityMultiplier': suggestedIntensityMultiplier,
  };

  factory TrainingReadiness.fromJson(Map<String, dynamic> json) =>
      TrainingReadiness(
        level: ReadinessLevel.values.firstWhere(
          (l) => l.name == json['level'] as String,
          orElse: () => ReadinessLevel.ready,
        ),
        score: (json['score'] as num).toDouble(),
        reason: json['reason'] as String,
        suggestedVolumeMultiplier:
            (json['suggestedVolumeMultiplier'] as num).toDouble(),
        suggestedIntensityMultiplier:
            (json['suggestedIntensityMultiplier'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingReadiness &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          score == other.score &&
          reason == other.reason &&
          suggestedVolumeMultiplier == other.suggestedVolumeMultiplier &&
          suggestedIntensityMultiplier == other.suggestedIntensityMultiplier;

  @override
  int get hashCode => Object.hash(
    level,
    score,
    reason,
    suggestedVolumeMultiplier,
    suggestedIntensityMultiplier,
  );
}

/// Single-number volume adjustment derived from a [TrainingReadiness] bucket.
///
/// Heuristic only — meant to scale planned set counts (or per-exercise volume)
/// for the next session. Not medical guidance.
class VolumeAdjustment {
  /// Multiplier in `0.6..1.1` to apply to planned volume.
  final double multiplier;

  /// Short rationale aligned with the source readiness level.
  final String reason;

  const VolumeAdjustment({required this.multiplier, required this.reason});

  Map<String, dynamic> toJson() => {'multiplier': multiplier, 'reason': reason};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumeAdjustment &&
          runtimeType == other.runtimeType &&
          multiplier == other.multiplier &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(multiplier, reason);
}

/// Pure helpers that derive [TrainingReadiness] and [VolumeAdjustment] from
/// recent [WorkoutResult]s plus optional self-reported signals.
///
/// **Heuristic only — not medical advice.** The score blends:
///
/// * Volume trend (recent 7d vs prior 7d, capped at ±50%)
/// * Missed-rep ratio (per-exercise reps falling well below the window median)
/// * Optional self-reported RPE (1..10)
/// * Optional sleep hours (<6h nudges the score down)
///
/// Output multipliers are bounded so even worst-case suggestions stay in a
/// sane training range.
abstract class Readiness {
  /// Default look-back window for history-derived signals.
  static const Duration _defaultWindow = Duration(days: 14);

  /// Half-window split — last 7 days vs prior 7 days.
  static const Duration _half = Duration(days: 7);

  /// Baseline score for a "ready" state with no strong signals either way.
  static const double _baseline = 0.75;

  /// Hard cap on the volume-trend signal contribution (50% swing → ±0.20).
  static const double _trendCap = 0.50;

  /// Sleep cutoffs.
  static const double _sleepLowCutoff = 6.0;
  static const double _sleepCriticalCutoff = 4.0;

  /// Reps must fall below `_missThreshold * exerciseMedian` to count as a miss.
  static const double _missThreshold = 0.8;

  /// Compute training readiness from recent results plus optional signals.
  ///
  /// * [recent] — recent [WorkoutResult]s; order does not matter. Sessions
  ///   outside `[now - window, now]` are ignored.
  /// * [window] — total look-back. The implementation splits it in halves to
  ///   compare recent vs prior week.
  /// * [selfReportedRpe] — optional 1..10 RPE for today (10 = max effort).
  ///   Values are clamped.
  /// * [sleepHours] — optional last-night sleep hours. <6 nudges down, <4
  ///   nudges down harder.
  /// * [now] — injectable clock for tests.
  ///
  /// **Heuristic — not medical advice.** Empty input returns a neutral
  /// `ReadinessLevel.ready` snapshot.
  static TrainingReadiness fromHistory(
    List<WorkoutResult> recent, {
    Duration window = _defaultWindow,
    double? selfReportedRpe,
    double? sleepHours,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final windowStart = clock.subtract(window);
    final midpoint = clock.subtract(_half);

    final filtered = recent
        .where(
          (r) =>
              !r.finishedAt.isBefore(windowStart) &&
              !r.finishedAt.isAfter(clock),
        )
        .toList(growable: false);

    var score = _baseline;
    final reasons = <String>[];

    // --- Volume trend (recent week vs prior week) --------------------------
    if (filtered.isNotEmpty) {
      var recentVolume = 0.0;
      var priorVolume = 0.0;
      for (final r in filtered) {
        if (r.finishedAt.isAfter(midpoint)) {
          recentVolume += r.totalVolume;
        } else {
          priorVolume += r.totalVolume;
        }
      }

      if (priorVolume > 0) {
        var trend = (recentVolume - priorVolume) / priorVolume;
        if (trend > _trendCap) trend = _trendCap;
        if (trend < -_trendCap) trend = -_trendCap;
        // Asymmetric mapping: a spike signals accumulated fatigue (penalty);
        // a *mild* drop reads as managed deload (small bonus); a *deep* drop
        // reads as missed/aborted sessions (penalty).
        double delta;
        if (trend >= 0) {
          delta = -0.40 * trend;
          if (trend > 0.25) reasons.add('Volume spike vs prior week.');
        } else if (trend > -0.30) {
          delta = -0.20 * trend; // negative trend → small positive delta.
          if (trend < -0.10) reasons.add('Volume eased vs prior week.');
        } else {
          // Sharp drop (>30%): treat as fatigue/missed sessions.
          delta = 0.30 * trend; // negative delta.
          reasons.add('Sharp drop in weekly volume.');
        }
        score += delta;
      } else if (recentVolume > 0) {
        // First-time training inside the window — no comparison baseline,
        // leave score untouched.
      }

      // --- Missed-rep ratio ------------------------------------------------
      final missRatio = _missedRepRatio(filtered);
      if (missRatio > 0) {
        // missRatio 0..1 → up to -0.30 score delta.
        score -= 0.30 * missRatio;
        if (missRatio >= 0.25) {
          reasons.add('Many sets fell short of typical reps.');
        }
      }
    }

    // --- Self-reported RPE -------------------------------------------------
    if (selfReportedRpe != null) {
      var rpe = selfReportedRpe;
      if (rpe < 1) rpe = 1;
      if (rpe > 10) rpe = 10;
      // RPE 5 → 0 delta; RPE 10 → -0.25; RPE 1 → +0.10.
      final delta = rpe >= 5 ? -0.05 * (rpe - 5) : 0.025 * (5 - rpe);
      score += delta;
      if (rpe >= 8) {
        reasons.add('High self-reported effort.');
      } else if (rpe <= 3) {
        reasons.add('Low self-reported effort.');
      }
    }

    // --- Sleep -------------------------------------------------------------
    if (sleepHours != null) {
      if (sleepHours < _sleepCriticalCutoff) {
        score -= 0.20;
        reasons.add('Very short sleep last night.');
      } else if (sleepHours < _sleepLowCutoff) {
        score -= 0.10;
        reasons.add('Short sleep last night.');
      }
    }

    if (score < 0) score = 0;
    if (score > 1) score = 1;

    final level = _levelForScore(score);
    final multipliers = _multipliersForLevel(level);
    final reason =
        reasons.isEmpty
            ? _defaultReasonForLevel(level, filtered.isEmpty)
            : reasons.join(' ');

    return TrainingReadiness(
      level: level,
      score: score,
      reason: reason,
      suggestedVolumeMultiplier: multipliers[0],
      suggestedIntensityMultiplier: multipliers[1],
    );
  }

  /// Translate a [TrainingReadiness] into a single volume multiplier.
  ///
  /// Heuristic only — wraps the readiness bucket's volume multiplier with a
  /// short rationale so callers can scale planned sets without re-deriving
  /// the mapping.
  static VolumeAdjustment adjust(TrainingReadiness readiness) {
    switch (readiness.level) {
      case ReadinessLevel.fresh:
        return const VolumeAdjustment(
          multiplier: 1.05,
          reason: 'Fresh — small volume bump.',
        );
      case ReadinessLevel.ready:
        return const VolumeAdjustment(
          multiplier: 1.0,
          reason: 'Ready — hold planned volume.',
        );
      case ReadinessLevel.cautious:
        return const VolumeAdjustment(
          multiplier: 0.85,
          reason: 'Cautious — trim volume slightly.',
        );
      case ReadinessLevel.fatigued:
        return const VolumeAdjustment(
          multiplier: 0.6,
          reason: 'Fatigued — back off this session.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static ReadinessLevel _levelForScore(double score) {
    if (score >= 0.85) return ReadinessLevel.fresh;
    if (score >= 0.65) return ReadinessLevel.ready;
    if (score >= 0.40) return ReadinessLevel.cautious;
    return ReadinessLevel.fatigued;
  }

  /// `[volume, intensity]`.
  static List<double> _multipliersForLevel(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.fresh:
        return const [1.05, 1.0];
      case ReadinessLevel.ready:
        return const [1.0, 1.0];
      case ReadinessLevel.cautious:
        return const [0.85, 0.95];
      case ReadinessLevel.fatigued:
        return const [0.6, 0.85];
    }
  }

  static String _defaultReasonForLevel(ReadinessLevel level, bool noHistory) {
    if (noHistory) return 'No recent history — assuming ready.';
    switch (level) {
      case ReadinessLevel.fresh:
        return 'Signals look fresh.';
      case ReadinessLevel.ready:
        return 'Signals look steady.';
      case ReadinessLevel.cautious:
        return 'Some fatigue markers.';
      case ReadinessLevel.fatigued:
        return 'Multiple fatigue markers.';
    }
  }

  /// Ratio of working-style sets where `actualReps` fell well below the
  /// window-wide median reps for that exercise.
  ///
  /// Returns 0 when there are too few comparable sets to draw a baseline.
  static double _missedRepRatio(List<WorkoutResult> results) {
    // Bucket reps per exerciseId across all results in window.
    final perExercise = <String, List<int>>{};
    for (final r in results) {
      for (final ex in r.exercises) {
        final list = perExercise.putIfAbsent(ex.exerciseId, () => <int>[]);
        for (final s in ex.sets) {
          list.add(s.actualReps);
        }
      }
    }

    var total = 0;
    var misses = 0;
    perExercise.forEach((_, repsList) {
      if (repsList.length < 2) return; // need a baseline.
      final sorted = [...repsList]..sort();
      final mid = sorted.length ~/ 2;
      final median =
          sorted.length.isOdd
              ? sorted[mid].toDouble()
              : (sorted[mid - 1] + sorted[mid]) / 2.0;
      if (median <= 0) return;
      final threshold = median * _missThreshold;
      for (final reps in repsList) {
        total += 1;
        if (reps < threshold) misses += 1;
      }
    });

    if (total == 0) return 0;
    return misses / total;
  }

  // Internals reference [PerformedSet] indirectly via [WorkoutResult].
  // Exposed for symmetry should consumers want to extend the helper.
  // ignore: unused_element
  static int _repsOf(PerformedSet s) => s.actualReps;
}
