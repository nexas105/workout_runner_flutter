import 'package:flutter/foundation.dart';

import '../data/default_exercises.dart';
import '../models/workout_exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_set.dart';

enum TrainingGoal { strength, hypertrophy, conditioning, general }

extension TrainingGoalSerializer on TrainingGoal {
  String get id => name;

  static TrainingGoal fromId(String? raw) {
    if (raw == null) return TrainingGoal.general;
    return TrainingGoal.values.firstWhere(
      (g) => g.name == raw,
      orElse: () => TrainingGoal.general,
    );
  }
}

enum ExperienceLevel { beginner, intermediate, advanced }

extension ExperienceLevelSerializer on ExperienceLevel {
  String get id => name;

  static ExperienceLevel fromId(String? raw) {
    if (raw == null) return ExperienceLevel.intermediate;
    return ExperienceLevel.values.firstWhere(
      (l) => l.name == raw,
      orElse: () => ExperienceLevel.intermediate,
    );
  }
}

@immutable
class PlanGenerationProfile {
  final TrainingGoal goal;
  final ExperienceLevel level;
  final int daysPerWeek;
  final Set<String> equipment;

  PlanGenerationProfile({
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    Set<String>? equipment,
  }) : assert(
         daysPerWeek >= 3 && daysPerWeek <= 6,
         'daysPerWeek must be in 3..6',
       ),
       equipment = Set.unmodifiable(equipment ?? const <String>{});

  PlanGenerationProfile copyWith({
    TrainingGoal? goal,
    ExperienceLevel? level,
    int? daysPerWeek,
    Set<String>? equipment,
  }) => PlanGenerationProfile(
    goal: goal ?? this.goal,
    level: level ?? this.level,
    daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    equipment: equipment ?? this.equipment,
  );

  Map<String, dynamic> toJson() => {
    'goal': goal.id,
    'level': level.id,
    'daysPerWeek': daysPerWeek,
    'equipment': equipment.toList(),
  };

