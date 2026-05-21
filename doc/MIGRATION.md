# Migration: 0.x → 1.0

1.0.0 is a full rewrite. Most public names changed, the global runner
singleton is gone, and every bundled widget is new. The list below covers
every breaking change called out in `CHANGELOG.md` plus the field renames
on the models.

If you only need a checklist, jump to the [bottom](#compatibility-checklist).

See [API.md](API.md) and [WIDGETS.md](WIDGETS.md) for the new shape and
[STORAGE.md](STORAGE.md) for the new persistence model.

---

## Controller

### `runner` singleton → `WorkoutRunner` instance + `RunnerScope`

There is no global runner anymore. Construct one yourself and expose it
through `RunnerScope`.

```dart
// before
import 'package:fitness_workout/fitness_workout.dart';

runner.configure(autoResume: true);
runner.start(plan);
```

```dart
// after
import 'package:fitness_workout/fitness_workout.dart';

final runner = WorkoutRunner();              // owner constructs it
await runner.tryAutoResume();                // explicit, not via configure
await runner.start(plan);

// somewhere above the widgets that need it:
RunnerScope(runner: runner, child: child);
```

You are now responsible for `runner.dispose()` when the owner state is
disposed.

### `WorkoutRunnerController` → `WorkoutRunner`

```dart
// before
final controller = WorkoutRunnerController(...);

// after
final controller = WorkoutRunner(...);
```

### `runner.configure(autoResume: …)` → constructor + `tryAutoResume()`

```dart
// before
runner.configure(autoResume: true);

// after
final runner = WorkoutRunner();              // optional: storage, slot
final resumed = await runner.tryAutoResume();
```

### `runner.onWorkoutFinished` → `runner.finished` stream

The callback is still available as `runner.onFinished`, but the
recommended way to receive results is the broadcast stream.

```dart
// before
runner.onWorkoutFinished = (result) {
  saveToBackend(result);
};
```

```dart
// after — callback variant (1:1 mapping)
runner.onFinished = (result) {
  saveToBackend(result);
};

// after — stream variant (preferred for multiple listeners)
final sub = runner.finished.listen(saveToBackend);
// remember: sub.cancel() before runner.dispose()
```

### `runner.changeExerciseIndex` → `runner.showExercise`

```dart
// before
runner.changeExerciseIndex(2);

// after
runner.showExercise(2);
```

### `runner.finishActiveSet` → `runner.finishCurrentSet`

The new signature accepts optional `weight` and an explicit `rest`
`Duration`, so the rest the user took for that set is captured.

```dart
// before
runner.finishActiveSet(reps: 8);
```

```dart
// after
await runner.finishCurrentSet(
  reps: 8,
  weight: 60,                              // optional, was missing
  rir: 2,
  rest: const Duration(seconds: 90),       // explicit rest taken
);
```

---

## Models

### `ExerciseCategorie` → `ExerciseCategory`

Typo fix. Search-and-replace.

```dart
// before
final cat = ExerciseCategorie(id: 'cat_strength', name: 'Strength');

// after
final cat = ExerciseCategory(id: 'cat_strength', name: 'Strength');
```

### `WorkoutExercise.desc` → `WorkoutExercise.description`

```dart
// before
WorkoutExercise(id: 'ex_squat', name: 'Squat', desc: 'King of leg moves');

// after
WorkoutExercise(
  id: 'ex_squat',
  name: 'Squat',
  description: 'King of leg moves',
);
```

### `defaultExercises` global → `DefaultExercises.all`

```dart
// before
final list = defaultExercises;
```

```dart
// after
final list = DefaultExercises.all;
// helpers:
DefaultExercises.byId('ex_squat');
DefaultExercises.byMuscle(DefaultMuscles.quads);
DefaultExercises.byCategory(DefaultCategories.strength);
DefaultExercises.search('press');
```

Equivalent helpers exist for muscles (`DefaultMuscles`), categories
(`DefaultCategories`) and plans (`DefaultPlans`).

### `WorkoutRunnerState.fromJson` no longer throws on null `activeExerciseIndex`

The 0.x release decoded `activeExerciseIndex` as `int` and crashed when a
previously inactive exercise was written. 1.0 decodes it as `int?`. No
code change needed, but if you persisted any 0.x state JSON it now decodes
correctly.

### `WorkoutExercise.fromJson` muscle decoding

0.x looked muscles up by id from a global registry and force-unwrapped the
result. 1.0 decodes muscles from their own JSON, so unknown muscle ids no
longer crash. The new JSON shape stores full muscle records inside an
exercise; old payloads that only contain ids will not round-trip — re-emit
them with `exercise.toJson()`.

---

## Storage

### Single in-process storage → pluggable `RunnerStorage`

```dart
// before — runner had a fixed storage strategy
runner.configure(autoResume: true);
```

```dart
// after — pick a storage backend, optionally a slot
final runner = WorkoutRunner(
  storage: PrefsRunnerStorage(),  // default; explicit shown for clarity
  slot: 'default',                // user id, or 'cardio', or any string
);
```

### Storage keys

If you used 0.x and had state persisted, note the new key prefixes used by
`PrefsRunnerStorage`:

- State: `workout_runner.state.{slot}`
- Plan:  `workout_runner.plan.{slot}`

0.x state in old keys is not migrated automatically — read it manually if
you need to preserve it, then call `runner.start(plan)` with the matching
plan.

See [STORAGE.md](STORAGE.md) for the full contract and custom backends.

---

## Widgets

Every bundled widget is new. There is no automated rename — pick the
replacement that matches your old layout.

| Old (0.x)                      | New (1.0)                                            |
| ------------------------------ | ---------------------------------------------------- |
| Default workout screen         | `RunnerScreen(plan: plan, runner: runner)`           |
| Custom body around the runner  | `RunnerPanel()` inside your own `Scaffold`           |
| Home-screen "start" card       | `QuickRunner(plans: [...], onOpen: ...)`             |
| Results page                   | `ResultsView(result: result)`                 |
| AppBar status                  | `RunnerStatusAppBarAction()` or `RunnerStatusChip()` |
| Inline banner under AppBar     | `RunnerStatusBanner()`                               |
| Bottom "continue workout" CTA  | `RunnerStatusBottomBar()`                            |
| Set list item                  | `SetRow(...)`                                        |

All bundled widgets read the runner from `RunnerScope`, so wrap
your tree once:

```dart
RunnerScope(
  runner: runner,
  child: child,
);
```

`RunnerScreen` also provides its own internal scope, so it is safe to push
without a wrapping scope ancestor.

---

## Theme

There was no design-token system in 0.x. 1.0 introduces
`WorkoutRunnerThemeData` + `WorkoutRunnerTheme`.

```dart
// 1.0
WorkoutRunnerTheme(
  data: WorkoutRunnerThemeData.dark().copyWith(
    accent: const Color(0xFFFF7E2A),
  ),
  child: const RunnerScreen(...),
);
```

If you want to keep the legacy look, do nothing — `WorkoutRunnerThemeData.dark()`
is used by default when no `WorkoutRunnerTheme` ancestor is present.

See [THEMING.md](THEMING.md) for the full token list.

---

## Finish flow

### Old: global `onWorkoutFinished`

```dart
// before
runner.onWorkoutFinished = (result) {
  Navigator.of(context).pushReplacementNamed('/results', arguments: result);
};
runner.finish();
```

### New: stream + per-screen handler

```dart
// after — stream listener anywhere in your app
runner.finished.listen((result) {
  analytics.log(result);
});

// after — screen-local handler via RunnerScreen
RunnerScreen(
  plan: plan,
  runner: runner,
  onFinished: (context, result) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Scaffold(body: ResultsView(result: result)),
      ),
    );
  },
);

// or — finish manually in your own UI
final result = await runner.finish();
if (result != null) {
  // navigate, save, ...
}
```

`runner.finish()` still returns the result, so synchronous flows work
without a stream listener.

---

## Compatibility checklist

After upgrading, verify the following:

- [ ] All `WorkoutRunnerController` references replaced with `WorkoutRunner`.
- [ ] The global `runner` singleton is gone; one `WorkoutRunner` instance
      lives at the top of your widget tree (or per logged-in user).
- [ ] You call `runner.dispose()` from your owning `State.dispose()`.
- [ ] `runner.configure(autoResume: …)` replaced by
      `await runner.tryAutoResume()` at app start.
- [ ] `runner.changeExerciseIndex(...)` replaced with `runner.showExercise(...)`.
- [ ] `runner.finishActiveSet(...)` calls replaced with
      `runner.finishCurrentSet(reps: ..., weight: ..., rest: ...)`.
- [ ] `runner.onWorkoutFinished` calls replaced with either
      `runner.onFinished` or `runner.finished.listen(...)`.
- [ ] All `ExerciseCategorie` references renamed to `ExerciseCategory`.
- [ ] All `WorkoutExercise.desc` references renamed to
      `WorkoutExercise.description`.
- [ ] All `defaultExercises` references replaced with `DefaultExercises.all`
      (or one of the new helpers).
- [ ] `RunnerScope(runner: runner, child: ...)` wraps any subtree
      that uses bundled widgets.
- [ ] Bundled widgets you used in 0.x replaced by the 1.0 equivalents
      listed in the [Widgets](#widgets) table.
- [ ] If you persisted 0.x state under old prefs keys, either migrate the
      data or accept that auto-resume will start cold on first launch.
- [ ] Custom storage (if any) implements the new `RunnerStorage` interface
      with both state and plan buckets per slot.
- [ ] Finish flow uses `runner.finished` stream and/or `runner.onFinished`
      callback; no more `runner.onWorkoutFinished`.
- [ ] (Optional) `WorkoutRunnerTheme` wraps your subtree if you want to
      override design tokens.

---

## Schema versioning (1.x and beyond)

From version 1.x of the package all top-level persistable payloads
(`WorkoutPlan`, `WorkoutResult`, `CardioResult`, `WorkoutRunnerState`,
`CardioRunnerState`) carry a `schemaVersion: <int>` field in JSON.
The current value is exported as `kPluginSchemaVersion`.

* `fromJson` factories MUST keep reading payloads written by previous
  schema versions — older JSON without `schemaVersion` is treated as
  schema version 0 and parsed with the same defensive defaults that
  the 1.0 factories already use.
* Bump `kPluginSchemaVersion` only when an irreversible JSON shape
  change ships, and add a section here describing what changed.

Additive fields (new optional keys, new enum members with a safe
fallback) do NOT require a version bump.
