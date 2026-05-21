# Architecture

`fitness_workout` is a Flutter package for running strength workouts: a
`ChangeNotifier` controller (`WorkoutRunner`) owns the active plan, the timers
and the performed sets; a pluggable `RunnerStorage` persists state and plan
JSON to whatever backend you supply; a stack of widgets reads the controller
via an `InheritedNotifier` (`RunnerScope`) and rebuilds on every
notification. There is no global singleton — you instantiate one runner per
session (or several, keyed by storage `slot`) and you own its lifecycle.

Related docs: [API.md](API.md) · [WIDGETS.md](WIDGETS.md) ·
[STORAGE.md](STORAGE.md) · [THEMING.md](THEMING.md) ·
[MIGRATION.md](MIGRATION.md).

## Layers

```
+------------------------------------------------------+
|                    Your Flutter app                  |
|  (MaterialApp, Navigator, your screens, your data)   |
+--------------------------+---------------------------+
                           |
                  embeds + provides
                           v
+------------------------------------------------------+
|              Bundled widgets (UI layer)              |
|   Strength: RunnerScreen, RunnerPanel, QuickRunner,  |
|     ResultsView, RunnerStatus*, SetRow        |
|   Cardio:   CardioRunnerScreen, CardioRunnerPanel,   |
|     CardioQuickRunner, CardioResultsView,            |
|     CardioRunnerStatus*                              |
+-------------+-----------------------+----------------+
              |                       |
   RunnerScope.of   CardioRunnerScope.of
              v                       v
+----------------------+   +---------------------------+
| RunnerScope   |   | CardioRunnerScope         |
| (InheritedNotifier)  |   | (InheritedNotifier)       |
+----------+-----------+   +-------------+-------------+
           |                             |
           v                             v
+----------------------+   +---------------------------+
| WorkoutRunner        |   | CardioRunner              |
| (ChangeNotifier)     |   | (ChangeNotifier)          |
| - WorkoutPlan?       |   | - CardioPlan?             |
| - WorkoutRunnerState?|   | - CardioRunnerState?      |
| - global/set/rest    |   | - global / interval timer |
| - Stream<WorkoutRes.>|   | - Stream<CardioResult>    |
+----------+-----------+   +-------------+-------------+
           |                             |
           +--------------+--------------+
                          |
            both write through the same
                          v
+------------------------------------------------------+
|     RunnerStorage  (interface)                       |
|     PrefsRunnerStorage  |  InMemoryRunnerStorage     |
|     ...or your own (Hive, SQLite, Supabase, ...)     |
|     keyed by `slot` — strength defaults to           |
|     'default', cardio defaults to 'cardio'.          |
+------------------------------------------------------+
```

The controller has no dependency on Flutter widgets — it only imports
`package:flutter/foundation.dart` for `ChangeNotifier`. You can drive it from
tests or background isolates as long as you supply a `RunnerStorage` that
works in that environment.

## Module map

Under `lib/src/`:

| Directory                  | Purpose                                                                                              |
| -------------------------- | ---------------------------------------------------------------------------------------------------- |
| `controller/`              | `WorkoutRunner` (strength controller). `cardio_runner.dart` is a separate, parallel controller.      |
| `models/`                  | Plain Dart value types with `toJson` / `fromJson` / `copyWith`. No Flutter dependency.               |
| `models/cardio/`           | Equivalent value types for `CardioRunner`.                                                           |
| `data/`                    | Static catalogues: `DefaultMuscles`, `DefaultCategories`, `DefaultExercises`, `DefaultPlans`.        |
| `storage/`                 | The `RunnerStorage` interface + `PrefsRunnerStorage` (SharedPreferences) and `InMemoryRunnerStorage`. |
| `theme/`                   | `WorkoutRunnerThemeData` design tokens and the `WorkoutRunnerTheme` `InheritedTheme`.                |
| `widgets/`                 | Public widgets that read the runner via `RunnerScope`.                                        |
| `widgets/internals/`       | Building blocks (`RunnerCard`, `RunnerPillButton`, `TimerText`, `SectionLabel`). Exported.           |
| `screens/`                 | `RunnerScreen` and `CardioRunnerScreen` — ready-to-push `Scaffold`s wrapping `RunnerPanel` / `CardioRunnerPanel`. Both are exported.   |

