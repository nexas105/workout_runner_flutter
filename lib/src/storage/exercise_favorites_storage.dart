import 'dart:async';

/// Optional storage for exercise favorites and usage tracking.
///
/// Kept separate from [WorkoutHistoryStorage] so apps can persist favorites
/// in lightweight key/value stores (SharedPreferences, Hive box, …) without
/// pulling in the full workout history pipeline.
///
/// Implementations should:
///
/// * keep favorites as a set (no duplicates),
/// * order [recents] newest-first by last [recordUsage] timestamp,
/// * order [mostUsed] by count desc, ties broken alphabetically by id.
abstract class ExerciseFavoritesStorage {
  Future<void> addFavorite(String exerciseId);
  Future<void> removeFavorite(String exerciseId);
  Future<bool> isFavorite(String exerciseId);
  Future<List<String>> favorites();

  Future<void> recordUsage(String exerciseId, {DateTime? at});
  Future<List<String>> recents({int limit = 10});

  Future<Map<String, int>> usageCounts();
  Future<List<String>> mostUsed({int limit = 10});

  Future<void> clear();
}
