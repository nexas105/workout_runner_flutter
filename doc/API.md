# API reference

Public types in alphabetical-ish order: controller first, then models, then
storage, then theme. Private members (anything starting with `_`) are
omitted. See [ARCHITECTURE.md](ARCHITECTURE.md) for the high-level model and
[WIDGETS.md](WIDGETS.md) for widget usage.

```dart
import 'package:fitness_workout/fitness_workout.dart';
```

---

## `WorkoutRunner`

```dart
class WorkoutRunner extends ChangeNotifier { ... }
```

The strength runner. Owns the active `WorkoutPlan`, the running
`WorkoutRunnerState`, three timers, the `finished` stream, and persistence
through a `RunnerStorage`. Pair it with `RunnerScope` so the bundled
widgets can find it.

### Construction

```dart
WorkoutRunner({
  RunnerStorage? storage,
  String slot = 'default',
});
```

- `storage` — defaults to `PrefsRunnerStorage()`. Inject your own
  (`InMemoryRunnerStorage`, custom) for tests or backends. See
  [STORAGE.md](STORAGE.md).
- `slot` — string key passed to every storage call. Use a per-user value
  for multi-user setups so different users do not stomp on each other's
  saved state. `WorkoutRunner` defaults to `'default'`; its cardio peer
  [`CardioRunner`](#cardiorunner) defaults to `'cardio'`, so the two can
  share a single backing storage without colliding.

### Lifecycle

**The owner is responsible for calling `dispose()`.** No widget in this
package does that for you.

```dart
@override
void dispose() {
  runner.dispose();
  super.dispose();
}
```

`dispose()` cancels every timer and closes the `finished` stream
controller.

### Properties

| Name                       | Type                            | Notes                                                                                              |
| -------------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------- |
| `plan`                     | `WorkoutPlan?`                  | The active plan. `null` between workouts.                                                          |
| `state`                    | `WorkoutRunnerState?`           | The persistable state snapshot.                                                                    |
| `isRunning`                | `bool`                          | Shorthand for `state?.isActive == true`.                                                           |
| `elapsed`                  | `Duration`                      | Time since `state.startedAt`, updated by the global ticker.                                        |
| `exercises`                | `List<WorkoutExercise>`         | `plan?.exercises ?? const []`.                                                                     |
| `currentExerciseIndex`     | `int`                           | Which exercise the UI is paged to. Defaults to `0`.                                                |
| `activeExerciseIndex`      | `int?`                          | Which exercise the user has *started*. `null` until `setActiveExercise()`.                         |
| `hasActiveExercise`        | `bool`                          | `activeExerciseIndex != null`.                                                                     |
| `currentExercise`          | `WorkoutExercise?`              | The exercise at `currentExerciseIndex`, or `null`.                                                 |
| `activeExercise`           | `WorkoutExercise?`              | The exercise at `activeExerciseIndex`, or `null`.                                                  |
| `activeSetExerciseIndex`   | `int?`                          | Exercise of the set whose ticker is running.                                                       |
| `activeSetIndex`           | `int?`                          | Set index of the set whose ticker is running.                                                      |
| `isSetRunning`             | `bool`                          | A set ticker is active.                                                                            |
| `currentSetElapsed`        | `Duration`                      | Elapsed time for the running set.                                                                  |
| `isResting`                | `bool`                          | The rest ticker is active.                                                                         |
| `restRemaining`            | `Duration`                      | Seconds remaining on the rest ticker.                                                              |
| `defaultRest`              | `Duration`                      | Used when `finishCurrentSet` / `addSetToExercise` is called without an explicit `rest`. Defaults to 90 s. |
| `finished`                 | `Stream<WorkoutResult>`         | Broadcast stream, one event per successful `finish()` call.                                        |
| `onFinished`               | `WorkoutFinishedCallback?`      | Optional callback, fires synchronously before the stream event.                                    |
| `onSetCompleted`           | `ValueChanged<PerformedSet>?`   | Optional callback after `finishCurrentSet` or `logSet` records a set.                              |
| `onExerciseChanged`        | `ValueChanged<int>?`            | Optional callback after `showExercise` changes the visible exercise.                               |
| `onRestStarted`            | `ValueChanged<Duration>?`       | Optional callback when a rest countdown starts.                                                    |

### Queries

```dart
bool isExerciseShown(int index);   // index == currentExerciseIndex
bool isExerciseActive(int index);  // index == activeExerciseIndex
bool canActivateSet(int exerciseIndex);  // exerciseIndex is active
bool canStart(WorkoutPlan plan);   // plan.validate().isValid
PerformedSet? getPerformedSet(int exerciseIndex, int setIndex);
```

None of these notify listeners.

### Mutating methods

All mutating methods call `notifyListeners()` (synchronously, even when the
method is async) and persist through `RunnerStorage`.

```dart
Future<bool> tryAutoResume();
```
Restore a previously saved active workout from `storage`. Returns `true` if
state was restored. Persists nothing; only reads.

```dart
Future<void> start(WorkoutPlan plan, {bool resumeIfPossible = true});
```
Start (or resume, if `resumeIfPossible` and the saved state matches the plan
id) a workout. Resets set + rest tickers, starts the global ticker.

```dart
Future<void> cancel();
```
Tear down without producing a result. Clears both storage entries.

```dart
Future<WorkoutResult?> finish();
```
Tear down with a result. Builds a `WorkoutResult` from `state.performed`,
clears storage, fires `onFinished`, emits on `finished`. Returns `null`
when no workout is active. **Side effects:** stops every timer, clears
state + plan, notifies, emits.

```dart
void showExercise(int index);
```
Paginate the carousel. No-op when `index` is out of range or unchanged.

```dart
void setActiveExercise(int index);
```
Mark an exercise as active. No-op when another is already active.

```dart
void clearActiveExercise();
```
Clear the active exercise. Discards any in-progress set and rest.

```dart
bool startSet(int exerciseIndex, int setIndex);
```
Start the per-set ticker. Returns `false` when preconditions fail (no plan,
not the active exercise, another set running, out-of-range index, set
already performed).

```dart
Future<bool> finishCurrentSet({
  required int reps,
  double? weight,
  int? rir,
  Duration? setDuration,
  Duration? rest,
});
```
Finish the running set. `setDuration` overrides the measured time, `rest`
overrides `defaultRest` (set to `Duration.zero` to skip the rest ticker).
Returns `false` when no set ticker is running.

```dart
Future<bool> logSet({
  required int exerciseIndex,
  required int setIndex,
  required int reps,
  double? weight,
  int? rir,
  Duration? duration,
  Duration? pause,
});
```
Record a `PerformedSet` without going through a ticker. Useful for backfill
flows. Returns `false` for missing state or out-of-range indices.

```dart
Future<void> updatePerformedSet({
  required int exerciseIndex,
  required int setIndex,
  required int reps,
  double? weight,
  int? rir,
});
```
Mutate an already-logged set in-place.

```dart
void skipRest();
```
Cancel the rest ticker.

```dart
Future<bool> addSetToExercise(
  int exerciseIndex, {
  int targetReps = 10,
  double? targetWeight,
  Duration? rest,
});
```
Append a target set to a plan exercise. Persists the plan.

```dart
Future<bool> removeSetFromExercise(int exerciseIndex, int setIndex);
```
Remove a target set. Refuses if the set is already performed.

### `finished` stream semantics

- It is a **broadcast** stream — multiple listeners are allowed.
- One event per successful `finish()` (so `result != null`).
- No replay: subscribe before `finish()` to receive the event.
- The stream controller is closed in `dispose()`. Cancel your subscription
  before that to avoid an `onDone` callback fire.

### Common pitfalls

- Calling `startSet` before `setActiveExercise` returns `false`. The UI
  surfaces this by greying out the *Start* affordance — your custom UI
  should do the same.
- `setActiveExercise` is a no-op while another exercise is active. If you
  want to swap, call `clearActiveExercise()` first.
- `start()` does not call `tryAutoResume()`. Auto-resume is opt-in.

---

## `WorkoutFinishedCallback`

```dart
typedef WorkoutFinishedCallback = void Function(WorkoutResult result);
```

Shape of `WorkoutRunner.onFinished`.

---

## `CardioRunner`

```dart
class CardioRunner extends ChangeNotifier { ... }
```

Cardio counterpart of [`WorkoutRunner`](#workoutrunner). Owns the active
`CardioPlan`, a `CardioRunnerState`, two timers (global + interval), the
`finished` broadcast stream, and persistence through a `RunnerStorage`.
Pair it with [`CardioRunnerScope`](WIDGETS.md#cardiorunnerscope) so the
bundled cardio widgets can find it.

### Construction

```dart
CardioRunner({
  RunnerStorage? storage,
  String slot = 'cardio',
});
```

- `storage` — defaults to `PrefsRunnerStorage()`. The same storage can be
  shared with a `WorkoutRunner` because the default `slot`s differ.
- `slot` — string key passed to every storage call. Defaults to
  `'cardio'`. Use a per-user value for multi-user setups.

### Lifecycle

**The owner is responsible for calling `dispose()`.** No widget in this
package does that for you. `dispose()` cancels both timers and closes the
`finished` stream controller.

### Read-only accessors

| Name                         | Type                            | Notes                                                                                              |
| ---------------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------- |
| `plan`                       | `CardioPlan?`                   | The active plan. `null` between sessions.                                                          |
| `state`                      | `CardioRunnerState?`            | The persistable state snapshot.                                                                    |
| `isRunning`                  | `bool`                          | `state?.isActive == true`.                                                                         |
| `isPaused`                   | `bool`                          | A state exists but `isActive == false`.                                                            |
| `elapsed`                    | `Duration`                      | Total time since `state.startedAt`, updated by the global ticker. Paused intervals are skipped.    |
| `intervals`                  | `List<CardioInterval>`          | `plan?.intervals ?? const []`.                                                                     |
| `currentIntervalIndex`       | `int`                           | Index in `intervals`. `0` when no session is running.                                              |
| `currentInterval`            | `CardioInterval?`               | `intervals[currentIntervalIndex]`, or `null` past the end.                                         |
| `currentIntervalElapsed`     | `Duration`                      | Time spent in the current interval. Resets at every interval transition.                           |
| `currentIntervalRemaining`   | `Duration`                      | `targetDuration - currentIntervalElapsed`, clamped to zero. **Returns `Duration.zero` when the interval has no `targetDuration`.** |
| `laps`                       | `List<CardioLap>`               | All `CardioLap`s logged so far.                                                                    |
| `hasNextInterval`            | `bool`                          | Whether another interval follows the current one.                                                  |
| `finished`                   | `Stream<CardioResult>`          | Broadcast stream, one event per successful `finish()` call.                                        |
| `onFinished`                 | `CardioFinishedCallback?`       | Optional callback, fires synchronously before the stream event.                                    |
| `onIntervalCompleted`        | `ValueChanged<CardioLap>?`      | Optional callback after `completeInterval` records a lap.                                          |
| `onPaused`                   | `VoidCallback?`                 | Optional callback after `pause` persists the paused state.                                         |
| `onResumed`                  | `VoidCallback?`                 | Optional callback after `resume` persists the active state.                                        |
| `autoAdvance`                | `bool`                          | Read/write. When `true` (default), the interval ticker auto-completes the lap once `targetDuration` is reached. Set to `false` for fully manual transitions. |

### Mutating methods

All mutating methods call `notifyListeners()` and persist through
`RunnerStorage`.

```dart
Future<bool> tryAutoResume();
```
Restore a previously saved cardio session from `storage`. Returns `true`
on a successful resume. If the stored state was active, both tickers
restart.

```dart
Future<void> start(CardioPlan plan, {bool resumeIfPossible = true});
```
Start (or resume, when `resumeIfPossible` and the saved state's `planId`
matches `plan.id`) a session. Resets the interval ticker, starts the
global ticker.

```dart
Future<void> pause();
```
Stop both tickers without producing a result. `state.isActive` becomes
`false`; `elapsed` and the lap list are preserved.

```dart
Future<void> resume();
```
Restart both tickers after a `pause()`.

```dart
Future<void> cancel();
```
Tear down without producing a result. Clears both storage entries.

```dart
Future<CardioResult?> finish();
```
Tear down with a result. Builds a `CardioResult` from `state.laps`, clears
storage, fires `onFinished`, emits on `finished`. Returns `null` when no
session is active.

```dart
Future<CardioLap?> completeInterval({
  double? distanceMeters,
  int? avgHeartRate,
  int? rpe,
  Duration? duration,
});
```
Record the current interval as a completed `CardioLap` and advance.
`distanceMeters` falls back to `currentInterval.targetDistanceMeters` when
omitted; `duration` falls back to `currentIntervalElapsed`. The lap's
`avgPacePerKm` is derived via [`CardioLap.computed`](#cardiolap). Returns
the persisted lap, or `null` when no session is active. When the new
interval index is past the end, the interval ticker stops — `finish()` is
**not** called automatically, so the consumer can show a summary first.

```dart
Future<void> skipInterval();
```
Advance to the next interval without logging a lap. Useful for trimming a
warm-up.

```dart
Future<void> jumpToInterval(int index);
```
Move to a specific interval. Out-of-range indices are ignored.

### Interval auto-advance semantics

The interval ticker runs at 1 s. On every tick, when:

- `state.isActive`, and
- `autoAdvance == true`, and
- `currentInterval.targetDuration != null`, and
- `currentIntervalElapsed >= targetDuration`,

it calls `completeInterval(duration: targetDuration)` for you. Distance-
bounded intervals and open-ended intervals (`targetDuration == null`)
never auto-advance — the user must press *Complete interval*.

### `finished` stream semantics

Same shape as the strength side — broadcast stream, one event per
successful `finish()`, no replay, closed on `dispose()`.

### Common pitfalls

- `currentIntervalRemaining` returns `Duration.zero` for open-ended
  intervals (where `targetDuration` is `null`). If you rely on it for a
  countdown UI, check `currentInterval?.targetDuration != null` first.
- `completeInterval` does not call `finish()` when the final interval is
  logged. You decide when to wrap up (e.g. by listening to `state` or
  `hasNextInterval`).
- `start()` does not call `tryAutoResume()`. Auto-resume is opt-in.
- The interval ticker is **not** restored across an auto-resume —
  `currentIntervalElapsed` resets to zero on restart. The global
  `elapsed` and the lap list are preserved.

### Common recipes

#### Running parallel strength + cardio runners

```dart
final strength = WorkoutRunner();   // slot 'default'
final cardio   = CardioRunner();    // slot 'cardio'

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

Because the default `slot`s differ, the two runners read and write
disjoint keys on the same `PrefsRunnerStorage` and never trample each
other.

#### Manual interval advance

```dart
final cardio = CardioRunner()..autoAdvance = false;

await cardio.start(plan);

// The interval ticker still counts up, but transitions only happen on
// explicit user input.
await cardio.completeInterval(distanceMeters: 500);
```

Use this when the user is doing distance- or rep-bounded work and the
target duration is approximate.

---

## `CardioFinishedCallback`

```dart
typedef CardioFinishedCallback = void Function(CardioResult result);
```

Shape of `CardioRunner.onFinished`.

---

## Models — cardio

All cardio models live under `lib/src/models/cardio/`. They are
`@immutable`, have `toJson` / `fromJson(Map<String, dynamic>)`, and
`copyWith` (where applicable). Equality is by `id` where applicable.

### `CardioPlan`

```dart
CardioPlan({
  required String id,
  required String name,
  required List<CardioInterval> intervals,
  String? description,
  CardioDiscipline discipline = CardioDiscipline.mixed,
  ExerciseCategory? category,
  Map<String, dynamic>? meta,
});
```

Top-level cardio plan. Identity is the `id` field. Computed getters:

- `plannedDuration` — sum of every interval's `targetDuration`
  (open-ended intervals contribute zero).
- `plannedDistanceMeters` — sum of every interval's
  `targetDistanceMeters`.

Extras: `toJsonString()` / `CardioPlan.fromJsonString(s)`.

### `CardioDiscipline`

```dart
enum CardioDiscipline { running, cycling, rowing, swimming,
                        jumpRope, walk, mixed }
```

Informational only — used by UI hints (e.g. `CardioQuickRunner` picks a
discipline-specific icon). Round-trips through its `name`;
deserialisation falls back to `mixed` for unknown values.

### `CardioInterval`

```dart
CardioInterval({
  required String id,
  required String name,
  CardioPhase phase = CardioPhase.work,
  Duration? targetDuration,
  double? targetDistanceMeters,
  String? intensity,
  Duration? targetPacePerKm,
  String? notes,
  Map<String, dynamic>? meta,
});
```

One segment of a `CardioPlan`. Identity is the `id` field. `intensity` is
free-form (`'Z3'`, `'RPE 8'`, `'80% HRmax'` — whatever your UI shows).
Computed getter:

- `isAutoAdvancing` — `true` when either `targetDuration` or
  `targetDistanceMeters` is set. The runner only auto-advances when
  `targetDuration` is set (distance-bounded intervals still need a
  manual *Complete interval* tap because the package does not measure
  GPS / cadence itself).

### `CardioPhase`

```dart
enum CardioPhase { warmup, work, rest, steady, cooldown }
```

Drives the colour and label of the phase pill in `CardioRunnerPanel`.

### `CardioLap`

```dart
CardioLap({
  required int intervalIndex,
  required Duration duration,
  double? distanceMeters,
  int? avgHeartRate,
  Duration? avgPacePerKm,
  int? rpe,
  required DateTime completedAt,
});
```

An executed interval, the counterpart of `PerformedSet`. The `intervalIndex`
points back into `CardioPlan.intervals`. JSON encodes both `duration` and
`avgPacePerKm` as integer seconds.

```dart
factory CardioLap.computed({
  required int intervalIndex,
  required Duration duration,
  double? distanceMeters,
  int? avgHeartRate,
  int? rpe,
  DateTime? completedAt,
});
```

Convenience constructor used by `CardioRunner.completeInterval`. Derives
`avgPacePerKm` (seconds per km) from `duration` + `distanceMeters` when
both are present and non-zero; otherwise leaves it `null`. `completedAt`
defaults to `DateTime.now()`.

### `CardioResult`

```dart
CardioResult({
  required String planId,
  required String planName,
  required DateTime startedAt,
  required DateTime finishedAt,
  required Duration duration,
  required List<CardioLap> laps,
});
```

Emitted by `CardioRunner.finish()` and on the `finished` stream. Computed
getters:

- `totalLaps` — `laps.length`.
- `totalWorkTime` — sum of every lap's `duration`.
- `totalDistanceMeters` — sum of every lap's `distanceMeters` (treating
  `null` as zero).
- `avgPacePerKm` — average pace in seconds-per-km across laps that
  reported both a non-zero distance and a non-zero duration. Returns
  `null` when no laps qualified.

### `CardioRunnerState`

```dart
CardioRunnerState({
  required String planId,
  required int currentIntervalIndex,
  required bool isActive,
  required DateTime startedAt,
  required DateTime updatedAt,
  required Duration elapsed,
  required List<CardioLap> laps,
});
```

The persistable cardio snapshot. JSON encodes `startedAt` / `updatedAt`
as ISO strings, `elapsed` as integer seconds.

`copyWith` keeps `planId` and `startedAt` fixed (the runner never mutates
them across a single session). `currentIntervalIndex`, `isActive`,
`updatedAt`, `elapsed`, and `laps` are all replaceable.

### `DefaultCardioPlans`

```dart
DefaultCardioPlans.easy5k;        // continuous 5 km
DefaultCardioPlans.tabata;        // 8 × (20 s / 10 s)
DefaultCardioPlans.walkRun;       // 6 × (3 min / 2 min)
DefaultCardioPlans.row500s;       // 4 × 500 m rowing
DefaultCardioPlans.bikePyramid;   // 60/90/120/90/60 s pyramid
DefaultCardioPlans.jumpRopeEmom;  // 10 × (40 s / 20 s)

DefaultCardioPlans.all;           // List<CardioPlan>
DefaultCardioPlans.byId('plan_tabata');
DefaultCardioPlans.byDiscipline(CardioDiscipline.rowing);
```

Use directly or copy as templates for app-specific plans.

---

## Models — strength

All strength models live under `lib/src/models/`. They are `@immutable`,
have `toJson` / `fromJson(Map<String, dynamic>)`, and `copyWith` (with one
or two exceptions noted). Equality is by `id` where applicable.

### `WorkoutPlan`

```dart
WorkoutPlan({
  required String id,
  required String name,
  required List<WorkoutExercise> exercises,
  String? description,
  Map<String, dynamic>? meta,
});
```

Top-level plan. Identity is the `id` field. `meta` is opaque — anything you
put in it round-trips through JSON unchanged, useful for tags, source
identifiers, etc.

JSON shape:

```json
{
  "id": "string",
  "name": "string",
  "description": "string?",
  "exercises": [ { /* WorkoutExercise */ } ],
  "meta": { /* free-form, optional */ }
}
```

Extras: `toJsonString()` / `WorkoutPlan.fromJsonString(s)` for string-typed
storage.

`copyWith` accepts every constructor parameter and replaces only the fields
you pass.

### `WorkoutPlanBuilder`

Fluent helper for creating plans without nesting constructors:

```dart
final plan = WorkoutPlanBuilder('Push Day')
    .exercise('Bench Press')
    .set(reps: 8, weight: 80)
    .set(reps: 8, weight: 80)
    .exercise('Shoulder Press')
    .set(reps: 10)
    .build();
```

Generated ids are slugged from names and duplicate exercise ids get a numeric
suffix. Call `addExercise()` / `addSet()` when you already have model objects.

### Plan validation

```dart
final result = plan.validate();
if (!result.isValid) {
  for (final issue in result.errors) {
    debugPrint(issue.message);
  }
}

final canRun = runner.canStart(plan);
```

Validation returns a `WorkoutPlanValidationResult` with `errors`, `warnings`,
`isValid`, and `hasWarnings`. Empty plan ids/names, duplicate exercise ids,
invalid reps, negative weights, and negative rests are errors. Exercises with
no target sets are warnings.

### `WorkoutExercise`

```dart
WorkoutExercise({
  required String id,
  required String name,
  String? description,
  ExerciseCategory? category,
  List<Muscle> muscles = const [],
  List<WorkoutSet> sets = const [],
  String? notes,
  Map<String, dynamic>? meta,
});
```

Identity is the `id`. JSON shape:

```json
{
  "id": "string",
  "name": "string",
  "description": "string?",
  "category": { /* ExerciseCategory */ } | null,
  "muscles": [ { /* Muscle */ } ],
  "sets": [ { /* WorkoutSet */ } ],
  "notes": "string?",
  "meta": { /* optional */ }
}
```

Muscles round-trip through their own JSON — no global lookup is required to
restore an exercise from storage.

### `WorkoutSet`

```dart
WorkoutSet({
  required int targetReps,
  double? targetWeight,
  Duration? rest,
});
```

Target set on a plan. JSON: `rest` is encoded as `int` seconds. Equality is
structural (`targetReps`, `targetWeight`, `rest`).

### `PerformedSet`

```dart
PerformedSet({
  required int exerciseIndex,
  required int setIndex,
  required int actualReps,
  double? actualWeight,
  int? rir,
  Duration? pause,
  Duration? duration,
  required DateTime completedAt,
});
```

An executed set. `pause` is the rest taken after the set; `duration` is the
time spent on the set itself. Both are encoded as `int` seconds in JSON.
`fromJson` also accepts a legacy `restTaken` key as a synonym for `pause`.

### `PerformedExercise`

```dart
PerformedExercise({
  required int exerciseIndex,
  required String exerciseName,
  required List<PerformedSet> sets,
});
```

Container for performed sets, snapshotting the exercise name at the time of
recording (so a later plan rename does not retroactively change history).

### `WorkoutRunnerState`

```dart
WorkoutRunnerState({
  required String planId,
  required int currentExerciseIndex,
  required int? activeExerciseIndex,
  required int currentSetIndex,
  required bool isActive,
  required DateTime startedAt,
  required DateTime updatedAt,
  required List<PerformedExercise> performed,
});
```

The persistable snapshot. JSON encodes `startedAt` / `updatedAt` as ISO
strings.

`copyWith` is unusual: `activeExerciseIndex` accepts `Object?` with an
internal sentinel so you can pass `null` to clear it (the runner uses this
in `clearActiveExercise()`). Pass it explicitly if you want to set or
clear; leave it out to preserve.

### `WorkoutResult`

```dart
WorkoutResult({
  required String planId,
  required DateTime startedAt,
  required DateTime finishedAt,
  required Duration duration,
  required List<PerformedExerciseDetails> exercises,
});
```

Emitted by `finish()` and on the `finished` stream. Computed getters:

- `totalSets` — completed sets across all exercises.
- `totalReps` — sum of `actualReps`.
- `totalVolume` — sum of `actualWeight * actualReps` (weight defaults to 0
  when null).

### `PerformedExerciseDetails`

```dart
PerformedExerciseDetails({
  required String exerciseId,
  required String exerciseName,
  required List<PerformedSet> sets,
});
```

Same shape as `PerformedExercise` but keyed by `exerciseId` rather than by
index, so the result can be matched against an external exercise catalogue.

### `ExerciseCategory`

```dart
ExerciseCategory({
  required String id,
  required String name,
  String? description,
});
```

Plain value type. Identity by `id`. `DefaultCategories` (see below) ships a
small set of canonical values.

### `Muscle`

```dart
Muscle({
  required String id,
  required String name,
  String? group,
});
```

Identity by `id`. `DefaultMuscles` ships a body-map's worth.

---

## Default catalogues

Static helpers under `lib/src/data/`. Use them as starting data or replace
them with your own.

```dart
DefaultMuscles.all;                  // List<Muscle>
DefaultMuscles.byId('m_chest');      // Muscle?
DefaultMuscles.byName('Chest');      // Muscle?
DefaultMuscles.byGroup('upper');     // List<Muscle>

DefaultCategories.all;               // List<ExerciseCategory>
DefaultCategories.byId('cat_strength');
DefaultCategories.byName('Strength');
DefaultCategories.strength;          // shortcuts: strength, cardio, mobility, core, hiit

DefaultExercises.all;                // List<WorkoutExercise>
DefaultExercises.byId('ex_bench_press');
DefaultExercises.byCategory(DefaultCategories.strength);
DefaultExercises.byMuscle(DefaultMuscles.chest);
DefaultExercises.byMuscleGroup('upper');
DefaultExercises.search('press');

DefaultPlans.all;                    // List<WorkoutPlan>
DefaultPlans.byId('plan_push');
DefaultPlans.byKind('strength');
DefaultPlans.pushDay;                // shortcuts: pushDay, pullDay, legDay,
                                      // fullBodyBeginner, coreBurn, hiitCircuit,
                                      // mobilityFlow
```

---

## Storage

See [STORAGE.md](STORAGE.md) for examples. The contract:

```dart
abstract class RunnerStorage {
  Future<void> saveState(Map<String, dynamic> json, {String slot = 'default'});
  Future<Map<String, dynamic>?> readState({String slot = 'default'});
  Future<void> clearState({String slot = 'default'});

  Future<void> savePlan(Map<String, dynamic> json, {String slot = 'default'});
  Future<Map<String, dynamic>?> readPlan({String slot = 'default'});
  Future<void> clearPlan({String slot = 'default'});
}
```

Implementations must round-trip the JSON unchanged. `slot` keys multiple
independent runners on the same backend; the default value is `'default'`.

### `PrefsRunnerStorage`

`SharedPreferences`-backed default. Keys:

- State: `workout_runner.state.{slot}`
- Plan:  `workout_runner.plan.{slot}`

Both are stored as JSON strings via `dart:convert`'s `jsonEncode`.

### `InMemoryRunnerStorage`

`Map`-backed, suitable for tests and previews. Does not survive a process
restart.

---

## Theme

See [THEMING.md](THEMING.md) for the token list.

```dart
class WorkoutRunnerThemeData { ... }
class WorkoutRunnerTheme extends InheritedTheme {
  const WorkoutRunnerTheme({Key? key, required WorkoutRunnerThemeData data,
                            required Widget child});
  static WorkoutRunnerThemeData of(BuildContext context);
}
```

`of(context)` returns the nearest data, falling back to
`WorkoutRunnerThemeData.dark()` when no ancestor exists, so widgets are
safe to use without an explicit theme.

---

## Common recipes

### Save results to a backend

```dart
late final StreamSubscription<WorkoutResult> _sub;

@override
void initState() {
  super.initState();
  _sub = runner.finished.listen((result) async {
    await api.saveWorkout(result.toJson());
  });
}

@override
void dispose() {
  _sub.cancel();
  super.dispose();
}
```

### Multiple parallel runners (multi-user, or strength + cardio side-by-side)

```dart
final alice = WorkoutRunner(slot: 'user_alice');
final bob   = WorkoutRunner(slot: 'user_bob');

await alice.tryAutoResume();
await bob.tryAutoResume();
```

Each runner reads / writes its own keys
(`workout_runner.state.user_alice`, etc.) so they do not interfere.

### Programmatic logging of past sets

```dart
await runner.start(plan);

for (var ex = 0; ex < plan.exercises.length; ex++) {
  for (var s = 0; s < plan.exercises[ex].sets.length; s++) {
    await runner.logSet(
      exerciseIndex: ex,
      setIndex: s,
      reps: lastWeek[ex][s].reps,
      weight: lastWeek[ex][s].weight,
      pause: const Duration(seconds: 60),
    );
  }
}

final result = await runner.finish();
```
