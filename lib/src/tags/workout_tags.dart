abstract class KnownTag {
  static const String strength = 'strength';
  static const String hypertrophy = 'hypertrophy';
  static const String rehab = 'rehab';
  static const String home = 'home';
  static const String gym = 'gym';
  static const String deload = 'deload';
  static const String cardio = 'cardio';
  static const String hiit = 'hiit';
  static const String liss = 'liss';
  static const String morning = 'morning';
  static const String evening = 'evening';
}

abstract class WorkoutTags {
  static const String _key = 'tags';

  static List<String> read(Map<String, dynamic>? meta) {
    if (meta == null) return const [];
    final raw = meta[_key];
    if (raw is! List) return const [];
    final seen = <String>{};
    final out = <String>[];
    for (final entry in raw) {
      if (entry is! String) continue;
      final cleaned = entry.trim().toLowerCase();
      if (cleaned.isEmpty) continue;
      if (seen.add(cleaned)) out.add(cleaned);
    }
    return out;
  }

  static Map<String, dynamic> write(
    Map<String, dynamic>? meta,
    Iterable<String> tags,
  ) {
    final next = <String, dynamic>{...?meta};
    final seen = <String>{};
    final cleaned = <String>[];
    for (final entry in tags) {
      final c = entry.trim().toLowerCase();
      if (c.isEmpty) continue;
      if (seen.add(c)) cleaned.add(c);
    }
    next[_key] = cleaned;
    return next;
  }

  static Map<String, dynamic> add(Map<String, dynamic>? meta, String tag) {
    final current = read(meta);
    return write(meta, [...current, tag]);
  }

  static Map<String, dynamic> remove(Map<String, dynamic>? meta, String tag) {
    final target = tag.trim().toLowerCase();
    final current = read(meta);
    return write(meta, current.where((t) => t != target));
  }

  static bool has(Map<String, dynamic>? meta, String tag) {
    final target = tag.trim().toLowerCase();
    if (target.isEmpty) return false;
    return read(meta).contains(target);
  }
}