  factory PlanGenerationProfile.fromJson(Map<String, dynamic> json) =>
      PlanGenerationProfile(
        goal: TrainingGoalSerializer.fromId(json['goal'] as String?),
        level: ExperienceLevelSerializer.fromId(json['level'] as String?),
        daysPerWeek: (json['daysPerWeek'] as num).toInt(),
        equipment:
            (json['equipment'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            const <String>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanGenerationProfile &&
          runtimeType == other.runtimeType &&
          goal == other.goal &&
          level == other.level &&
          daysPerWeek == other.daysPerWeek &&
          equipment.length == other.equipment.length &&
          equipment.containsAll(other.equipment);

  @override
  int get hashCode => Object.hash(
    goal,
    level,
    daysPerWeek,
    Object.hashAllUnordered(equipment),
  );
}

abstract class PlanGenerator {
  PlanGenerator._();

  static const List<String> _pushIds = [
    'ex_bench_press',
    'ex_ohp',
    'ex_incline_db_press',
    'ex_dips',
    'ex_pushups',
  ];

  static const List<String> _pullIds = [
    'ex_pullups',
    'ex_barbell_row',
    'ex_lat_pulldown',
    'ex_face_pulls',
    'ex_barbell_curl',
    'ex_hammer_curl',
  ];

  static const List<String> _squatIds = [
    'ex_squat',
    'ex_front_squat',
    'ex_leg_press',
    'ex_lunges',
  ];

  static const List<String> _hingeIds = [
    'ex_deadlift',
    'ex_rdl',
    'ex_hip_thrust',
    'ex_kettlebell_swing',
  ];

  static const List<String> _legAccessoryIds = [
    'ex_leg_curl',
    'ex_calf_raise',
  ];

  static const List<String> _pushAccessoryIds = [
    'ex_triceps_pushdown',
  ];

  static WorkoutPlan fullBody(
    PlanGenerationProfile profile, {
    String? id,
    String? name,
  }) {
    final pool = _allowedExercises(profile);
    final picks = <WorkoutExercise>[];
    final push = _firstAllowed(_pushIds, pool);
    final pull = _firstAllowed(_pullIds, pool);
    final squat = _firstAllowed(_squatIds, pool);
    final hinge = _firstAllowed(_hingeIds, pool);
    for (final e in [push, pull, squat, hinge]) {
      if (e != null) picks.add(e);
    }
    if (picks.length < 6) {
      final extra = _firstAllowed(
        [..._pushAccessoryIds, ..._legAccessoryIds, ..._pullIds],
        pool,
        exclude: picks.map((e) => e.id).toSet(),
      );
      if (extra != null) picks.add(extra);
    }
    if (picks.length < 6) {
      final extra = _firstAllowed(
        _pullIds,
        pool,
        exclude: picks.map((e) => e.id).toSet(),
      );
      if (extra != null) picks.add(extra);
    }
    final exercises = picks
        .map((e) => _applyScheme(e, profile))
        .toList(growable: false);
    return WorkoutPlan(
      id: id ?? 'plan_generated_full_body',
      name: name ?? 'Full body',
      description: _planDescription(profile),
      exercises: exercises,
      meta: _planMeta(profile, 'fullBody'),
    );
  }

  static List<WorkoutPlan> pushPullLegs(PlanGenerationProfile profile) {
    final pool = _allowedExercises(profile);
    final push = _pickAll(_pushIds, pool, max: 4)
      ..addAll(_pickAll(_pushAccessoryIds, pool, max: 1));
    final pull = _pickAll(_pullIds, pool, max: 4);
    final legs = [
      ..._pickAll(_squatIds, pool, max: 2),
      ..._pickAll(_hingeIds, pool, max: 2),
      ..._pickAll(_legAccessoryIds, pool, max: 1),
    ];

    WorkoutPlan build(String slug, String displayName, List<WorkoutExercise> e) =>
        WorkoutPlan(
          id: 'plan_generated_ppl_$slug',
          name: displayName,
          description: _planDescription(profile),
          exercises: e.map((x) => _applyScheme(x, profile)).toList(),
          meta: _planMeta(profile, 'pushPullLegs_$slug'),
        );

    return [
      build('push', 'Push', push),
      build('pull', 'Pull', pull),
      build('legs', 'Legs', legs),
    ];
  }

  static List<WorkoutPlan> upperLower(PlanGenerationProfile profile) {
    final pool = _allowedExercises(profile);
    final upper = [
      ..._pickAll(_pushIds, pool, max: 2),
      ..._pickAll(_pullIds, pool, max: 2),
      ..._pickAll(_pushAccessoryIds, pool, max: 1),
    ];
    final lower = [
      ..._pickAll(_squatIds, pool, max: 2),
      ..._pickAll(_hingeIds, pool, max: 2),
      ..._pickAll(_legAccessoryIds, pool, max: 1),
    ];

    WorkoutPlan build(
      String slug,
      String displayName,
      List<WorkoutExercise> e,
    ) => WorkoutPlan(
      id: 'plan_generated_ul_$slug',
      name: displayName,
      description: _planDescription(profile),
      exercises: e.map((x) => _applyScheme(x, profile)).toList(),
      meta: _planMeta(profile, 'upperLower_$slug'),
    );

    return [build('upper', 'Upper', upper), build('lower', 'Lower', lower)];
  }

  static WorkoutPlan fromEquipment(PlanGenerationProfile profile) {
    switch (profile.daysPerWeek) {
      case 3:
        return fullBody(profile);
      case 4:
      case 5:
        return upperLower(profile).first;
      case 6:
        return pushPullLegs(profile).first;
      default:
        return fullBody(profile);
    }
  }

  static List<WorkoutExercise> _allowedExercises(
    PlanGenerationProfile profile,
  ) {
    if (profile.equipment.isEmpty) return DefaultExercises.all;
    return DefaultExercises.all.where((e) {
      final eq = e.meta?['equipment'];
      if (eq is String) return profile.equipment.contains(eq);
      return true;
    }).toList();
  }

  static WorkoutExercise? _firstAllowed(
    List<String> ids,
    List<WorkoutExercise> pool, {
    Set<String> exclude = const {},
  }) {
    for (final id in ids) {
      if (exclude.contains(id)) continue;
      for (final e in pool) {
        if (e.id == id) return e;
      }
    }
    return null;
  }

  static List<WorkoutExercise> _pickAll(
    List<String> ids,
    List<WorkoutExercise> pool, {
    required int max,
  }) {
    final out = <WorkoutExercise>[];
    for (final id in ids) {
      if (out.length >= max) break;
      for (final e in pool) {
        if (e.id == id) {
          out.add(e);
          break;
        }
      }
    }
    return out;
  }

  static WorkoutExercise _applyScheme(
    WorkoutExercise base,
    PlanGenerationProfile profile,
  ) {
    final scheme = _schemeFor(profile);
    final rest = Duration(seconds: _restSecondsFor(profile.goal));
    final firstWeight = base.sets.isNotEmpty
        ? base.sets.first.targetWeight
        : null;
    final sets = List<WorkoutSet>.generate(
      scheme.sets,
      (_) => WorkoutSet(
        targetReps: scheme.reps,
        targetWeight: firstWeight,
        rest: rest,
      ),
    );
    return base.copyWith(sets: sets);
  }

  static _SetScheme _schemeFor(PlanGenerationProfile profile) {
    switch (profile.goal) {
      case TrainingGoal.strength:
        if (profile.level == ExperienceLevel.beginner) {
          return const _SetScheme(sets: 3, reps: 5);
        }
        return const _SetScheme(sets: 5, reps: 5);
      case TrainingGoal.hypertrophy:
        return const _SetScheme(sets: 4, reps: 10);
      case TrainingGoal.conditioning:
        return const _SetScheme(sets: 3, reps: 15);
      case TrainingGoal.general:
        return const _SetScheme(sets: 3, reps: 10);
    }
  }

  static int _restSecondsFor(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.strength:
        return 180;
      case TrainingGoal.hypertrophy:
        return 90;
      case TrainingGoal.conditioning:
        return 45;
      case TrainingGoal.general:
        return 60;
    }
  }

  static String _planDescription(PlanGenerationProfile profile) =>
      'Generated for ${profile.goal.id} • ${profile.level.id} • '
      '${profile.daysPerWeek} d/wk';

  static Map<String, dynamic> _planMeta(
    PlanGenerationProfile profile,
    String template,
  ) => {
    'generator': 'PlanGenerator',
    'template': template,
    'profile': profile.toJson(),
  };
}

@immutable
class _SetScheme {
  final int sets;
  final int reps;
  const _SetScheme({required this.sets, required this.reps});
}
