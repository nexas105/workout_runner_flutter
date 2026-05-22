import '../models/workout_exercise.dart';

abstract class ExerciseSearch {
  static List<WorkoutExercise> query(
    List<WorkoutExercise> source,
    String text,
  ) {
    final tokens = _tokenize(text);
    if (tokens.isEmpty) {
      return List<WorkoutExercise>.of(source);
    }

    final scored = <_ScoredEntry>[];
    for (var i = 0; i < source.length; i++) {
      final exercise = source[i];
      final score = _scoreExercise(exercise, tokens);
      if (score != null) {
        scored.add(_ScoredEntry(exercise, score, i));
      }
    }

    scored.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      if (byScore != 0) return byScore;
      return a.originalIndex.compareTo(b.originalIndex);
    });

    return scored.map((e) => e.exercise).toList(growable: false);
  }

  static List<WorkoutExercise> filter(
    List<WorkoutExercise> source, {
    String? categoryId,
    Set<String>? muscleIds,
    String? equipmentMetaKey,
    String? movementPatternMetaKey,
  }) {
    return source
        .where((exercise) {
          if (categoryId != null) {
            final catId =
                exercise.category?.id ?? _metaString(exercise, 'category');
            if (catId != categoryId) return false;
          }
          if (muscleIds != null && muscleIds.isNotEmpty) {
            final ids = exercise.muscles.map((m) => m.id).toSet();
            if (!muscleIds.every(ids.contains)) return false;
          }
          if (equipmentMetaKey != null) {
            final equipment = _metaString(exercise, 'equipment');
            if (equipment?.toLowerCase() != equipmentMetaKey.toLowerCase()) {
              return false;
            }
          }
          if (movementPatternMetaKey != null) {
            final pattern = _metaString(exercise, 'movementPattern');
            if (pattern?.toLowerCase() !=
                movementPatternMetaKey.toLowerCase()) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  static List<String> suggest(
    List<WorkoutExercise> source,
    String partial, {
    int limit = 5,
  }) {
    final needle = partial.trim().toLowerCase();
    if (needle.isEmpty || limit <= 0) return const [];

    final seen = <String>{};
    final prefixHits = <String>[];
    final containsHits = <String>[];

    for (final exercise in source) {
      final candidates = <String>[exercise.name, ..._aliases(exercise)];
      for (final candidate in candidates) {
        if (candidate.isEmpty) continue;
        final lower = candidate.toLowerCase();
        if (!lower.contains(needle)) continue;
        if (!seen.add(lower)) continue;
        if (lower.startsWith(needle)) {
          prefixHits.add(candidate);
        } else {
          containsHits.add(candidate);
        }
      }
    }

    final out = <String>[...prefixHits, ...containsHits];
    if (out.length > limit) {
      return out.sublist(0, limit);
    }
    return out;
  }

  static List<String> _tokenize(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }

  static int? _scoreExercise(WorkoutExercise exercise, List<String> tokens) {
    final name = exercise.name.toLowerCase();
    final description = exercise.description?.toLowerCase() ?? '';
    final categoryName = exercise.category?.name.toLowerCase() ?? '';
    final muscleNames = exercise.muscles
        .map((m) => m.name.toLowerCase())
        .toList(growable: false);
    final aliases = _aliases(
      exercise,
    ).map((a) => a.toLowerCase()).toList(growable: false);

    if (tokens.length == 1) {
      final t = tokens.first;
      if (name == t) return 0;
    }

    var aggregate = 0;
    for (final token in tokens) {
      final tokenScore = _scoreToken(
        token,
        name: name,
        description: description,
        categoryName: categoryName,
        muscleNames: muscleNames,
        aliases: aliases,
      );
      if (tokenScore == null) return null;
      if (tokenScore > aggregate) aggregate = tokenScore;
    }

    if (tokens.length > 1 && name == tokens.join(' ')) {
      return 0;
    }
    if (aggregate == 0) {
      return tokens.length == 1 ? 0 : 1;
    }
    return aggregate;
  }

  static int? _scoreToken(
    String token, {
    required String name,
    required String description,
    required String categoryName,
    required List<String> muscleNames,
    required List<String> aliases,
  }) {
    if (name == token) return 0;
    if (name.startsWith(token)) return 1;
    for (final alias in aliases) {
      if (alias == token) return 1;
      if (alias.startsWith(token)) return 2;
    }
    if (name.contains(token)) return 3;
    for (final alias in aliases) {
      if (alias.contains(token)) return 4;
    }
    if (categoryName.contains(token)) return 5;
    for (final muscle in muscleNames) {
      if (muscle.contains(token)) return 5;
    }
    if (description.contains(token)) return 6;
    return null;
  }

  static List<String> _aliases(WorkoutExercise exercise) {
    final meta = exercise.meta;
    if (meta == null) return const [];
    final raw = meta['aliases'];
    if (raw is List) {
      return raw.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  static String? _metaString(WorkoutExercise exercise, String key) {
    final meta = exercise.meta;
    if (meta == null) return null;
    final value = meta[key];
    if (value is String) return value;
    return null;
  }
}

class _ScoredEntry {
  final WorkoutExercise exercise;
  final int score;
  final int originalIndex;

  _ScoredEntry(this.exercise, this.score, this.originalIndex);
}
