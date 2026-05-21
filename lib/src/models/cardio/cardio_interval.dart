import 'package:flutter/foundation.dart';

/// What the user is supposed to be doing during a [CardioInterval].
///
/// * [warmup] — easy effort to start the session.
/// * [work] — the "hard" segment (a sprint, a fast km, a high-cadence push).
/// * [rest] — active or passive recovery between work bouts.
/// * [steady] — continuous moderate effort (a steady 5 km run).
/// * [cooldown] — easy effort at the end of the session.
enum CardioPhase { warmup, work, rest, steady, cooldown }

extension CardioPhaseSerializer on CardioPhase {
  String get id => name;

  static CardioPhase fromId(String raw) => CardioPhase.values.firstWhere(
    (p) => p.name == raw,
    orElse: () => CardioPhase.work,
  );
}

/// A single segment inside a [CardioPlan]. Either bounded by [targetDuration],
/// by [targetDistance], or both — the runner only auto-advances when the
/// bounded dimension hits its target. Free-form steady-state intervals can
/// leave both `null` and rely on the user pressing "next".
@immutable
class CardioInterval {
  /// Stable identifier — useful when matching laps back to the plan.
  final String id;

  /// Human label shown in UIs (e.g. "Sprint", "Easy jog").
  final String name;

  final CardioPhase phase;

  /// Target duration in seconds. `null` for open-ended intervals.
  final Duration? targetDuration;

  /// Target distance in meters. `null` when distance is not the bounding axis.
  final double? targetDistanceMeters;

  /// Optional intensity hint (0..10 RPE, %HRmax, or just a label like "Z3").
  final String? intensity;

  /// Optional pace target (seconds per km). Useful for running plans.
  final Duration? targetPacePerKm;

  /// Optional extra notes, e.g. "stay seated", "nasal breathing only".
  final String? notes;

  final Map<String, dynamic>? meta;

  /// Metabolic Equivalent of Task. When `null`, the cardio discipline's
  /// default is used by `CardioResult.kcal()`.
  final double? met;

  const CardioInterval({
    required this.id,
    required this.name,
    this.phase = CardioPhase.work,
    this.targetDuration,
    this.targetDistanceMeters,
    this.intensity,
    this.targetPacePerKm,
    this.notes,
    this.meta,
    this.met,
  });

  /// True when the runner can decide on its own when the interval is finished
  /// (either a duration or a distance bound is set).
  bool get isAutoAdvancing =>
      targetDuration != null || targetDistanceMeters != null;

  CardioInterval copyWith({
    String? id,
    String? name,
    CardioPhase? phase,
    Duration? targetDuration,
    double? targetDistanceMeters,
    String? intensity,
    Duration? targetPacePerKm,
    String? notes,
    Map<String, dynamic>? meta,
    double? met,
  }) => CardioInterval(
    id: id ?? this.id,
    name: name ?? this.name,
    phase: phase ?? this.phase,
    targetDuration: targetDuration ?? this.targetDuration,
    targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
    intensity: intensity ?? this.intensity,
    targetPacePerKm: targetPacePerKm ?? this.targetPacePerKm,
    notes: notes ?? this.notes,
    meta: meta ?? this.meta,
    met: met ?? this.met,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phase': phase.id,
    if (targetDuration != null) 'targetDuration': targetDuration!.inSeconds,
    if (targetDistanceMeters != null)
      'targetDistanceMeters': targetDistanceMeters,
    if (intensity != null) 'intensity': intensity,
    if (targetPacePerKm != null) 'targetPacePerKm': targetPacePerKm!.inSeconds,
    if (notes != null) 'notes': notes,
    if (meta != null) 'meta': meta,
    if (met != null) 'met': met,
  };

  factory CardioInterval.fromJson(Map<String, dynamic> json) => CardioInterval(
    id: json['id'] as String,
    name: json['name'] as String,
    phase: CardioPhaseSerializer.fromId(json['phase'] as String? ?? 'work'),
    targetDuration:
        json['targetDuration'] == null
            ? null
            : Duration(seconds: (json['targetDuration'] as num).toInt()),
    targetDistanceMeters: (json['targetDistanceMeters'] as num?)?.toDouble(),
    intensity: json['intensity'] as String?,
    targetPacePerKm:
        json['targetPacePerKm'] == null
            ? null
            : Duration(seconds: (json['targetPacePerKm'] as num).toInt()),
    notes: json['notes'] as String?,
    meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
    met: (json['met'] as num?)?.toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardioInterval &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
