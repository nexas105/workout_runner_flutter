import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutResult _workout({required DateTime finishedAt, String id = 'p'}) =>
    WorkoutResult(
      planId: id,
      startedAt: finishedAt.subtract(const Duration(minutes: 30)),
      finishedAt: finishedAt,
      duration: const Duration(minutes: 30),
      exercises: const [],
    );

CardioResult _cardio({required DateTime finishedAt, String id = 'c'}) =>
    CardioResult(
      planId: id,
      planName: id,
      discipline: CardioDiscipline.running,
      startedAt: finishedAt.subtract(const Duration(minutes: 20)),
      finishedAt: finishedAt,
      duration: const Duration(minutes: 20),
      laps: const [],
    );

void main() {
  late InMemoryPagedHistoryStorage history;

  setUp(() {
    history = InMemoryPagedHistoryStorage();
  });

  test('pages through 250 workouts in 5 pages of 50, newest-first', () async {
    final base = DateTime.utc(2026, 1, 1);
    for (var i = 0; i < 250; i++) {
      await history.saveWorkout(
        _workout(
          finishedAt: base.add(Duration(minutes: i)),
          id: 'w${i.toString().padLeft(3, '0')}',
        ),
      );
    }

    final collected = <String>[];
    String? cursor;
    var pages = 0;
    HistoryPage<WorkoutResult> page;
    do {
      page = await history.pagedWorkouts(limit: 50, cursor: cursor);
      pages++;
      collected.addAll(page.items.map((r) => r.planId));
      cursor = page.nextCursor;
    } while (page.hasMore);

    expect(pages, 5);
    expect(page.hasMore, isFalse);
    expect(collected.length, 250);
    expect(collected.first, 'w249');
    expect(collected.last, 'w000');
    expect(collected, equals(collected.toSet().toList()));
    expect(page.totalCount, 250);
  });

  test('hasMore is false when last page is partial', () async {
    final base = DateTime.utc(2026, 1, 1);
    for (var i = 0; i < 7; i++) {
      await history.saveWorkout(
        _workout(finishedAt: base.add(Duration(minutes: i)), id: 'w$i'),
      );
    }

    final p1 = await history.pagedWorkouts(limit: 5);
    expect(p1.items.length, 5);
    expect(p1.hasMore, isTrue);

    final p2 = await history.pagedWorkouts(limit: 5, cursor: p1.nextCursor);
    expect(p2.items.length, 2);
    expect(p2.hasMore, isFalse);
    expect(p2.nextCursor, isNull);
  });

  test('since filter is applied at page granularity', () async {
    final pivot = DateTime.utc(2026, 5, 20);
    for (var i = -3; i < 4; i++) {
      await history.saveWorkout(
        _workout(finishedAt: pivot.add(Duration(days: i)), id: 'd$i'),
      );
    }

    final page = await history.pagedWorkouts(limit: 50, since: pivot);
    expect(page.items.map((r) => r.planId).toList(), ['d3', 'd2', 'd1']);
    expect(page.totalCount, 3);
    expect(page.hasMore, isFalse);

    expect(await history.workoutCountSince(pivot), 3);
    expect(await history.workoutCountSince(null), 7);
  });

  test('cursor encoding is opaque base64', () async {
    final base = DateTime.utc(2026, 1, 1);
    for (var i = 0; i < 3; i++) {
      await history.saveWorkout(
        _workout(finishedAt: base.add(Duration(minutes: i)), id: 'w$i'),
      );
    }

    final page = await history.pagedWorkouts(limit: 1);
    expect(page.nextCursor, isNotNull);
    expect(int.tryParse(page.nextCursor!), isNull);
  });

  test('cardio pages independently of workouts', () async {
    final base = DateTime.utc(2026, 1, 1);
    for (var i = 0; i < 5; i++) {
      await history.saveCardio(
        _cardio(finishedAt: base.add(Duration(minutes: i)), id: 'c$i'),
      );
    }

    final page = await history.pagedCardio(limit: 2);
    expect(page.items.map((r) => r.planId).toList(), ['c4', 'c3']);
    expect(page.totalCount, 5);
    expect(page.hasMore, isTrue);

    final tail = await history.pagedCardio(limit: 10, cursor: page.nextCursor);
    expect(tail.items.map((r) => r.planId).toList(), ['c2', 'c1', 'c0']);
    expect(tail.hasMore, isFalse);
  });

  test('still satisfies the eager WorkoutHistoryStorage contract', () async {
    final WorkoutHistoryStorage eager = history;
    await eager.saveWorkout(_workout(finishedAt: DateTime.utc(2026, 1, 1)));
    await eager.saveCardio(_cardio(finishedAt: DateTime.utc(2026, 1, 2)));

    expect((await eager.recentWorkouts()).length, 1);
    expect((await eager.recentCardio()).length, 1);

    await eager.clear();
    expect(history.workoutCount, 0);
    expect(history.cardioCount, 0);
  });
}
