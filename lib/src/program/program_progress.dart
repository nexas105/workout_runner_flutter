import '../models/cardio/cardio_result.dart';
import '../models/workout_result.dart';
import 'training_program.dart';

class ProgramProgress {
  final String programId;
  final int currentWeekIndex;
  final int currentDayIndex;
  final Set<String> completedDayIds;
  final Set<String> skippedDayIds;
  final Set<String> allDayIds;

  const ProgramProgress({
    required this.programId,
    required this.currentWeekIndex,
    required this.currentDayIndex,
    this.completedDayIds = const {},
    this.skippedDayIds = const {},
    this.allDayIds = const {},
  });

  ProgramProgress copyWith({
    String? programId,
    int? currentWeekIndex,
    int? currentDayIndex,
    Set<String>? completedDayIds,
    Set<String>? skippedDayIds,
    Set<String>? allDayIds,
  }) => ProgramProgress(
    programId: programId ?? this.programId,
    currentWeekIndex: currentWeekIndex ?? this.currentWeekIndex,
    currentDayIndex: currentDayIndex ?? this.currentDayIndex,
    completedDayIds: completedDayIds ?? this.completedDayIds,
    skippedDayIds: skippedDayIds ?? this.skippedDayIds,
    allDayIds: allDayIds ?? this.allDayIds,
  );

  /// True when every known program day id is either completed or skipped.
  /// Relies on [allDayIds] being populated (`compute()` does this).
  bool get isCompleted {
    if (allDayIds.isEmpty) return false;
    for (final id in allDayIds) {
      if (!completedDayIds.contains(id) && !skippedDayIds.contains(id)) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'programId': programId,
    'currentWeekIndex': currentWeekIndex,
    'currentDayIndex': currentDayIndex,
    'completedDayIds': completedDayIds.toList(),
    'skippedDayIds': skippedDayIds.toList(),
    if (allDayIds.isNotEmpty) 'allDayIds': allDayIds.toList(),
  };

  factory ProgramProgress.fromJson(Map<String, dynamic> json) =>
      ProgramProgress(
        programId: json['programId'] as String,
        currentWeekIndex: (json['currentWeekIndex'] as num).toInt(),
        currentDayIndex: (json['currentDayIndex'] as num).toInt(),
        completedDayIds: ((json['completedDayIds'] as List<dynamic>?) ??
                const [])
            .map((e) => e as String)
            .toSet(),
        skippedDayIds: ((json['skippedDayIds'] as List<dynamic>?) ??
                const [])
            .map((e) => e as String)
            .toSet(),
        allDayIds: ((json['allDayIds'] as List<dynamic>?) ?? const [])
            .map((e) => e as String)
            .toSet(),
      );
}

abstract class ProgramProgressTracker {
  static ProgramProgress compute(
    TrainingProgram program,
    List<WorkoutResult> workoutResults,
    List<CardioResult> cardioResults, {
    DateTime? startedAt,
  }) {
    final start = startedAt ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final strengthByPlan = <String, List<DateTime>>{};
    for (final r in workoutResults) {
      if (r.finishedAt.isBefore(start)) continue;
      strengthByPlan
          .putIfAbsent(r.planId, () => <DateTime>[])
          .add(r.finishedAt);
    }
    final cardioByPlan = <String, List<DateTime>>{};
    for (final r in cardioResults) {
      if (r.finishedAt.isBefore(start)) continue;
      cardioByPlan
          .putIfAbsent(r.planId, () => <DateTime>[])
          .add(r.finishedAt);
    }
    for (final list in strengthByPlan.values) {
      list.sort((a, b) => a.compareTo(b));
    }
    for (final list in cardioByPlan.values) {
      list.sort((a, b) => a.compareTo(b));
    }

    final completed = <String>{};
    final allIds = <String>{};
    int? currentWeek;
    int? currentDay;

    for (final w in program.weeks) {
      for (var i = 0; i < w.days.length; i++) {
        final d = w.days[i];
        allIds.add(d.id);
        final pid = d.planId;
        var dayCompleted = false;
        if (pid != null) {
          if (d.kind == ProgramDayKind.strength) {
            final pool = strengthByPlan[pid];
            if (pool != null && pool.isNotEmpty) {
              pool.removeAt(0);
              dayCompleted = true;
            }
          } else if (d.kind == ProgramDayKind.cardio) {
            final pool = cardioByPlan[pid];
            if (pool != null && pool.isNotEmpty) {
              pool.removeAt(0);
              dayCompleted = true;
            }
          }
        }
        if (dayCompleted) {
          completed.add(d.id);
        } else {
          currentWeek ??= w.index;
          currentDay ??= i;
        }
      }
    }

    final firstWeek = program.weeks.isNotEmpty ? program.weeks.first.index : 1;
    return ProgramProgress(
      programId: program.id,
      currentWeekIndex: currentWeek ?? firstWeek,
      currentDayIndex: currentDay ?? 0,
      completedDayIds: completed,
      skippedDayIds: const {},
      allDayIds: allIds,
    );
  }
}
