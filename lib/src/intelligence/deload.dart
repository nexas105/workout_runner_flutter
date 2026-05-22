import 'dart:math' as math;

import '../models/set_type.dart';
import '../models/workout_exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_set.dart';

enum DeloadStrategy { volume, intensity, balanced, mobility }

class DeloadConfig {
  final double setMultiplier;
  final double weightMultiplier;
  final double repMultiplier;

  const DeloadConfig({
    this.setMultiplier = 0.6,
    this.weightMultiplier = 0.7,
    this.repMultiplier = 0.8,
  });

  const DeloadConfig.volume()
    : setMultiplier = 0.5,
      weightMultiplier = 0.85,
      repMultiplier = 0.9;

  const DeloadConfig.intensity()
    : setMultiplier = 0.8,
      weightMultiplier = 0.6,
      repMultiplier = 0.85;

  const DeloadConfig.balanced()
    : setMultiplier = 0.6,
      weightMultiplier = 0.7,
      repMultiplier = 0.85;

  const DeloadConfig.mobility()
    : setMultiplier = 0.4,
      weightMultiplier = 0.5,
      repMultiplier = 0.7;

  factory DeloadConfig.fromStrategy(DeloadStrategy s) {
    switch (s) {
      case DeloadStrategy.volume:
        return const DeloadConfig.volume();
      case DeloadStrategy.intensity:
        return const DeloadConfig.intensity();
      case DeloadStrategy.balanced:
        return const DeloadConfig.balanced();
      case DeloadStrategy.mobility:
        return const DeloadConfig.mobility();
    }
  }
}

abstract class DeloadPlan {
  static WorkoutPlan from(
    WorkoutPlan plan, {
    DeloadStrategy strategy = DeloadStrategy.balanced,
    DeloadConfig? config,
    String? idSuffix,
  }) {
    final cfg = config ?? DeloadConfig.fromStrategy(strategy);
    final suffix = idSuffix ?? '_deload';

    final newExercises = <WorkoutExercise>[];
    for (final ex in plan.exercises) {
      final warmups = <WorkoutSet>[];
      final workings = <WorkoutSet>[];
      for (final s in ex.sets) {
        if (s.type == SetType.warmup) {
          warmups.add(s);
        } else {
          workings.add(s);
        }
      }

      final keepCount =
          workings.isEmpty
              ? 0
              : math.max(1, (workings.length * cfg.setMultiplier).ceil());
      final keptWorking =
          workings.take(keepCount).map((s) {
            final reps = math.max(
              1,
              (s.targetReps * cfg.repMultiplier).round(),
            );
            final weight =
                s.targetWeight == null
                    ? null
                    : _roundToHalf(s.targetWeight! * cfg.weightMultiplier);
            return WorkoutSet(
              targetReps: reps,
              targetWeight: weight,
              rest: s.rest,
              type: SetType.working,
              targetDuration: s.targetDuration,
            );
          }).toList();

      newExercises.add(ex.copyWith(sets: [...warmups, ...keptWorking]));
    }

    return plan.copyWith(
      id: '${plan.id}$suffix',
      name: '${plan.name} (Deload)',
      exercises: newExercises,
    );
  }

  static double _roundToHalf(double v) => (v * 2).round() / 2;
}
