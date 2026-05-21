import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

CardioPlan _buildCardioPlan() => const CardioPlan(
  id: 'cardio_test',
  name: 'Cardio test',
  intervals: [
    CardioInterval(
      id: 'warmup',
      name: 'Warm up',
      phase: CardioPhase.warmup,
      targetDuration: Duration(minutes: 5),
    ),
    CardioInterval(
      id: 'work',
      name: 'Work',
      phase: CardioPhase.work,
      targetDuration: Duration(minutes: 1),
    ),
  ],
);

void main() {
  late InMemoryRunnerStorage storage;
  late CardioRunner runner;

  setUp(() {
    storage = InMemoryRunnerStorage();
    runner = CardioRunner(storage: storage);
  });

  tearDown(() {
    runner.dispose();
  });

  group('CardioRunner callbacks', () {
    test('onIntervalCompleted receives the recorded lap', () async {
      CardioLap? callbackLap;
      runner.onIntervalCompleted = (lap) => callbackLap = lap;

      await runner.start(_buildCardioPlan());
      final lap = await runner.completeInterval(
        duration: const Duration(minutes: 5),
        distanceMeters: 1000,
      );

      expect(lap, isNotNull);
      expect(callbackLap, same(lap));
      expect(runner.laps.single.distanceMeters, 1000);
      expect(runner.currentIntervalIndex, 1);
    });

    test('onPaused and onResumed are called after state changes', () async {
      var paused = 0;
      var resumed = 0;
      runner.onPaused = () => paused++;
      runner.onResumed = () => resumed++;

      await runner.start(_buildCardioPlan());
      await runner.pause();
      await runner.resume();

      expect(paused, 1);
      expect(resumed, 1);
      expect(runner.isRunning, isTrue);
    });
  });
}
