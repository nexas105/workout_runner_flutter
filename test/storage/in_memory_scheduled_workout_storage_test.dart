import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryScheduledWorkoutStorage storage;

  ScheduledWorkout entry(String id, DateTime at, {String planId = 'p'}) {
    return ScheduledWorkout(id: id, planId: planId, scheduledAt: at);
  }

  setUp(() {
    storage = InMemoryScheduledWorkoutStorage();
  });

  test('upsert / read round-trip', () async {
    final s = entry('a', DateTime(2026, 5, 21, 18));
    await storage.upsert(s);

    final back = await storage.read('a');
    expect(back, isNotNull);
    expect(back!.id, 'a');
    expect(back.scheduledAt, s.scheduledAt);
  });

  test('upsert replaces existing entry by id', () async {
    await storage.upsert(entry('a', DateTime(2026, 5, 21)));
    await storage.upsert(entry('a', DateTime(2026, 5, 22)));

    final back = await storage.read('a');
    expect(back!.scheduledAt, DateTime(2026, 5, 22));
    expect((await storage.all()).length, 1);
  });

  test('read returns null for unknown id', () async {
    expect(await storage.read('nope'), isNull);
  });

  test('all() is sorted ascending by scheduledAt', () async {
    await storage.upsert(entry('c', DateTime(2026, 5, 23)));
    await storage.upsert(entry('a', DateTime(2026, 5, 21)));
    await storage.upsert(entry('b', DateTime(2026, 5, 22)));

    expect((await storage.all()).map((e) => e.id), ['a', 'b', 'c']);
  });

  test('remove deletes by id', () async {
    await storage.upsert(entry('a', DateTime(2026, 5, 21)));
    await storage.upsert(entry('b', DateTime(2026, 5, 22)));

    await storage.remove('a');
    expect(await storage.read('a'), isNull);
    expect((await storage.all()).map((e) => e.id), ['b']);
  });

  test('remove of missing id is a no-op', () async {
    await storage.upsert(entry('a', DateTime(2026, 5, 21)));
    await storage.remove('nope');
    expect((await storage.all()).map((e) => e.id), ['a']);
  });

  test('clear wipes all entries', () async {
    await storage.upsert(entry('a', DateTime(2026, 5, 21)));
    await storage.upsert(entry('b', DateTime(2026, 5, 22)));

    await storage.clear();
    expect(await storage.all(), isEmpty);
    expect(await storage.read('a'), isNull);
  });
}