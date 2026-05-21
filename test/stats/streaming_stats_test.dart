import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutResult _workout({
  required DateTime finishedAt,
  required String id,
  required int setCount,
  required double weight,
  required int reps,
}) {
  final sets = [
    for (var i = 0; i < setCount; i++)
      PerformedSet(
        exerciseIndex: 0,
        setIndex: i,
        actualReps: reps,
        actualWeight: weight,
        completedAt: finishedAt,
      ),
  ];
  return WorkoutResult(
    planId: id,
    startedAt: finishedAt.subtract(const Duration(minutes: 30)),
    finishedAt: finishedAt,
    duration: const Duration(minutes: 30),
    exercises: [
      PerformedExerciseDetails(
        exerciseId: 'ex_squat',
        exerciseName: 'Squat',
        sets: sets,
      ),
    ],
  );
}

void main() {
  late InMemoryPagedHistoryStorage history;

  setUp(() {
    history = InMemoryPagedHistoryStorage();
  });

  test('totalVolume matches sum of WorkoutResult.totalVolume across pages',
      () async {
    final base = DateTime.utc(2026, 1, 1);
    var expected = 0.0;
    for (var i = 0; i < 120; i++) {
      final r = _workout(
        finishedAt: base.add(Duration(minutes: i)),
        id: 'w$i',
        setCount: 3,
        weight: 50.0 + i,
        reps: 5,
      );
      await history.saveWorkout(r);
      expected += r.totalVolume;
    }

    final streamed = await StreamingStats.totalVolume(history, pageSize: 25);
    expect(streamed, closeTo(expected, 1e-9));
  });

  test('totalSets sums every performed set newest-first', () async {
    final base = DateTime.utc(2026, 1, 1);
    for (var i = 0; i < 10; i++) {
      await history.saveWorkout(
        _workout(
          finishedAt: base.add(Duration(minutes: i)),
          id: 'w$i',
          setCount: 4,
          weight: 60,
          reps: 6,
        ),
      );
    }

    final total = await StreamingStats.totalSets(history, pageSize: 3);
    expect(total, 10 * 4);
  });

  test('walk yields results newest-first across many pages', () async {
    final base = DateTime.utc(2026, 1, 1);
    for (var i = 0; i < 25; i++) {
      await history.saveWorkout(
        _workout(
          finishedAt: base.add(Duration(minutes: i)),
          id: 'w${i.toString().padLeft(2, '0')}',
          setCount: 1,
          weight: 10,
          reps: 1,
        ),
      );
    }

    final order = <String>[];
    await for (final r in StreamingStats.walk(history, pageSize: 4)) {
      order.add(r.planId);
    }

    expect(order.length, 25);
    expect(order.first, 'w24');
    expect(order.last, 'w00');
    final sorted = [...order]..sort((a, b) => b.compareTo(a));
    expect(order, equals(sorted));
  });

  test('since filter is honoured by walk and totalVolume', () async {
    final pivot = DateTime.utc(2026, 5, 20);
    final before = _workout(
      finishedAt: pivot.subtract(const Duration(days: 1)),
      id: 'before',
      setCount: 5,
      weight: 100,
      reps: 5,
    );
    final after1 = _workout(
      finishedAt: pivot.add(const Duration(days: 1)),
      id: 'after1',
      setCount: 2,
      weight: 50,
      reps: 4,
    );
    final after2 = _workout(
      finishedAt: pivot.add(const Duration(days: 2)),
      id: 'after2',
      setCount: 3,
      weight: 40,
      reps: 3,
    );
    await history.saveWorkout(before);
    await history.saveWorkout(after1);
    await history.saveWorkout(after2);

    final ids = <String>[];
    await for (final r in StreamingStats.walk(history, since: pivot)) {
      ids.add(r.planId);
    }
    expect(ids, ['after2', 'after1']);

    final volume = await StreamingStats.totalVolume(history, since: pivot);
    expect(volume, closeTo(after1.totalVolume + after2.totalVolume, 1e-9));
  });

  test('empty history yields zero totals and no walk emissions', () async {
    expect(await StreamingStats.totalVolume(history), 0.0);
    expect(await StreamingStats.totalSets(history), 0);
    expect(await StreamingStats.walk(history).toList(), isEmpty);
  });
}
