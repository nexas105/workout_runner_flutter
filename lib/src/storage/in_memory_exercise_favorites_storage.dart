import 'dart:async';

import 'exercise_favorites_storage.dart';

/// In-memory [ExerciseFavoritesStorage] for tests, demos and prototypes.
///
/// Not persisted across app launches — wire a SharedPreferences/Hive-backed
/// implementation for production use.
class InMemoryExerciseFavoritesStorage implements ExerciseFavoritesStorage {
  final Set<String> _favorites = <String>{};
  final Map<String, DateTime> _lastUsed = <String, DateTime>{};
  final Map<String, int> _counts = <String, int>{};

  @override
  Future<void> addFavorite(String exerciseId) async {
    _favorites.add(exerciseId);
  }

  @override
  Future<void> removeFavorite(String exerciseId) async {
    _favorites.remove(exerciseId);
  }

  @override
  Future<bool> isFavorite(String exerciseId) async {
    return _favorites.contains(exerciseId);
  }

  @override
  Future<List<String>> favorites() async {
    return _favorites.toList(growable: false);
  }

  @override
  Future<void> recordUsage(String exerciseId, {DateTime? at}) async {
    _lastUsed[exerciseId] = at ?? DateTime.now();
    _counts[exerciseId] = (_counts[exerciseId] ?? 0) + 1;
  }

  @override
  Future<List<String>> recents({int limit = 10}) async {
    final entries =
        _lastUsed.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final ids = entries.map((e) => e.key).toList();
    if (ids.length > limit) {
      return ids.take(limit).toList();
    }
    return ids;
  }

  @override
  Future<Map<String, int>> usageCounts() async {
    return Map<String, int>.from(_counts);
  }

  @override
  Future<List<String>> mostUsed({int limit = 10}) async {
    final entries =
        _counts.entries.toList()..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          if (byCount != 0) return byCount;
          return a.key.compareTo(b.key);
        });
    final ids = entries.map((e) => e.key).toList();
    if (ids.length > limit) {
      return ids.take(limit).toList();
    }
    return ids;
  }

  @override
  Future<void> clear() async {
    _favorites.clear();
    _lastUsed.clear();
    _counts.clear();
  }
}
