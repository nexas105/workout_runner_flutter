import 'package:flutter/foundation.dart';

/// A grouping of exercises performed back-to-back as a superset or circuit.
///
/// The runner already works on a flat `exercises` list — blocks are *metadata*
/// layered on top, telling UI (and the rest helper) that exercises at
/// [exerciseIndices] belong together for [rounds] rounds with [restBetween]
/// between exercises and [restAfterBlock] once the whole block is done.
///
/// Blocks DO NOT duplicate the exercises themselves. They reference existing
/// `WorkoutPlan.exercises` by index, keeping the plan's flat structure intact
/// for the runner that doesn't (yet) understand blocks natively.
@immutable
class WorkoutBlock {
  /// Stable id for the block — used by editors and result snapshots.
  final String id;

  /// Optional label shown in UIs (e.g. "Chest Superset", "Finisher Circuit").
  final String name;

  /// Indices into the plan's flat `exercises` list. Order matters: that's
  /// the order each round walks through.
  final List<int> exerciseIndices;

  /// How many times to loop the block. `1` = a regular pairing, `≥2` = a
  /// circuit.
  final int rounds;

  /// Rest between exercises *within* a round. `null` falls back to each
  /// exercise's own set-level rest (legacy behaviour).
  final Duration? restBetween;

  /// Rest after finishing all rounds of the block. `null` means the runner
  /// uses the last set's regular rest.
  final Duration? restAfterBlock;

  /// Free-form metadata for editor / app extensions.
  final Map<String, dynamic>? meta;

  const WorkoutBlock({
    required this.id,
    required this.exerciseIndices,
    this.name = '',
    this.rounds = 1,
    this.restBetween,
    this.restAfterBlock,
    this.meta,
  });

  bool get isSuperset => rounds == 1 && exerciseIndices.length >= 2;
  bool get isCircuit => rounds >= 2 && exerciseIndices.length >= 2;

  WorkoutBlock copyWith({
    String? id,
    String? name,
    List<int>? exerciseIndices,
    int? rounds,
    Duration? restBetween,
    Duration? restAfterBlock,
    Map<String, dynamic>? meta,
  }) => WorkoutBlock(
    id: id ?? this.id,
    name: name ?? this.name,
    exerciseIndices: exerciseIndices ?? this.exerciseIndices,
    rounds: rounds ?? this.rounds,
    restBetween: restBetween ?? this.restBetween,
    restAfterBlock: restAfterBlock ?? this.restAfterBlock,
    meta: meta ?? this.meta,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (name.isNotEmpty) 'name': name,
    'exerciseIndices': exerciseIndices,
    'rounds': rounds,
    if (restBetween != null) 'restBetween': restBetween!.inSeconds,
    if (restAfterBlock != null) 'restAfterBlock': restAfterBlock!.inSeconds,
    if (meta != null) 'meta': meta,
  };

  factory WorkoutBlock.fromJson(Map<String, dynamic> json) => WorkoutBlock(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    exerciseIndices: ((json['exerciseIndices'] as List<dynamic>?) ?? const [])
        .whereType<num>()
        .map((n) => n.toInt())
        .toList(growable: false),
    rounds: (json['rounds'] as num?)?.toInt() ?? 1,
    restBetween:
        json['restBetween'] == null
            ? null
            : Duration(seconds: (json['restBetween'] as num).toInt()),
    restAfterBlock:
        json['restAfterBlock'] == null
            ? null
            : Duration(seconds: (json['restAfterBlock'] as num).toInt()),
    meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutBlock &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
