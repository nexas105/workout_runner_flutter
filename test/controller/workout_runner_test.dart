import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _buildPlan({String id = 'plan_test', String name = 'Test plan'}) {
  return WorkoutPlan(
    id: id,
    name: name,
    exercises: const [
      WorkoutExercise(
        id: 'ex_bench',
        name: 'Bench press',
        category: ExerciseCategory(id: 'cat_strength', name: 'Strength'),
        muscles: [Muscle(id: 'm_chest', name: 'Chest', group: 'upper')],
        sets: [
          WorkoutSet(
            targetReps: 8,
            targetWeight: 60,
            rest: Duration(seconds: 60),
          ),
          WorkoutSet(
            targetReps: 8,
            targetWeight: 60,
            rest: Duration(seconds: 60),
          ),
        ],
      ),
      WorkoutExercise(
        id: 'ex_pullups',
        name: 'Pull-ups',
        sets: [WorkoutSet(targetReps: 10, rest: Duration(seconds: 60))],
      ),
    ],
  );
}

void main() {
  late InMemoryRunnerStorage storage;
  late WorkoutRunner runner;

  setUp(() {
    storage = InMemoryRunnerStorage();
    runner = WorkoutRunner(storage: storage);
  });

  tearDown(() {
    runner.dispose();
  });

  group('construction', () {
    test('can be constructed with InMemoryRunnerStorage', () {
      expect(runner.isRunning, isFalse);
      expect(runner.plan, isNull);
      expect(runner.state, isNull);
      expect(runner.elapsed, Duration.zero);
    });
  });

  group('start', () {
    test('initialises state, persists, and notifies listeners', () async {
      var notifyCount = 0;
      runner.addListener(() => notifyCount++);

      final plan = _buildPlan();
      await runner.start(plan);

      expect(runner.isRunning, isTrue);
      expect(runner.plan?.id, plan.id);
      expect(runner.state, isNotNull);
      expect(runner.state!.planId, plan.id);
      expect(runner.state!.currentExerciseIndex, 0);
      expect(runner.state!.activeExerciseIndex, isNull);
      expect(runner.state!.currentSetIndex, 0);
      expect(runner.state!.performed, isEmpty);
      expect(notifyCount, greaterThan(0));

      final storedState = await storage.readState();
      final storedPlan = await storage.readPlan();
      expect(storedState, isNotNull);
      expect(storedState!['planId'], plan.id);
      expect(storedPlan, isNotNull);
      expect(storedPlan!['id'], plan.id);
    });

    test('same plan + resumeIfPossible reuses existing state', () async {
      final plan = _buildPlan();
      await runner.start(plan);
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(
        reps: 10,
        weight: 50,
        rir: 1,
        rest: Duration.zero,
      );

      final startedAtBefore = runner.state!.startedAt;
      final performedBefore = runner.state!.performed.length;
      expect(performedBefore, 1);

      await runner.start(plan, resumeIfPossible: true);

      expect(runner.isRunning, isTrue);
      expect(runner.state!.startedAt, startedAtBefore);
      expect(runner.state!.performed.length, performedBefore);
      expect(runner.getPerformedSet(0, 0), isNotNull);
    });

    test(
      'a different plan resets state even when resumeIfPossible is true',
      () async {
        final planA = _buildPlan(id: 'plan_a');
        await runner.start(planA);
        runner.setActiveExercise(0);
        runner.startSet(0, 0);
        await runner.finishCurrentSet(
          reps: 10,
          weight: 50,
          rest: Duration.zero,
        );
        expect(runner.state!.performed, isNotEmpty);

        final planB = _buildPlan(id: 'plan_b', name: 'Other');
        await runner.start(planB, resumeIfPossible: true);

        expect(runner.plan?.id, 'plan_b');
        expect(runner.state!.planId, 'plan_b');
        expect(runner.state!.performed, isEmpty);
        expect(runner.state!.activeExerciseIndex, isNull);
      },
    );
  });

  group('exercise activation and sets', () {
    test('setActiveExercise sets the active index', () async {
      await runner.start(_buildPlan());

      runner.setActiveExercise(0);

      expect(runner.activeExerciseIndex, 0);
      expect(runner.hasActiveExercise, isTrue);
    });

    test('showExercise calls onExerciseChanged', () async {
      await runner.start(_buildPlan());
      int? changedTo;
      runner.onExerciseChanged = (index) => changedTo = index;

      runner.showExercise(1);

      expect(changedTo, 1);
      expect(runner.currentExerciseIndex, 1);
    });

    test('startSet then finishCurrentSet records a performed set', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);
      PerformedSet? callbackSet;
      Duration? restStarted;
      runner.onSetCompleted = (set) => callbackSet = set;
      runner.onRestStarted = (rest) => restStarted = rest;

      final started = runner.startSet(0, 0);
      expect(started, isTrue);
      expect(runner.isSetRunning, isTrue);

      final ok = await runner.finishCurrentSet(
        reps: 10,
        weight: 50,
        rir: 1,
        rest: Duration.zero,
      );

      expect(ok, isTrue);
      expect(runner.isSetRunning, isFalse);

      final performed = runner.getPerformedSet(0, 0);
      expect(performed, isNotNull);
      expect(performed!.exerciseIndex, 0);
      expect(performed.setIndex, 0);
      expect(performed.actualReps, 10);
      expect(performed.actualWeight, 50);
      expect(performed.rir, 1);
      expect(performed.pause, Duration.zero);
      expect(callbackSet, same(performed));
      expect(restStarted, isNull);
    });

    test(
      'logSet returns false for out-of-range indices instead of throwing',
      () async {
        await runner.start(_buildPlan());

        final ok = await runner.logSet(
          exerciseIndex: 99,
          setIndex: 0,
          reps: 10,
        );

        expect(ok, isFalse);
      },
    );

    test('onRestStarted is called when finishing a set with rest', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      Duration? restStarted;
      runner.onRestStarted = (rest) => restStarted = rest;

      await runner.finishCurrentSet(reps: 8, rest: const Duration(seconds: 30));

      expect(restStarted, const Duration(seconds: 30));
      expect(runner.isResting, isTrue);
    });

    test('finishCurrentSet returns false when no set is active', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);

      final ok = await runner.finishCurrentSet(reps: 5, rest: Duration.zero);

      expect(ok, isFalse);
      expect(runner.getPerformedSet(0, 0), isNull);
    });

    test(
      'getPerformedSet returns null for sets that have not been performed',
      () async {
        await runner.start(_buildPlan());
        runner.setActiveExercise(0);
        runner.startSet(0, 0);
        await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

        expect(runner.getPerformedSet(0, 0), isNotNull);
        expect(runner.getPerformedSet(0, 1), isNull);
        expect(runner.getPerformedSet(1, 0), isNull);
      },
    );
  });

  group('timed sets', () {
    WorkoutPlan timedPlan() => const WorkoutPlan(
      id: 'timed_plan',
      name: 'Timed',
      exercises: [
        WorkoutExercise(
          id: 'ex_plank',
          name: 'Plank',
          sets: [
            WorkoutSet(
              targetReps: 0,
              type: SetType.timed,
              targetDuration: Duration(seconds: 30),
            ),
          ],
        ),
        WorkoutExercise(
          id: 'ex_bench',
          name: 'Bench',
          sets: [WorkoutSet(targetReps: 8, targetWeight: 60)],
        ),
      ],
    );

    test(
      'exposes target duration and remaining for the active timed set',
      () async {
        await runner.start(timedPlan());
        runner.setActiveExercise(0);
        runner.startSet(0, 0);

        expect(runner.isCurrentSetTimed, isTrue);
        expect(runner.currentSetTargetDuration, const Duration(seconds: 30));
        // _setElapsed is 0 right after startSet — remaining equals target.
        expect(runner.currentSetRemaining, const Duration(seconds: 30));
        expect(runner.currentActiveSet?.type, SetType.timed);
      },
    );

    test('accessors fall back to defaults for non-timed sets', () async {
      await runner.start(timedPlan());
      runner.setActiveExercise(1);
      runner.startSet(1, 0);

      expect(runner.isCurrentSetTimed, isFalse);
      expect(runner.currentSetTargetDuration, isNull);
      expect(runner.currentSetRemaining, Duration.zero);
    });

    test('PerformedSet inherits the type from the WorkoutSet', () async {
      await runner.start(timedPlan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 0, rest: Duration.zero);

      final logged = runner.getPerformedSet(0, 0);
      expect(logged?.type, SetType.timed);
    });
  });

  group('pause / resume', () {
    test('pause stops the runner and fires onPaused', () async {
      await runner.start(_buildPlan());
      var paused = 0;
      runner.onPaused = () => paused++;

      await runner.pause();

      expect(runner.isPaused, isTrue);
      expect(runner.isRunning, isFalse);
      expect(paused, 1);
    });

    test('resume restarts the runner and reports the paused delta', () async {
      await runner.start(_buildPlan());
      await runner.pause();

      Duration? delta;
      runner.onResumed = (d) => delta = d;

      await Future<void>.delayed(const Duration(milliseconds: 30));
      await runner.resume();

      expect(runner.isRunning, isTrue);
      expect(runner.isPaused, isFalse);
      expect(delta, isNotNull);
      expect(delta! >= const Duration(milliseconds: 25), isTrue);
    });

    test('pause is a no-op when not running', () async {
      var paused = 0;
      runner.onPaused = () => paused++;

      await runner.pause();

      expect(paused, 0);
    });
  });

  group('rest hooks', () {
    test('skipRest fires onRestSkipped only when a rest is active', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);

      var skipped = 0;
      runner.onRestSkipped = () => skipped++;

      runner.skipRest();
      expect(skipped, 0);

      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: const Duration(seconds: 30));
      expect(runner.isResting, isTrue);

      runner.skipRest();
      expect(skipped, 1);
      expect(runner.isResting, isFalse);
    });

    test('extendRest grows remaining and restTotal', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: const Duration(seconds: 30));

      expect(runner.restTotal, const Duration(seconds: 30));

      runner.extendRest(const Duration(seconds: 15));
      expect(runner.restTotal, const Duration(seconds: 45));
      expect(
        runner.restRemaining,
        greaterThanOrEqualTo(const Duration(seconds: 30)),
      );
    });

    test('extendRest is a no-op without an active rest', () async {
      await runner.start(_buildPlan());
      runner.extendRest(const Duration(seconds: 10));
      expect(runner.isResting, isFalse);
      expect(runner.restTotal, Duration.zero);
    });
  });

  group('cancel', () {
    test('cancel clears storage and in-memory state', () async {
      await runner.start(_buildPlan());
      expect(runner.isRunning, isTrue);
      expect(await storage.readState(), isNotNull);

      await runner.cancel();

      expect(runner.isRunning, isFalse);
      expect(runner.plan, isNull);
      expect(runner.state, isNull);
      expect(runner.elapsed, Duration.zero);
      expect(await storage.readState(), isNull);
      expect(await storage.readPlan(), isNull);
    });
  });

  group('finish', () {
    test(
      'emits on finished stream, invokes onFinished, and returns a result',
      () async {
        WorkoutResult? callbackResult;
        runner.onFinished = (r) => callbackResult = r;
        final streamFuture = runner.finished.first;

        final plan = _buildPlan();
        await runner.start(plan);
        runner.setActiveExercise(0);
        runner.startSet(0, 0);
        await runner.finishCurrentSet(reps: 8, weight: 60, rest: Duration.zero);

        final result = await runner.finish();
        final streamResult = await streamFuture;

        expect(result, isNotNull);
        expect(result!.planId, plan.id);
        expect(result.exercises.length, 1);
        expect(result.exercises.first.exerciseId, 'ex_bench');
        expect(result.exercises.first.exerciseName, 'Bench press');
        expect(result.exercises.first.sets.length, 1);
        expect(result.exercises.first.sets.first.actualReps, 8);
        expect(result.exercises.first.sets.first.actualWeight, 60);
        expect(result.totalSets, 1);
        expect(result.totalReps, 8);
        expect(result.totalVolume, 480.0);

        expect(callbackResult, same(result));
        expect(streamResult.planId, plan.id);

        // Storage is cleared.
        expect(await storage.readState(), isNull);
        expect(await storage.readPlan(), isNull);
      },
    );

    test(
      'timers do not leak: after finish, isRunning is false and elapsed is zero',
      () async {
        await runner.start(_buildPlan());
        runner.setActiveExercise(0);
        runner.startSet(0, 0);
        await runner.finishCurrentSet(reps: 8, rest: Duration.zero);

        await runner.finish();

        expect(runner.isRunning, isFalse);
        expect(runner.elapsed, Duration.zero);
        expect(runner.isSetRunning, isFalse);
        expect(runner.isResting, isFalse);
        expect(runner.plan, isNull);
        expect(runner.state, isNull);
      },
    );

    test('finish returns null when no workout is active', () async {
      final result = await runner.finish();
      expect(result, isNull);
    });
  });

  group('tryAutoResume', () {
    test('restores an active workout from storage', () async {
      // Pre-populate storage with state + plan from a finished session-in-progress.
      final plan = _buildPlan(id: 'plan_resume');
      final now = DateTime.now().subtract(const Duration(minutes: 3));
      final state = WorkoutRunnerState(
        planId: plan.id,
        currentExerciseIndex: 0,
        activeExerciseIndex: 0,
        currentSetIndex: 1,
        isActive: true,
        startedAt: now,
        updatedAt: now,
        performed: const [],
      );
      await storage.saveState(state.toJson());
      await storage.savePlan(plan.toJson());

      // Use a fresh runner sharing the same storage.
      final fresh = WorkoutRunner(storage: storage);
      addTearDown(fresh.dispose);

      final resumed = await fresh.tryAutoResume();

      expect(resumed, isTrue);
      expect(fresh.isRunning, isTrue);
      expect(fresh.plan?.id, plan.id);
      expect(fresh.state?.activeExerciseIndex, 0);
      expect(fresh.state?.currentSetIndex, 1);
    });

    test('returns false when storage is empty', () async {
      final fresh = WorkoutRunner(storage: storage);
      addTearDown(fresh.dispose);

      expect(await fresh.tryAutoResume(), isFalse);
      expect(fresh.isRunning, isFalse);
    });

    test('restores a paused session without restarting the timer', () async {
      final plan = _buildPlan();
      final now = DateTime.now();
      final inactive = WorkoutRunnerState(
        planId: plan.id,
        currentExerciseIndex: 0,
        activeExerciseIndex: null,
        currentSetIndex: 0,
        isActive: false,
        startedAt: now,
        updatedAt: now,
        performed: const [],
      );
      await storage.saveState(inactive.toJson());
      await storage.savePlan(plan.toJson());

      final fresh = WorkoutRunner(storage: storage);
      addTearDown(fresh.dispose);

      expect(await fresh.tryAutoResume(), isTrue);
      expect(fresh.isRunning, isFalse);
      expect(fresh.isPaused, isTrue);
      expect(fresh.plan?.id, plan.id);
    });
  });

  group('plan mutation', () {
    test('canStart uses plan validation', () {
      final valid = _buildPlan();
      const invalid = WorkoutPlan(id: '', name: '', exercises: []);

      expect(runner.canStart(valid), isTrue);
      expect(runner.canStart(invalid), isFalse);
    });

    test('addSetToExercise appends a set to the targeted exercise', () async {
      final plan = _buildPlan();
      await runner.start(plan);
      final originalCount = runner.plan!.exercises[0].sets.length;

      final ok = await runner.addSetToExercise(
        0,
        targetReps: 12,
        targetWeight: 55,
      );

      expect(ok, isTrue);
      expect(runner.plan!.exercises[0].sets.length, originalCount + 1);
      final added = runner.plan!.exercises[0].sets.last;
      expect(added.targetReps, 12);
      expect(added.targetWeight, 55);
    });

    test(
      'addSetToExercise returns false for out-of-range exercise index',
      () async {
        await runner.start(_buildPlan());

        expect(await runner.addSetToExercise(99), isFalse);
      },
    );

    test('removeSetFromExercise removes a non-performed set', () async {
      await runner.start(_buildPlan());
      final originalCount = runner.plan!.exercises[0].sets.length;

      final ok = await runner.removeSetFromExercise(0, 1);

      expect(ok, isTrue);
      expect(runner.plan!.exercises[0].sets.length, originalCount - 1);
    });

    test('removeSetFromExercise refuses to remove a performed set', () async {
      await runner.start(_buildPlan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);
      await runner.finishCurrentSet(reps: 8, rest: Duration.zero);
      final beforeCount = runner.plan!.exercises[0].sets.length;

      final ok = await runner.removeSetFromExercise(0, 0);

      expect(ok, isFalse);
      expect(runner.plan!.exercises[0].sets.length, beforeCount);
      expect(runner.getPerformedSet(0, 0), isNotNull);
    });

    test(
      'removeSetFromExercise returns false for out-of-range set index',
      () async {
        await runner.start(_buildPlan());

        expect(await runner.removeSetFromExercise(0, 99), isFalse);
      },
    );
  });
}
