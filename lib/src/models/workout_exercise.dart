import 'package:flutter/foundation.dart';

import 'exercise_category.dart';
import 'exercise_metadata.dart';
import 'muscle.dart';
import 'workout_set.dart';

@immutable
class WorkoutExercise {
  final String id;
  final String name;
  final String? description;
  final ExerciseCategory? category;
  final List<Muscle> muscles;
  final List<WorkoutSet> sets;
  final String? notes;
  final Map<String, dynamic>? meta;

  /// Metabolic Equivalent of Task — used by `WorkoutResult.kcal()` to estimate
  /// energy expenditure. When `null`, the exercise category's default is used,
  /// falling back to a global default if the category is also unknown.
  final double? met;

  /// Primary equipment required to perform this exercise. `null` means
  /// "equipment not modeled" — readers should fall back to `meta['equipment']`
  /// when present for backward compatibility.
  final ExerciseEquipment? equipment;

  /// Coarse-grained movement pattern (push/pull/squat/hinge/...). Used by
  /// substitution and plan-generation helpers.
  final MovementPattern? movementPattern;

  /// Rough difficulty bucket — drives picker filtering.
  final ExerciseDifficulty? difficulty;

  /// True for unilateral moves (split squat, single-arm row, ...).
  final bool unilateral;

  /// Alternative names that should match in search. Always lowercased on
  /// `fromJson` so callers don't need to normalize.
  final List<String> aliases;

  /// Extra search keywords (e.g. "knee dominant", "anti-rotation"). Always
  /// lowercased on `fromJson`.
  final List<String> searchTerms;

  const WorkoutExercise({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.muscles = const [],
    this.sets = const [],
    this.notes,
    this.meta,
    this.met,
    this.equipment,
    this.movementPattern,
    this.difficulty,
    this.unilateral = false,
    this.aliases = const [],
    this.searchTerms = const [],
  });

  WorkoutExercise copyWith({
    String? id,
    String? name,
    String? description,
    ExerciseCategory? category,
    List<Muscle>? muscles,
    List<WorkoutSet>? sets,
    String? notes,
    Map<String, dynamic>? meta,
    double? met,
    ExerciseEquipment? equipment,
    MovementPattern? movementPattern,
    ExerciseDifficulty? difficulty,
    bool? unilateral,
    List<String>? aliases,
    List<String>? searchTerms,
  }) => WorkoutExercise(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    muscles: muscles ?? this.muscles,
    sets: sets ?? this.sets,
    notes: notes ?? this.notes,
    meta: meta ?? this.meta,
    met: met ?? this.met,
    equipment: equipment ?? this.equipment,
    movementPattern: movementPattern ?? this.movementPattern,
    difficulty: difficulty ?? this.difficulty,
    unilateral: unilateral ?? this.unilateral,
    aliases: aliases ?? this.aliases,
    searchTerms: searchTerms ?? this.searchTerms,
  );

  /// Returns a copy with a fresh [id]. Useful when forking a catalog exercise
  /// into a user-owned variant.
  WorkoutExercise cloneWithId(String newId) => copyWith(id: newId);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (category != null) 'category': category!.toJson(),
    'muscles': muscles.map((m) => m.toJson()).toList(),
    'sets': sets.map((s) => s.toJson()).toList(),
    if (notes != null) 'notes': notes,
    if (meta != null) 'meta': meta,
    if (met != null) 'met': met,
    if (equipment != null) 'equipment': equipment!.id,
    if (movementPattern != null) 'movementPattern': movementPattern!.id,
    if (difficulty != null) 'difficulty': difficulty!.id,
    if (unilateral) 'unilateral': true,
    if (aliases.isNotEmpty) 'aliases': aliases,
    if (searchTerms.isNotEmpty) 'searchTerms': searchTerms,
  };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>();
    // Backward-compat: read first-class fields, then fall back to meta entries
    // (Phase 4.5/5.5.18 readers had been parking equipment/movementPattern
    // strings in meta before this phase made them first-class).
    final equipmentId =
        json['equipment'] as String? ?? meta?['equipment'] as String?;
    final movementId =
        json['movementPattern'] as String? ??
        meta?['movementPattern'] as String?;
    final difficultyId =
        json['difficulty'] as String? ?? meta?['difficulty'] as String?;
    final aliasesRaw =
        json['aliases'] as List<dynamic>? ?? meta?['aliases'] as List<dynamic>?;
    final searchRaw = json['searchTerms'] as List<dynamic>?;
    return WorkoutExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category:
          json['category'] == null
              ? null
              : ExerciseCategory.fromJson(
                json['category'] as Map<String, dynamic>,
              ),
      muscles:
          (json['muscles'] as List<dynamic>? ?? const [])
              .map((m) => Muscle.fromJson(m as Map<String, dynamic>))
              .toList(),
      sets:
          (json['sets'] as List<dynamic>? ?? const [])
              .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
              .toList(),
      notes: json['notes'] as String?,
      meta: meta,
      met: (json['met'] as num?)?.toDouble(),
      equipment:
          equipmentId == null ? null : ExerciseEquipmentId.fromId(equipmentId),
      movementPattern: MovementPatternId.fromId(movementId),
      difficulty: ExerciseDifficultyId.fromId(difficultyId),
      unilateral: json['unilateral'] as bool? ?? false,
      aliases: (aliasesRaw ?? const [])
          .whereType<String>()
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList(growable: false),
      searchTerms: (searchRaw ?? const [])
          .whereType<String>()
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExercise &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
