import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../exercise_category.dart';
import 'cardio_interval.dart';

/// How the cardio session is structured. Mostly informational — drives UI
/// hints, not runtime behaviour.
enum CardioDiscipline {
  running,
  cycling,
  rowing,
  swimming,
  jumpRope,
  walk,
  mixed,
}

extension CardioDisciplineSerializer on CardioDiscipline {
  String get id => name;

  static CardioDiscipline fromId(String raw) => CardioDiscipline.values
      .firstWhere((d) => d.name == raw, orElse: () => CardioDiscipline.mixed);
}

/// A cardio session described as an ordered list of [CardioInterval]s.
///
/// Plays the same role as `WorkoutPlan` for the strength side, but the unit
/// of progress is the interval (= lap), not the rep×set.
@immutable
class CardioPlan {
  final String id;
  final String name;
  final String? description;
  final CardioDiscipline discipline;
  final ExerciseCategory? category;
  final List<CardioInterval> intervals;
  final Map<String, dynamic>? meta;

  const CardioPlan({
    required this.id,
    required this.name,
    required this.intervals,
    this.description,
    this.discipline = CardioDiscipline.mixed,
    this.category,
    this.meta,
  });

  /// Sum of all interval target durations (skipping open-ended intervals).
  Duration get plannedDuration => intervals.fold(
    Duration.zero,
    (acc, i) => acc + (i.targetDuration ?? Duration.zero),
  );

  /// Sum of all interval target distances in meters (skipping unset).
  double get plannedDistanceMeters =>
      intervals.fold(0.0, (acc, i) => acc + (i.targetDistanceMeters ?? 0));

  CardioPlan copyWith({
    String? id,
    String? name,
    String? description,
    CardioDiscipline? discipline,
    ExerciseCategory? category,
    List<CardioInterval>? intervals,
    Map<String, dynamic>? meta,
  }) => CardioPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    discipline: discipline ?? this.discipline,
    category: category ?? this.category,
    intervals: intervals ?? this.intervals,
    meta: meta ?? this.meta,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'discipline': discipline.id,
    if (category != null) 'category': category!.toJson(),
    'intervals': intervals.map((i) => i.toJson()).toList(),
    if (meta != null) 'meta': meta,
  };

  factory CardioPlan.fromJson(Map<String, dynamic> json) => CardioPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    discipline: CardioDisciplineSerializer.fromId(
      json['discipline'] as String? ?? 'mixed',
    ),
    category:
        json['category'] == null
            ? null
            : ExerciseCategory.fromJson(
              json['category'] as Map<String, dynamic>,
            ),
    intervals:
        (json['intervals'] as List<dynamic>)
            .map((i) => CardioInterval.fromJson(i as Map<String, dynamic>))
            .toList(),
    meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
  );

  String toJsonString() => jsonEncode(toJson());
  factory CardioPlan.fromJsonString(String s) =>
      CardioPlan.fromJson(jsonDecode(s) as Map<String, dynamic>);

  CardioPlan cloneWithId(String newId) => copyWith(id: newId);

  /// One-line summary suited for plan picker cards. Localise it yourself if
  /// needed.
  String get previewSummary {
    final minutes = plannedDuration.inMinutes;
    final minutesPart = minutes <= 0 ? '<1 min' : '~$minutes min';
    final distanceKm = plannedDistanceMeters / 1000;
    final distancePart = distanceKm > 0
        ? ' • ${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km'
        : '';
    return '${intervals.length} '
        '${intervals.length == 1 ? 'interval' : 'intervals'} '
        '• $minutesPart$distancePart';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardioPlan && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
