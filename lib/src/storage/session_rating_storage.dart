import 'dart:async';

import '../feedback/session_rating.dart';

abstract class SessionRatingStorage {
  Future<void> save(SessionRating rating);
  Future<SessionRating?> read(String sessionKey);
  Future<List<SessionRating>> recent({int? limit, DateTime? since});
  Future<void> remove(String sessionKey);
  Future<void> clear();
}

class InMemorySessionRatingStorage implements SessionRatingStorage {
  final Map<String, SessionRating> _byKey = <String, SessionRating>{};

  @override
  Future<void> save(SessionRating rating) async {
    final key = rating.sessionKey;
    if (key == null) {
      throw ArgumentError.value(
        rating,
        'rating',
        'SessionRating.sessionKey is required for storage.',
      );
    }
    _byKey[key] = rating;
  }

  @override
  Future<SessionRating?> read(String sessionKey) async {
    return _byKey[sessionKey];
  }

  @override
  Future<List<SessionRating>> recent({int? limit, DateTime? since}) async {
    final entries =
        _byKey.values.toList()..sort((a, b) => b.ratedAt.compareTo(a.ratedAt));
    Iterable<SessionRating> filtered = entries;
    if (since != null) {
      filtered = filtered.where((r) => !r.ratedAt.isBefore(since));
    }
    if (limit != null && limit >= 0) {
      filtered = filtered.take(limit);
    }
    return filtered.toList(growable: false);
  }

  @override
  Future<void> remove(String sessionKey) async {
    _byKey.remove(sessionKey);
  }

  @override
  Future<void> clear() async {
    _byKey.clear();
  }
}
