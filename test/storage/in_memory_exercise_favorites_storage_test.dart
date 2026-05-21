import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryExerciseFavoritesStorage storage;

  setUp(() {
    storage = InMemoryExerciseFavoritesStorage();
  });

  group('favorites', () {
    test('add / remove / isFavorite', () async {
      expect(await storage.isFavorite('bench'), isFalse);

      await storage.addFavorite('bench');
      await storage.addFavorite('squat');
      expect(await storage.isFavorite('bench'), isTrue);
      expect((await storage.favorites()).toSet(), {'bench', 'squat'});

      // duplicate add stays a set
      await storage.addFavorite('bench');
      expect((await storage.favorites()).length, 2);

      await storage.removeFavorite('bench');
      expect(await storage.isFavorite('bench'), isFalse);
      expect((await storage.favorites()).toSet(), {'squat'});
    });
  });

  group('recents', () {
    test('orders by most recent timestamp, newest first', () async {
      await storage.recordUsage('a', at: DateTime(2026, 1, 1));
      await storage.recordUsage('b', at: DateTime(2026, 1, 3));
      await storage.recordUsage('c', at: DateTime(2026, 1, 2));

      expect(await storage.recents(), ['b', 'c', 'a']);
    });

    test('duplicate recordUsage updates the timestamp', () async {
      await storage.recordUsage('a', at: DateTime(2026, 1, 1));
      await storage.recordUsage('b', at: DateTime(2026, 1, 2));
      await storage.recordUsage('a', at: DateTime(2026, 1, 3));

      expect(await storage.recents(), ['a', 'b']);
    });

    test('honours limit', () async {
      await storage.recordUsage('a', at: DateTime(2026, 1, 1));
      await storage.recordUsage('b', at: DateTime(2026, 1, 2));
      await storage.recordUsage('c', at: DateTime(2026, 1, 3));

      expect(await storage.recents(limit: 2), ['c', 'b']);
    });
  });

  group('mostUsed', () {
    test('orders by count desc, ties broken alphabetically by id', () async {
      await storage.recordUsage('zebra');
      await storage.recordUsage('apple');
      await storage.recordUsage('apple');
      await storage.recordUsage('mango');
      await storage.recordUsage('mango');
      await storage.recordUsage('zebra');

      // counts: apple=2, mango=2, zebra=2 — all tied, alpha order
      expect(await storage.mostUsed(), ['apple', 'mango', 'zebra']);

      await storage.recordUsage('mango');
      // counts: mango=3, apple=2, zebra=2
      expect(await storage.mostUsed(), ['mango', 'apple', 'zebra']);
    });

    test('honours limit', () async {
      await storage.recordUsage('a');
      await storage.recordUsage('b');
      await storage.recordUsage('c');

      expect((await storage.mostUsed(limit: 2)).length, 2);
    });

    test('usageCounts returns a copy', () async {
      await storage.recordUsage('a');
      await storage.recordUsage('a');

      final counts = await storage.usageCounts();
      expect(counts['a'], 2);

      counts['a'] = 99;
      final reread = await storage.usageCounts();
      expect(reread['a'], 2);
    });
  });

  test('clear wipes favorites, recents and counts', () async {
    await storage.addFavorite('bench');
    await storage.recordUsage('bench');
    await storage.recordUsage('squat');

    await storage.clear();

    expect(await storage.favorites(), isEmpty);
    expect(await storage.recents(), isEmpty);
    expect(await storage.usageCounts(), isEmpty);
    expect(await storage.mostUsed(), isEmpty);
  });
}