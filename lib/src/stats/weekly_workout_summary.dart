class WeeklyWorkoutSummary {
  final DateTime start;
  final DateTime end;
  final int workoutCount;
  final int totalSets;
  final int totalReps;
  final double totalVolume;
  final Duration totalDuration;

  const WeeklyWorkoutSummary({
    required this.start,
    required this.end,
    required this.workoutCount,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.totalDuration,
  });

  const WeeklyWorkoutSummary.empty({required this.start, required this.end})
    : workoutCount = 0,
      totalSets = 0,
      totalReps = 0,
      totalVolume = 0.0,
      totalDuration = Duration.zero;

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'workoutCount': workoutCount,
    'totalSets': totalSets,
    'totalReps': totalReps,
    'totalVolume': totalVolume,
    'totalDurationSec': totalDuration.inSeconds,
  };

  factory WeeklyWorkoutSummary.fromJson(Map<String, dynamic> json) =>
      WeeklyWorkoutSummary(
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        workoutCount: (json['workoutCount'] as num).toInt(),
        totalSets: (json['totalSets'] as num).toInt(),
        totalReps: (json['totalReps'] as num).toInt(),
        totalVolume: (json['totalVolume'] as num).toDouble(),
        totalDuration: Duration(
          seconds: (json['totalDurationSec'] as num).toInt(),
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyWorkoutSummary &&
          other.start == start &&
          other.end == end &&
          other.workoutCount == workoutCount &&
          other.totalSets == totalSets &&
          other.totalReps == totalReps &&
          other.totalVolume == totalVolume &&
          other.totalDuration == totalDuration;

  @override
  int get hashCode => Object.hash(
    start,
    end,
    workoutCount,
    totalSets,
    totalReps,
    totalVolume,
    totalDuration,
  );
}
