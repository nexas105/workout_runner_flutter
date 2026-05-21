import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingHaptics extends RunnerHaptics {
  int setStartedCount = 0;
  int setCompletedCount = 0;
  int restTickCountdownCount = 0;
  int restCompletedCount = 0;
  int restSkippedCount = 0;
  int timedTargetReachedCount = 0;
  int workoutFinishedCount = 0;
  int prAchievedCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;

  @override
  void setStarted() => setStartedCount++;

  @override
  void setCompleted() => setCompletedCount++;

  @override
  void restTickCountdown() => restTickCountdownCount++;

  @override
  void restCompleted() => restCompletedCount++;

  @override
  void restSkipped() => restSkippedCount++;

  @override
  void timedTargetReached() => timedTargetReachedCount++;

  @override
  void workoutFinished() => workoutFinishedCount++;

  @override
  void prAchieved() => prAchievedCount++;

  @override
  void pause() => pauseCount++;

  @override
  void resume() => resumeCount++;
}

WorkoutPlan _buildPlan() {
  return const WorkoutPlan(
    id: 'plan_haptics',
    name: 'Haptics plan',
    exercises: [
      WorkoutExercise(
        id: 'ex_bench',
        name: 'Bench press',
        sets: [
          WorkoutSet(targetReps: 8, rest: Duration(seconds: 30)),
          WorkoutSet(targetReps: 8, rest: Duration(seconds: 30)),
        ],
      ),
    ],
  );
}

void main() {
  group('NoOpRunnerHaptics', () {
    test('is non-null and every method is a safe no-op', () {
      const haptics = NoOpRunnerHaptics();
      expect(haptics, isNotNull);
      expect(() {
        haptics.setStarted();
        haptics.setCompleted();
        haptics.restTickCountdown();
        haptics.restCompleted();
        haptics.restSkipped();
        haptics.timedTargetReached();
        haptics.workoutFinished();
        haptics.prAchieved();
        haptics.pause();
        haptics.resume();
      }, returnsNormally);
    });
  });

  group('RunnerHapticsBridge.wire', () {
    late InMemoryRunnerStorage storage;
    late WorkoutRunner runner;
    late _CountingHaptics haptics;

    setUp(() {
      storage = InMemoryRunnerStorage();
      runner = WorkoutRunner(storage: storage);
      haptics = _CountingHaptics();
      RunnerHapticsBridge.wire(runner, haptics);
    });

    tearDown(() {
      runner.dispose();
    });

    test('setCompleted fires when a set is finished', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);

      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

      expect(haptics.setCompletedCount, 1);
    });

    test(
      'restTickCountdown fires exactly once per rest, when remaining '
      'drops under the threshold',
      () async {
        await runner.start(_buildPlan());
        runner.setActiveExercise(0);
        runner.startSet(0, 0);
        await runner.finishCurrentSet(
          reps: 8,
          rest: const Duration(seconds: 30),
        );

        // Above threshold — nothing yet.
        runner.onRestTick!(const Duration(seconds: 10));
        runner.onRestTick!(const Duration(seconds: 5));
        runner.onRestTick!(const Duration(seconds: 4));
        expect(haptics.restTickCountdownCount, 0);

        // Drop into threshold — fires once.
        runner.onRestTick!(const Duration(seconds: 3));
        expect(haptics.restTickCountdownCount, 1);

        // Further ticks inside threshold do not refire.
        runner.onRestTick!(const Duration(seconds: 2));
        runner.onRestTick!(const Duration(seconds: 1));
        expect(haptics.restTickCountdownCount, 1);

        // Remaining-zero tick is treated as "rest complete", not a countdown.
        runner.onRestTick!(Duration.zero);
        expect(haptics.restTickCountdownCount, 1);
      },
    );

    test('countdown flag resets between rest periods', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);

      runner.startSet(0, 0);
      await runner.finishCurrentSet(
        reps: 8,
        rest: const Duration(seconds: 30),
      );
      runner.onRestTick!(const Duration(seconds: 2));
      expect(haptics.restTickCountdownCount, 1);
      runner.skipRest();

      runner.startSet(0, 1);
      await runner.finishCurrentSet(
        reps: 8,
        rest: const Duration(seconds: 30),
      );
      runner.onRestTick!(const Duration(seconds: 2));
      expect(haptics.restTickCountdownCount, 2);
    });

    test(
      'short rest (<= tickAt) fires restTickCountdown immediately on '
      'restStarted',
      () async {
        await runner.start(_buildPlan());
        runner.setActiveExercise(0);
        runner.startSet(0, 0);
        await runner.finishCurrentSet(
          reps: 8,
          rest: const Duration(seconds: 2),
        );

        expect(haptics.restTickCountdownCount, 1);
      },
    );

    test('restSkipped fires when skipRest is called', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(
        reps: 8,
        rest: const Duration(seconds: 30),
      );

      runner.skipRest();

      expect(haptics.restSkippedCount, 1);
    });

    test('pause / resume route to haptics', () async {
      await runner.start(_buildPlan());

      await runner.pause();
      expect(haptics.pauseCount, 1);

      await runner.resume();
      expect(haptics.resumeCount, 1);
    });

    test('workoutFinished fires once on finish', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);
      runner.startSet(0, 1);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

      await runner.finish();

      expect(haptics.workoutFinishedCount, 1);
    });

    test('second wire() replaces the previous wiring (idempotent)', () async {
      final other = _CountingHaptics();
      RunnerHapticsBridge.wire(runner, other);

      await runner.start(_buildPlan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

      expect(haptics.setCompletedCount, 0);
      expect(other.setCompletedCount, 1);
    });
  });

  group('RunnerHapticsBridge.wireCardio', () {
    test('routes interval, pause, resume, finished onto haptics', () async {
      final runner = CardioRunner(storage: InMemoryRunnerStorage());
      final haptics = _CountingHaptics();
      RunnerHapticsBridge.wireCardio(runner, haptics);

      final now = DateTime.now();
      runner.onIntervalCompleted?.call(
        CardioLap(
          intervalIndex: 0,
          duration: const Duration(seconds: 30),
          completedAt: now,
        ),
      );
      runner.onPaused?.call();
      runner.onResumed?.call();
      runner.onFinished?.call(
        CardioResult(
          planId: 'p',
          planName: 'p',
          discipline: CardioDiscipline.mixed,
          startedAt: now,
          finishedAt: now,
          duration: const Duration(seconds: 30),
          laps: const [],
        ),
      );

      expect(haptics.setCompletedCount, 1);
      expect(haptics.pauseCount, 1);
      expect(haptics.resumeCount, 1);
      expect(haptics.workoutFinishedCount, 1);
      runner.dispose();
    });
  });
}
