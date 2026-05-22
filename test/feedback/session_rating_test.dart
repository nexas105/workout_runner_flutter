import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionRating JSON round-trip', () {
    test('preserves all fields when fully populated', () {
      final rating = SessionRating(
        sessionKey: 'plan-1|2026-05-21T10:00:00.000',
        mood: SessionMood.good,
        difficulty: 4,
        energy: 3,
        sleepQuality: 5,
        overallRating: 4,
        notes: 'felt strong',
        ratedAt: DateTime.utc(2026, 5, 21, 10, 5),
      );

      final round = SessionRating.fromJson(rating.toJson());

      expect(round.sessionKey, rating.sessionKey);
      expect(round.mood, SessionMood.good);
      expect(round.difficulty, 4);
      expect(round.energy, 3);
      expect(round.sleepQuality, 5);
      expect(round.overallRating, 4);
      expect(round.notes, 'felt strong');
      expect(round.ratedAt, rating.ratedAt);
    });

    test('preserves nullable fields when omitted', () {
      final rating = SessionRating(ratedAt: DateTime.utc(2026, 5, 21, 10, 0));

      final round = SessionRating.fromJson(rating.toJson());

      expect(round.sessionKey, isNull);
      expect(round.mood, isNull);
      expect(round.difficulty, isNull);
      expect(round.energy, isNull);
      expect(round.sleepQuality, isNull);
      expect(round.overallRating, isNull);
      expect(round.notes, isNull);
      expect(round.ratedAt, rating.ratedAt);
    });

    test('copyWith overrides selectively', () {
      final base = SessionRating(
        sessionKey: 'k1',
        mood: SessionMood.neutral,
        difficulty: 2,
        ratedAt: DateTime.utc(2026, 5, 21),
      );
      final next = base.copyWith(mood: SessionMood.great, notes: 'pr day');
      expect(next.sessionKey, 'k1');
      expect(next.mood, SessionMood.great);
      expect(next.difficulty, 2);
      expect(next.notes, 'pr day');
    });
  });

  group('keyFor', () {
    test('returns stable composite for WorkoutResult', () {
      final result = WorkoutResult(
        planId: 'plan-42',
        startedAt: DateTime.utc(2026, 5, 21, 9),
        finishedAt: DateTime.utc(2026, 5, 21, 10),
        duration: const Duration(hours: 1),
        exercises: const [],
      );

      final key = SessionRating.keyFor(result);
      expect(key, 'plan-42|2026-05-21T10:00:00.000Z');
      expect(SessionRating.keyFor(result), key);
    });

    test('returns stable composite for CardioResult', () {
      final result = CardioResult(
        planId: 'cardio-7',
        planName: 'Easy Run',
        discipline: CardioDiscipline.running,
        startedAt: DateTime.utc(2026, 5, 21, 7),
        finishedAt: DateTime.utc(2026, 5, 21, 7, 30),
        duration: const Duration(minutes: 30),
        laps: const [],
      );

      final key = SessionRating.keyForCardio(result);
      expect(key, 'cardio-7|2026-05-21T07:30:00.000Z');
    });
  });

  group('SessionRatingStats', () {
    test('averageOverall returns null on empty', () {
      expect(SessionRatingStats.averageOverall(const []), isNull);
    });

    test('averageOverall returns null when no rating has overallRating', () {
      final ratings = [
        SessionRating(mood: SessionMood.good, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(difficulty: 3, ratedAt: DateTime.utc(2026, 1)),
      ];
      expect(SessionRatingStats.averageOverall(ratings), isNull);
    });

    test('averageOverall computes mean ignoring nulls', () {
      final ratings = [
        SessionRating(overallRating: 5, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(overallRating: 3, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(overallRating: 4, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(ratedAt: DateTime.utc(2026, 1)),
      ];
      expect(SessionRatingStats.averageOverall(ratings), closeTo(4.0, 1e-9));
    });

    test('averageDifficulty computes mean ignoring nulls', () {
      final ratings = [
        SessionRating(difficulty: 2, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(difficulty: 4, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(ratedAt: DateTime.utc(2026, 1)),
      ];
      expect(SessionRatingStats.averageDifficulty(ratings), closeTo(3.0, 1e-9));
    });

    test('moodHistogram counts moods and zero-fills missing ones', () {
      final ratings = [
        SessionRating(mood: SessionMood.great, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(mood: SessionMood.great, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(mood: SessionMood.bad, ratedAt: DateTime.utc(2026, 1)),
        SessionRating(ratedAt: DateTime.utc(2026, 1)),
      ];
      final hist = SessionRatingStats.moodHistogram(ratings);
      expect(hist[SessionMood.great], 2);
      expect(hist[SessionMood.good], 0);
      expect(hist[SessionMood.neutral], 0);
      expect(hist[SessionMood.bad], 1);
      expect(hist[SessionMood.terrible], 0);
    });
  });
}
