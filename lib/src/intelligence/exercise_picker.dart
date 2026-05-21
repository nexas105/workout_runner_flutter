import '../models/workout_exercise.dart';
import '../storage/exercise_favorites_storage.dart';

/// Pure helper that re-orders a catalog of exercises using favorites + recents
/// pulled from an [ExerciseFavoritesStorage].
///
/// Stateless — the original list is never mutated.
class ExercisePicker {
  const ExercisePicker._();

  static Future<List<WorkoutExercise>> prioritised(
    List<WorkoutExercise> catalog,
    ExerciseFavoritesStorage storage, {
    int favoriteWeight = 3,
    int recentWeight = 2,
    int usageWeight = 1,
    int recentsLimit = 20,
  }) async {
    if (catalog.isEmpty) return const [];

    final favoriteIds = (await storage.favorites()).toSet();
    final recentIds = (await storage.recents(limit: recentsLimit)).toSet();
    final counts = await storage.usageCounts();

    final indexed = <_Scored>[];
    for (var i = 0; i < catalog.length; i++) {
      final ex = catalog[i];
      final isFav = favoriteIds.contains(ex.id);
      final isRecent = recentIds.contains(ex.id);
      final usage = counts[ex.id] ?? 0;
      final cappedUsage = usage > 5 ? 5 : usage;
      final score =
          (isFav ? favoriteWeight : 0) +
          (isRecent ? recentWeight : 0) +
          cappedUsage * usageWeight;
      indexed.add(_Scored(ex, i, score));
    }

    indexed.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.index.compareTo(b.index);
    });

    return indexed.map((s) => s.exercise).toList(growable: false);
  }
}

class _Scored {
  final WorkoutExercise exercise;
  final int index;
  final int score;
  const _Scored(this.exercise, this.index, this.score);
}
