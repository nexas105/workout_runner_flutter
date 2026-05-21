# Changelog

## 1.0.0 — refactor & stable API

Complete refactor of the package. **Breaking changes throughout** — see
`doc/MIGRATION.md` for upgrade notes.

### Highlights
- New `WorkoutRunner` controller (was `WorkoutRunnerController`). No more
  global singleton — instantiate it yourself and pass it via
  `RunnerScope`.
- New **`CardioRunner`** companion controller for interval / lap based
  sessions (running, cycling, rowing, jump rope, HIIT). Same lifecycle
  shape as `WorkoutRunner`, same `RunnerStorage` interface, defaults to
  the `cardio` slot so a strength runner and a cardio runner coexist in
  the same app.
- New cardio models: `CardioPlan`, `CardioInterval` (+ `CardioPhase`),
  `CardioLap` (+ `CardioLap.computed` for auto-pace), `CardioResult` with
  `totalLaps` / `totalDistanceMeters` / `totalWorkTime` / `avgPacePerKm`,
  `CardioRunnerState`.
- New cardio widgets in the same dark-first look:
  `CardioRunnerPanel`, `CardioRunnerScreen`, `CardioQuickRunner`,
  `CardioResultsView`, `CardioRunnerStatusChip` / `Banner` / `BottomBar`,
  `CardioRunnerScope`.
- `DefaultCardioPlans` with built-in plans: Easy 5K, Tabata, Walk/Run,
  Rower 4×500 m, Bike pyramid, Jump-rope EMOM.
- `DefaultPlans` with built-in strength plans (Push / Pull / Legs / …).
- New `RunnerScope` (`InheritedNotifier`) for widget-tree access.
- New `WorkoutRunnerTheme` + `WorkoutRunnerThemeData` design tokens for the
  bundled widgets. Ships with a dark-first fitness look out of the box,
  shared by strength + cardio widgets.
- All strength UI rewritten from scratch in the new look (`RunnerPanel`,
  `QuickRunner`, `ResultsView`, status indicators, `SetRow`,
  bottom-sheet set input, rest strip).
- Stream API on both controllers: `runner.finished` emits results in
  addition to the optional `onFinished` callback.
- New `WorkoutPlanBuilder` fluent API for creating strength plans with
  chained `exercise()` / `set()` calls.
- New plan validation helpers: `plan.validate()` and
  `WorkoutRunner.canStart(plan)`.
- New lifecycle callbacks: `WorkoutRunner.onSetCompleted`,
  `onExerciseChanged`, `onRestStarted`, plus `CardioRunner.onIntervalCompleted`,
  `onPaused`, and `onResumed`.
- Pluggable `RunnerStorage` with `PrefsRunnerStorage` and
  `InMemoryRunnerStorage` implementations. Slots make multi-user and
  parallel strength/cardio setups possible.
- Standalone `example/` Flutter app (no longer mis-nested under `lib/`)
  with four tabs: Home, Exercises, Cardio, History.
- Full docs in `doc/` (architecture, API, widgets, storage, theming,
  migration) covering both runners.

### Bug fixes
- `WorkoutRunnerState.fromJson` could throw on `activeExerciseIndex` (was
  cast to `int` instead of `int?`).
- `WorkoutExercise.fromJson` previously force-unwrapped muscle lookup and
  could crash on unknown muscles. Muscles now round-trip via their own JSON.
- Auto-resume now restores the elapsed timer correctly.
- `ExerciseCategorie` typo corrected to `ExerciseCategory`.
- `WorkoutRunner.logSet` now returns `false` for invalid indices instead of
  throwing.

### Renamed / removed
- `runner` singleton → instantiate `WorkoutRunner()` and inject via
  `RunnerScope`.
- `WorkoutRunnerController` → `WorkoutRunner`.
- `WorkoutRunnerScope` → `RunnerScope` (file `widgets/workout_runner_scope.dart`
  → `widgets/runner_scope.dart`).
- `WorkoutResultsView` → `ResultsView` (class now matches the file name
  `widgets/results_view.dart`).
- `CardioStatusChip` / `CardioStatusBanner` / `CardioStatusBottomBar` →
  `CardioRunnerStatusChip` / `CardioRunnerStatusBanner` /
  `CardioRunnerStatusBottomBar` (parity with the strength
  `RunnerStatus*` family). New `CardioRunnerStatusAppBarAction`.
- `runner.configure(autoResume: …)` → `WorkoutRunner` constructor + explicit
  `tryAutoResume()`.
- `runner.onWorkoutFinished` → `runner.finished` stream (callback variant
  kept as `runner.onFinished`).
- `runner.changeExerciseIndex` → `runner.showExercise`.
- `runner.finishActiveSet` → `runner.finishCurrentSet` (now takes optional
  `weight` and `Duration rest`).
- `ExerciseCategorie` → `ExerciseCategory`.
- `WorkoutExercise.desc` → `WorkoutExercise.description`.
- `defaultExercises` global → `DefaultExercises.all`.

### API contract tightening
Methods that previously returned `void` and silently no-op'd on invariant
violations now return `bool` (or `Future<bool>`), letting consumers detect
when a call was a no-op. Affected methods:

- `WorkoutRunner.pause()` / `resume()` → `Future<bool>`
- `WorkoutRunner.showExercise(int)` → `bool`
- `WorkoutRunner.setActiveExercise(int)` → `bool`
- `WorkoutRunner.clearActiveExercise()` → `bool`
- `WorkoutRunner.skipRest()` → `bool`
- `CardioRunner.pause()` / `resume()` → `Future<bool>`
- `CardioRunner.skipInterval()` → `Future<bool>`
- `CardioRunner.jumpToInterval(int)` → `Future<bool>`

## 0.0.5
* Bug-fix for finish workout from default screen callback.

## 0.0.4
* UI optimisations.

## 0.0.3
* Default muscle, exercise and category data.
* Global finish hook on the result model.
* Detailed `WorkoutResult` shape.

## 0.0.2
* Minor edits.

## 0.0.1
* Initial release.
