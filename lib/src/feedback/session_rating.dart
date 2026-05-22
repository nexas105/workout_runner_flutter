import '../models/cardio/cardio_result.dart';
import '../models/workout_result.dart';

enum SessionMood { great, good, neutral, bad, terrible }

class SessionRating {
  final String? sessionKey;
  final SessionMood? mood;
  final int? difficulty;
  final int? energy;
  final int? sleepQuality;
  final int? overallRating;
  final String? notes;
  final DateTime ratedAt;

  SessionRating({
    this.sessionKey,
    this.mood,
    this.difficulty,
    this.energy,
    this.sleepQuality,
    this.overallRating,
    this.notes,
    DateTime? ratedAt,
  }) : ratedAt = ratedAt ?? DateTime.now();

  SessionRating copyWith({
    String? sessionKey,
    SessionMood? mood,
    int? difficulty,
    int? energy,
    int? sleepQuality,
    int? overallRating,
    String? notes,
    DateTime? ratedAt,
  }) {
    return SessionRating(
      sessionKey: sessionKey ?? this.sessionKey,
      mood: mood ?? this.mood,
      difficulty: difficulty ?? this.difficulty,
      energy: energy ?? this.energy,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      overallRating: overallRating ?? this.overallRating,
      notes: notes ?? this.notes,
      ratedAt: ratedAt ?? this.ratedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sessionKey': sessionKey,
    'mood': mood?.name,
    'difficulty': difficulty,
    'energy': energy,
    'sleepQuality': sleepQuality,
    'overallRating': overallRating,
    'notes': notes,
    'ratedAt': ratedAt.toIso8601String(),
  };

  static SessionRating fromJson(Map<String, dynamic> json) {
    final moodRaw = json['mood'];
    SessionMood? mood;
    if (moodRaw is String) {
      for (final m in SessionMood.values) {
        if (m.name == moodRaw) {
          mood = m;
          break;
        }
      }
    }
    return SessionRating(
      sessionKey: json['sessionKey'] as String?,
      mood: mood,
      difficulty: json['difficulty'] as int?,
      energy: json['energy'] as int?,
      sleepQuality: json['sleepQuality'] as int?,
      overallRating: json['overallRating'] as int?,
      notes: json['notes'] as String?,
      ratedAt: DateTime.parse(json['ratedAt'] as String),
    );
  }

  static String keyFor(WorkoutResult result) =>
      '${result.planId}|${result.finishedAt.toIso8601String()}';

  static String keyForCardio(CardioResult result) =>
      '${result.planId}|${result.finishedAt.toIso8601String()}';
}

abstract class SessionRatingStats {
  static double? averageOverall(List<SessionRating> ratings) {
    final values = <int>[
      for (final r in ratings)
        if (r.overallRating != null) r.overallRating!,
    ];
    if (values.isEmpty) return null;
    final sum = values.fold<int>(0, (a, b) => a + b);
    return sum / values.length;
  }

  static Map<SessionMood, int> moodHistogram(List<SessionRating> ratings) {
    final hist = <SessionMood, int>{for (final m in SessionMood.values) m: 0};
    for (final r in ratings) {
      final m = r.mood;
      if (m != null) hist[m] = (hist[m] ?? 0) + 1;
    }
    return hist;
  }

  static double? averageDifficulty(List<SessionRating> ratings) {
    final values = <int>[
      for (final r in ratings)
        if (r.difficulty != null) r.difficulty!,
    ];
    if (values.isEmpty) return null;
    final sum = values.fold<int>(0, (a, b) => a + b);
    return sum / values.length;
  }
}
