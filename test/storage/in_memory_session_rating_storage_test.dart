import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySessionRatingStorage storage;

  setUp(() {
    storage = InMemorySessionRatingStorage();
  });

  test('save / read round-trip', () async {
    final rating = SessionRating(
      sessionKey: 'k-a',
      mood: SessionMood.good,
      overallRating: 4,
      ratedAt: DateTime.utc(2026, 5, 1),
    );

    await storage.save(rating);

    final read = await storage.read('k-a');
    expect(read, isNotNull);
    expect(read!.sessionKey, 'k-a');
    expect(read.mood, SessionMood.good);
    expect(read.overallRating, 4);
  });

  test('save overwrites the same sessionKey', () async {
    await storage.save(SessionRating(
      sessionKey: 'k-a',
      overallRating: 2,
      ratedAt: DateTime.utc(2026, 5, 1),
    ));
    await storage.save(SessionRating(
      sessionKey: 'k-a',
      overallRating: 5,
      ratedAt: DateTime.utc(2026, 5, 2),
    ));

    final read = await storage.read('k-a');
    expect(read!.overallRating, 5);
    expect((await storage.recent()).length, 1);
  });

  test('save throws when sessionKey is null', () async {
    expect(
      () => storage.save(SessionRating(ratedAt: DateTime.utc(2026, 5, 1))),
      throwsArgumentError,
    );
  });

  test('recent returns newest-first by ratedAt', () async {
    await storage.save(SessionRating(
      sessionKey: 'old',
      ratedAt: DateTime.utc(2026, 1, 1),
    ));
    await storage.save(SessionRating(
      sessionKey: 'mid',
      ratedAt: DateTime.utc(2026, 3, 1),
    ));
    await storage.save(SessionRating(
      sessionKey: 'new',
      ratedAt: DateTime.utc(2026, 5, 1),
    ));

    final all = await storage.recent();
    expect(all.map((r) => r.sessionKey).toList(), ['new', 'mid', 'old']);
  });

  test('recent respects limit', () async {
    for (var i = 0; i < 5; i++) {
      await storage.save(SessionRating(
        sessionKey: 'k$i',
        ratedAt: DateTime.utc(2026, 5, i + 1),
      ));
    }
    final top2 = await storage.recent(limit: 2);
    expect(top2.length, 2);
    expect(top2.first.sessionKey, 'k4');
    expect(top2.last.sessionKey, 'k3');
  });

  test('recent filters by since (inclusive)', () async {
    await storage.save(SessionRating(
      sessionKey: 'jan',
      ratedAt: DateTime.utc(2026, 1, 15),
    ));
    await storage.save(SessionRating(
      sessionKey: 'mar',
      ratedAt: DateTime.utc(2026, 3, 10),
    ));
    await storage.save(SessionRating(
      sessionKey: 'may',
      ratedAt: DateTime.utc(2026, 5, 1),
    ));

    final since = await storage.recent(since: DateTime.utc(2026, 3, 10));
    expect(since.map((r) => r.sessionKey).toList(), ['may', 'mar']);
  });

  test('remove deletes only the matching key', () async {
    await storage.save(SessionRating(
      sessionKey: 'a',
      ratedAt: DateTime.utc(2026, 5, 1),
    ));
    await storage.save(SessionRating(
      sessionKey: 'b',
      ratedAt: DateTime.utc(2026, 5, 2),
    ));

    await storage.remove('a');
    expect(await storage.read('a'), isNull);
    expect(await storage.read('b'), isNotNull);
  });

  test('clear empties the storage', () async {
    await storage.save(SessionRating(
      sessionKey: 'a',
      ratedAt: DateTime.utc(2026, 5, 1),
    ));
    await storage.save(SessionRating(
      sessionKey: 'b',
      ratedAt: DateTime.utc(2026, 5, 2),
    ));

    await storage.clear();
    expect(await storage.recent(), isEmpty);
    expect(await storage.read('a'), isNull);
  });
}