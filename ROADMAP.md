# Roadmap

Open items deferred from the cardio-runner review. Roughly ordered by impact;
none are blocking the current API surface.

## Cardio runner

- [ ] **Suppress auto-advance while a lap input sheet is open.** When the
      ticker auto-completes an interval underneath an open input sheet, the
      sheet writes against a stale interval index. Fix by either freezing
      auto-advance while a sheet is up, or by passing the captured interval
      index into the sheet's result and rejecting if it changed.

- [ ] **`logLap()` / `updateLap()` API.** Mirror `WorkoutRunner.logSet()` and
      `updatePerformedSet()` so users can record laps after the fact or edit
      a logged lap (e.g. correcting the distance reading from a watch). Today
      the only way to record a lap is `completeInterval()` during the live
      session.

- [ ] **`addInterval()` / `removeInterval()` on a running plan.** Symmetric
      with `addSetToExercise()` / `removeSetFromExercise()` on the strength
      side. Useful when the user wants to extend a run by another interval
      mid-session, or skip ahead by deleting upcoming intervals.

- [ ] **Plan-scoped warmup/cooldown interval IDs.** `iv_warmup_300` is shared
      across `easy5k`, `walkRun`, `row500s`, etc. Lookup is plan-scoped today
      so this is fine, but any future feature that aggregates intervals across
      plans (history dashboards, "skip warmups I already did this week") will
      hit duplicate keys. Prefix with the plan id.

- [ ] **1-indexed loop in `bikePyramid`.** Generated interval IDs run
      `iv_bike_work_0..4`, inconsistent with every other generated plan which
      uses `_1..n`. Cosmetic, but jarring when grepping.

- [ ] **Debug-only `assert` on `tryAutoResume` exceptions.** Currently swallows
      everything silently — fine in release, but a corrupt JSON in storage
      goes completely unnoticed during development.

- [ ] **Document the double-listener pattern.** Both `finished` (stream) and
      `onFinished` (callback) fire on `finish()`. Consumers regularly wire up
      both by mistake and end up handling the result twice. Either deprecate
      one, or call it out clearly in `doc/API.md`.

- [ ] **Document the semantics of `skipInterval()` vs `completeInterval()`.**
      `skipInterval()` does NOT log a lap; `completeInterval()` does. Easy to
      pick the wrong one and silently lose lap data.

## Strength runner

- [ ] **`jumpToExercise(int index)`.** Cardio has `jumpToInterval`; strength
      only has `showExercise` (paginate the UI) and `setActiveExercise` (which
      no-ops if another exercise is active). A real "jump" — clear the active
      slot and switch — would round out the API.

- [ ] **`skipExercise()`.** Symmetric with `skipInterval()`. Lets the user
      mark an exercise as "skipped without logging" instead of having to
      cancel the workout.

- [ ] **Background time accounting.** Today both runners stop accumulating
      `elapsed` while the app is suspended (Timer.periodic doesn't fire).
      `tryAutoResume` on the cardio side now catches up to a 2 min gap via
      `state.updatedAt`; the strength side derives `elapsed` from wall-clock
      math but can't tell active from paused time across suspension. Spec out
      a unified background-aware elapsed before either runner is used for
      anything where the duration is contractual (subscription billing,
      timed challenges, etc.).

## Shared / infra

- [ ] **Unify the two `RunnerState` shapes.** `WorkoutRunnerState` uses
      wall-clock math (`startedAt + pausedFor`); `CardioRunnerState` snapshots
      `elapsed` and `intervalElapsed`. Both contracts are reasonable in
      isolation but consumer code that handles both gets noisy. Pick one
      strategy and align.

- [ ] **`RunnerStorage` typed migrations.** Schema bumps today rely on
      `fromJson` being defensive (nullable casts, default fallbacks). A
      versioned envelope (`{"v": 2, "data": {...}}`) with explicit upgrade
      hooks would be safer once any field genuinely needs to change shape.

- [ ] **More built-in plans.** Tabata + 5K is enough for a demo. Real apps
      will want a deeper catalogue (5×5, Stronglifts, PPL, Madcow, Couch-to-5K
      week-by-week, Hyrox-style mixed sessions). All composable from the
      existing `DefaultExercises` + `CardioInterval` primitives.

- [ ] **Tests for `CardioRunner`.** The strength side has ~68 controller
      tests; the cardio side has none. At minimum: start/pause/resume/cancel
      lifecycle, `completeInterval` race guard, `tryAutoResume` wall-clock
      catch-up, `start()` discarding a paused session.

## Done in 1.0.0

### Review pass (controllers, persistence, lifecycle)

- Race between auto-advance ticker and manual `completeInterval`
  (re-entrancy guard).
- Persist-race between the periodic snapshot and `cancel()`/`finish()`
  (generation token + awaited in-flight persist).
- `start()` no longer zeroes interval progress when resuming a same-plan
  session.
- Lap-timeline `RangeError` (guard now checks `lap.intervalIndex`, not the
  iteration index).
- `start()` parity: cardio now also checks `state.isActive` before treating
  the previous session as resumable.
- `CardioResult` now carries `discipline` and `meta` from the plan.
- `WorkoutRunner` gained `pause()` / `resume()` / `isPaused`, with
  `pausedFor` persisted in `WorkoutRunnerState`.

### Public API audit (renames, no-op contract)

- `QuickCardioRunner` → `CardioQuickRunner` (file/class match).
- `WorkoutResultsView` → `ResultsView` (file/class match).
- `WorkoutRunnerScope` → `RunnerScope`, file renamed accordingly.
- Cardio status family parity:
  `CardioStatusChip` → `CardioRunnerStatusChip`,
  `CardioStatusBanner` → `CardioRunnerStatusBanner`,
  `CardioStatusBottomBar` → `CardioRunnerStatusBottomBar`,
  new `CardioRunnerStatusAppBarAction`.
- Silent `void` no-ops on lifecycle/navigation methods now return `bool`
  (or `Future<bool>`): `pause`, `resume`, `showExercise`,
  `setActiveExercise`, `clearActiveExercise`, `skipRest`, `skipInterval`,
  `jumpToInterval`.

### Pub.dev polish

- `docs/` → `doc/` (pub.dev layout convention, dry-run warning gone).
- `topics:` added to `pubspec.yaml` (fitness, workout, timer, health,
  widgets).
- `description:` rewritten to surface both runners.

### Stability matrix

- `.github/workflows/ci.yml`: `dart format` check, `flutter analyze
  --fatal-infos --fatal-warnings`, `flutter test`, `flutter pub publish
  --dry-run` on push/PR to `main`.
- Codebase formatted with `dart format` (50 files touched) so the CI
  format check passes on a clean tree.
- Example app gained `android/`, `web/` and `macos/` platforms in
  addition to the existing `ios/`.
- 105 tests pass.