The cardio side mirrors the strength side: the same controller / scope /
widget / storage layering, the same theme, the same idea of a `slot`. See
[Two runners: strength + cardio](#two-runners-strength--cardio) below.

## Data flow: start to finish

The state machine you orchestrate looks like this. Each step lists the method
on `WorkoutRunner` and what it does.

1. **Construction**

   ```dart
   final runner = WorkoutRunner(); // default: PrefsRunnerStorage, slot 'default'
   ```

   No persistence happens yet — no plan, no state.

2. **(Optional) Resume**

   ```dart
   final resumed = await runner.tryAutoResume();
   ```

   Reads `state` and `plan` JSON from storage at the configured slot. If both
   exist and `state.isActive` is true, the in-memory plan + state are
   restored, `_elapsed` is recomputed from `state.startedAt`, the global
   ticker starts, and the runner notifies listeners. Returns `true` on a real
   resume, `false` if nothing was stored or anything failed to parse.

3. **Start a new workout**

   ```dart
   await runner.start(plan);
   ```

   Creates a fresh `WorkoutRunnerState` (`isActive: true`, `startedAt: now`,
   no active exercise), resets set + rest tickers, starts the global ticker,
   persists, notifies. If `resumeIfPossible` is true (default) and the
   stored `state.planId` matches `plan.id` and is still active, the existing
   state is reused.

4. **Activate an exercise**

   ```dart
   runner.setActiveExercise(0);
   ```

   Sets `state.activeExerciseIndex`. Refuses if another exercise is already
   active (call `clearActiveExercise()` first). Until an exercise is active,
   `startSet` returns `false`.

5. **Start a set**

   ```dart
   runner.startSet(0, 0);
   ```

   Validates: a plan + state exist, the exercise is the active one, no set
   is currently running, indices are in range, the set has not been
   performed yet. On success it cancels any rest timer, starts the per-set
   ticker (1 s period) and notifies.

6. **Finish the running set**

   ```dart
   await runner.finishCurrentSet(reps: 8, weight: 60, rir: 2);
   ```

   Stops the set ticker, records a `PerformedSet`, persists, then —
   if `rest` (defaulting to `runner.defaultRest`) is non-zero — starts the
   rest ticker. The widget tree gets a notification per second until the
   rest ends or `skipRest()` is called.

7. **Repeat / page**

   `showExercise(i)` changes the visible (carousel) exercise without
   activating it. `clearActiveExercise()` resets the active exercise and
   discards any running set or rest.

8. **Log retroactively (optional)**

   ```dart
   await runner.logSet(exerciseIndex: 0, setIndex: 2, reps: 6, weight: 60);
   await runner.updatePerformedSet(
     exerciseIndex: 0, setIndex: 2, reps: 7, weight: 60,
   );
   ```

   Bypasses the per-set ticker, useful for imports or for editing after the
   fact.

9. **Mutate the plan**

   `addSetToExercise(...)` / `removeSetFromExercise(...)` append / drop
   target sets. Removal is rejected if a `PerformedSet` already exists at
   that index.

10. **Finish the workout**

    ```dart
    final result = await runner.finish();
    ```

    Builds a `WorkoutResult` from `state.performed`, stops every timer,
    clears in-memory state, clears both storage entries, invokes
    `onFinished` (if set), pushes the result onto the `finished` broadcast
    stream, and notifies. Returns `null` if there is no active workout.

11. **Cancel (no result)**

    ```dart
    await runner.cancel();
    ```

    Same teardown as `finish()` but emits no result.

12. **Disposal (app shutdown)**

    ```dart
    runner.dispose();
    ```

    Cancels every timer, closes the `finished` stream controller. The
    *owner* of the runner is responsible — neither `RunnerScope` nor
    any widget calls `dispose()` for you.

## Persistence model

Two keys per `slot` are written: state and plan. They are written
separately because plan mutations (`addSetToExercise`,
`removeSetFromExercise`) are independent from state mutations, and
`tryAutoResume()` needs both.

Concretely, `_persist()` writes both `state` and `plan`; `_persistPlan()`
writes only the plan. They are called from every mutating method —
`start`, `showExercise`, `setActiveExercise`, `clearActiveExercise`,
`_recordPerformedSet` (called by `finishCurrentSet` and `logSet`),
`updatePerformedSet`, `addSetToExercise`, `removeSetFromExercise`.
`finish()` and `cancel()` invoke `clearState` + `clearPlan` instead.

Auto-resume reads the state, parses it, and only resumes when
`state.isActive` is `true`. The global elapsed time is recomputed from
`state.startedAt` so even an app launched the next day shows accurate wall
time. The per-set and rest tickers are **not** restored — they only exist
in memory, so a relaunch lands you between sets, not mid-set.

See [STORAGE.md](STORAGE.md) for the storage contract and example custom
implementations.

## Two runners: strength + cardio

`WorkoutRunner` and `CardioRunner` are independent `ChangeNotifier`s with
no shared state. They are designed to coexist in the same app:

- They both talk to the **same** [`RunnerStorage`](STORAGE.md) interface,
  but each uses its own `slot`. By convention, `WorkoutRunner` defaults to
  `'default'` and `CardioRunner` defaults to `'cardio'`, so they never
  overwrite each other's state or plan keys on the default
  `PrefsRunnerStorage`.
- They have separate scopes — `RunnerScope` and `CardioRunnerScope`
  — so widgets only rebuild for "their" controller. Drop both scopes near
  the root of your app and any descendant widget can read whichever one it
  needs.
- You own the lifecycle of each. Construct them once, call `dispose()` on
  each when you tear down your root state.

```dart
final strength = WorkoutRunner();              // slot 'default'
final cardio   = CardioRunner();               // slot 'cardio'

// Auto-resume both on app start — they read independent storage keys.
await strength.tryAutoResume();
await cardio.tryAutoResume();

runApp(
  RunnerScope(
    runner: strength,
    child: CardioRunnerScope(
      runner: cardio,
      child: const MaterialApp(home: Home()),
    ),
  ),
);
```

If you do need to point both runners at the same backing storage (e.g. a
shared Supabase table) you can pass `slot: 'alice_strength'` / `slot:
'alice_cardio'` to keep their rows distinct.

### Cardio data flow: start to finish

The strength runner is keyed by `(exercise, set)`. The cardio runner is
keyed by `interval` — every plan is a flat list of `CardioInterval`s, and
each completed interval is logged as a `CardioLap`.

1. **Start**

   ```dart
   await cardio.start(DefaultCardioPlans.tabata);
   ```

   Builds a fresh `CardioRunnerState` (or reuses the in-memory one when
   `resumeIfPossible: true` and the plan id matches), resets the interval
   ticker, starts the global ticker, persists, notifies.

2. **Interval ticker auto-advance**

   While `state.isActive`, the interval ticker increments
   `currentIntervalElapsed` once per second. If `autoAdvance` is `true`
   (the default) and the interval has a `targetDuration`, the runner
   auto-calls `completeInterval(duration: target)` the moment the
   elapsed time hits the target. Distance-only and open-ended intervals
   never auto-advance — the user signals completion manually.

3. **`completeInterval(...)`**

   Records a `CardioLap` (`CardioLap.computed` derives `avgPacePerKm`
   from duration + distance), appends it to `state.laps`, increments
   `currentIntervalIndex`, resets the interval ticker. When the new
   index is past the last interval, the interval ticker stops — leaving
   `finish()` to the consumer so a summary screen can be shown first.

4. **`finish()`**

   Builds a `CardioResult` from `state.laps`, stops every timer, clears
   the cardio slot in storage, fires `onFinished`, emits on the
   `finished` broadcast stream. Returns `null` when no session is
   active.

5. **`cancel()` / `dispose()`**

   Same teardown shape as `WorkoutRunner` — `cancel` clears storage
   without producing a result; `dispose` cancels every timer and closes
   the `finished` stream controller.

`skipInterval()` and `jumpToInterval(i)` exist for free-form navigation —
both move the index without logging a lap. Set `cardio.autoAdvance =
false` if you want to drive transitions entirely from your UI.

## Timers

Three independent `Timer.periodic`s, each ticking at 1 s:

| Timer         | Field          | Starts in                                      | Stops in                                                                       |
| ------------- | -------------- | ---------------------------------------------- | ------------------------------------------------------------------------------ |
| Global        | `_globalTimer` | `start` / `tryAutoResume`                      | `cancel`, `finish`, `dispose`                                                  |
| Set ticker    | `_setTicker`   | `startSet`                                     | `finishCurrentSet`, `clearActiveExercise`, `cancel`, `finish`, `dispose`       |
| Rest ticker   | `_restTicker`  | `finishCurrentSet` (when `rest.inSeconds > 0`) | When countdown hits zero, `skipRest`, `startSet`, `clearActiveExercise`, `cancel`, `finish`, `dispose` |

All three are unconditionally cancelled in `dispose()` via `_stopAllTimers()`,
so you cannot leak a timer by destroying the controller mid-workout. Each
tick calls `notifyListeners()` so the widget tree refreshes once per second.

## Threading / lifecycle

`WorkoutRunner` is single-isolate / single-listener-model. All mutations
happen on the platform thread. Persistence is async (the storage interface
returns `Future`s), but the in-memory state is updated synchronously before
the await — listeners get the visible update immediately, the disk write
happens shortly after.

The `finished` getter returns a **broadcast** stream: any number of
listeners, no buffered history, one event per successful `finish()` call.
The optional `onFinished` callback fires synchronously before the stream
event for callers that prefer a callback.

You — the app — own the runner and must call `dispose()` when you're done
with it. A common pattern is to construct the runner once at app start
(e.g. in a holder above `MaterialApp`) and dispose it from your root state
object. `RunnerScope` does not own the runner, it only exposes it.
