import '../models/workout_result.dart';
import 'weekly_workout_summary.dart';

abstract class WorkoutStats {
  WorkoutStats._();

  static double totalVolume(List<WorkoutResult> results) {
    var sum = 0.0;
    for (final r in results) {
      sum += r.totalVolume;
    }
    return sum;
  }

  static int totalSets(List<WorkoutResult> results) {
    var sum = 0;
    for (final r in results) {
      sum += r.totalSets;
    }
    return sum;
  }

  static int totalReps(List<WorkoutResult> results) {
    var sum = 0;
    for (final r in results) {
      sum += r.totalReps;
    }
    return sum;
  }

  static Duration totalDuration(List<WorkoutResult> results) {
    var sum = Duration.zero;
    for (final r in results) {
      sum += r.duration;
    }
    return sum;
  }

  static double totalKcal(
    List<WorkoutResult> results, {
    required double bodyWeightKg,
  }) {
    if (bodyWeightKg <= 0) return 0;
    var sum = 0.0;
    for (final r in results) {
      sum += r.kcal(bodyWeightKg: bodyWeightKg);
    }
    return sum;
  }

  static int streakDays(List<WorkoutResult> results, {DateTime? now}) {
    if (results.isEmpty) return 0;
    final today = _dateOnly(now ?? DateTime.now());
    final days = <DateTime>{
      for (final r in results) _dateOnly(r.finishedAt.toLocal()),
    };

    // Anchor: most recent workout day at or before today. A workout in the
    // future relative to `now` is ignored for streak purposes.
    DateTime? anchor;
    for (final d in days) {
      if (!d.isAfter(today) && (anchor == null || d.isAfter(anchor))) {
        anchor = d;
      }
    }
    if (anchor == null) return 0;

    // If the most recent workout is older than yesterday, the streak is broken.
    final gapFromToday = today.difference(anchor).inDays;
    if (gapFromToday > 1) return 0;

    var streak = 0;
    var cursor = anchor;
    while (days.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static WeeklyWorkoutSummary weeklySummary(
    List<WorkoutResult> results, {
    DateTime? weekStart,
  }) {
    final end = weekStart == null
        ? DateTime.now()
        : weekStart.add(const Duration(days: 7));
    final start = weekStart ?? end.subtract(const Duration(days: 7));

    var count = 0;
    var sets = 0;
    var reps = 0;
    var volume = 0.0;
    var dur = Duration.zero;

    for (final r in results) {
      final t = r.finishedAt;
      if (t.isBefore(start) || !t.isBefore(end)) continue;
      count += 1;
      sets += r.totalSets;
      reps += r.totalReps;
      volume += r.totalVolume;
      dur += r.duration;
    }

    return WeeklyWorkoutSummary(
      start: start,
      end: end,
      workoutCount: count,
      totalSets: sets,
      totalReps: reps,
      totalVolume: volume,
      totalDuration: dur,
    );
  }

  static Map<String, double> volumePerExercise(List<WorkoutResult> results) {
    final map = <String, double>{};
    for (final r in results) {
      for (final ex in r.exercises) {
        var v = 0.0;
        for (final s in ex.sets) {
          v += (s.actualWeight ?? 0) * s.actualReps;
        }
        map[ex.exerciseId] = (map[ex.exerciseId] ?? 0) + v;
      }
    }
    return map;
  }

  static DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);
}
