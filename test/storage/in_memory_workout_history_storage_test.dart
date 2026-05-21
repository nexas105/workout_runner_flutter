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
  late InMemoryWorkoutHistoryStorage history;

  setUp(() {
    history = InMemoryWorkoutHistoryStorage();
  });

  test('saves and returns workouts newest-first', () async {
    final a = _workout(finishedAt: DateTime.utc(2026, 5, 19), id: 'a');
    final b = _workout(finishedAt: DateTime.utc(2026, 5, 21), id: 'b');
    final c = _workout(finishedAt: DateTime.utc(2026, 5, 20), id: 'c');
    await history.saveWorkout(a);
    await history.saveWorkout(b);
    await history.saveWorkout(c);

    final recent = await history.recentWorkouts();
    expect(recent.map((r) => r.planId).toList(), ['b', 'c', 'a']);
  });

  test('respects the limit cap', () async {
    for (var i = 0; i < 5; i++) {
      await history.saveWorkout(
        _workout(finishedAt: DateTime.utc(2026, 5, 20 + i), id: 'w$i'),
      );
    }

    final top2 = await history.recentWorkouts(limit: 2);
    expect(top2.length, 2);
    expect(top2.first.planId, 'w4');
  });

  test('since is a strict lower bound', () async {
    final pivot = DateTime.utc(2026, 5, 20);
    await history.saveWorkout(
      _workout(finishedAt: pivot.subtract(const Duration(days: 1))),
    );
    await history.saveWorkout(_workout(finishedAt: pivot, id: 'on_pivot'));
    await history.saveWorkout(
      _workout(finishedAt: pivot.add(const Duration(days: 1)), id: 'after'),
    );

    final after = await history.recentWorkouts(since: pivot);
    expect(after.map((r) => r.planId).toList(), ['after']);
  });

  test('cardio sink is isolated from workout sink', () async {
    await history.saveWorkout(_workout(finishedAt: DateTime.utc(2026, 5, 20)));
    await history.saveCardio(_cardio(finishedAt: DateTime.utc(2026, 5, 21)));

    expect((await history.recentWorkouts()).length, 1);
    expect((await history.recentCardio()).length, 1);
  });

  test('clear empties both sinks', () async {
    await history.saveWorkout(_workout(finishedAt: DateTime.utc(2026, 5, 20)));
    await history.saveCardio(_cardio(finishedAt: DateTime.utc(2026, 5, 21)));

    await history.clear();

    expect(history.workoutCount, 0);
    expect(history.cardioCount, 0);
  });
}
