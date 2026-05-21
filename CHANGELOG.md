# Changelog

## 1.0.0 — first stable release

This is the first stable, fully-featured release of `fitness_workout` on
pub.dev. Earlier `0.0.x` versions were experimental prototypes; the API
has been redesigned from scratch and is now committed to (no expected
breaking changes within the `1.x` line).

The full package ships: the strength + cardio runner controllers, the
drop-in widget kit, editors, intelligence layer (overload, stats, PR
detection, recommendations, readiness, deload, plan generator, warmup
generator), content catalogues + templates, programs, dashboard,
onboarding sheets, privacy / consent / audit helpers, generic sync DTOs,
coach mode hooks, haptic / audio / voice hooks and a focus-mode runner
UI.

### Models & schema
- `SetType { working, warmup, drop, failure, amrap, timed }` on
  `WorkoutSet` and `PerformedSet`, plus `targetDuration` for AMRAP / timed
  work.
- `ExerciseEquipment`, `MovementPattern`, `ExerciseDifficulty`,
  `unilateral`, `aliases`, `searchTerms` are now first-class on
  `WorkoutExercise` (legacy `meta` reads stay supported).
- `WorkoutBlock` + `WorkoutPlan.blocks` for supersets / circuits.
- `PerformedExercise.substitutedFrom` / `PerformedExerciseDetails.substitutedFrom`
  preserve mid-session exercise swaps in result history.
- `kPluginSchemaVersion` stamped into every top-level JSON payload.
- `met` on `WorkoutExercise`, `CardioInterval`, `CardioLap` and
  `PerformedExerciseDetails` enables `WorkoutResult.kcal` /
  `CardioResult.kcal` energy estimates via `EnergyEstimator`.

### Runner controller
- `WorkoutRunner.pause()` / `resume()` with `pausedFor` excluded from
  `elapsed`, plus `onPaused` / `onResumed(delta)` callbacks.
- Rest hooks: `onRestTick`, `onRestCompleted`, `onRestSkipped` and
  `extendRest(extra)` + `restTotal`.
- Timed/AMRAP accessors: `currentActiveSet`, `currentSetTargetDuration`,
  `currentSetRemaining`, `isCurrentSetTimed`, `onTimedSetTargetReached`.
- Plan editing API: `addExercise`, `removeExercise`, `moveExercise`
  (re-maps performed indices), `replaceSet`, `duplicateSet`,
  `reorderSets`, `substituteExercise(index, replacement)`,
  `replacePlan(plan, {preservePerformed})`.
- Optional `bodyWeightKg` field on both runners for live kcal stats.

### Stats, intelligence & helpers
- `WorkoutResult.toCsv()` / `CardioResult.toCsv()` exports.
- `WorkoutStats`, `PersonalRecords` (incl. cardio PRs), `WeeklyWorkoutSummary`,
  `OverloadEngine`, `Recommendations`, `Readiness`, `PlanGenerator`,
  `WarmupGenerator`, `RestPreset`, `DeloadPlan`, `ExerciseSearch`,
  `ExerciseAlternatives`, `ExerciseIndex`, `EquipmentProfile`,
  `ExercisePicker` and `StreamingStats` for paginated history.
- `WorkoutHistoryStorage`, `PagedWorkoutHistoryStorage`,
  `ExerciseFavoritesStorage`, `SessionRatingStorage`,
  `PlanDraftStorage`, `ScheduledWorkoutStorage`,
  `CustomEntityRegistry` (+ in-memory implementations) and a
  `Catalog` merger that layers user-defined entries over the bundled
  defaults.

### Content
- `DefaultExercises`, `DefaultPlans`, `DefaultCardioPlans` are joined by
  `StrengthTemplates` (full-body, PPL, upper/lower, 5x5) and
  `CardioTemplates` (Tabata, HIIT, LISS, Pyramid, easy bike, run/walk).
- `ProgramTemplates` ships a Beginner 5x5, a 4-week PPL and a 10K base
  cardio program through the new `TrainingProgram` model.

### UI
- `WorkoutRunnerLocalizations` + `WorkoutRunnerLocalizationsScope` for
  i18n; bundled English defaults migrated through hot surfaces.
- `WorkoutRunnerThemeData` gains set-type accents, timer/rest tokens and
  a `.fromColorScheme(ColorScheme)` factory.
- **Focus runner** (Phase 2.8): `RunnerFocusPanel` + `SessionHeader`,
  `FocusActionBar`, `ExerciseFocusCard`, `SetTimeline`, `NextUpStrip`.
  The classic `RunnerPanel` stays as the default — opt in to the focus
  layout per screen.
- **Editors**: `PlanEditorScreen`, `CardioPlanEditorScreen`,
  `ExerciseEditorSheet`, `MuscleEditorSheet`, `CategoryEditorSheet`,
  `CatalogPickerSheet`, `MetaFieldRow`.
- **Dashboard**: `WeeklySummaryCard`, `PrHighlightsCard`,
  `VolumeTrendChart` (zero-dep `CustomPainter`), `RecentSessionsList`.
- **Onboarding**: `GoalPickerSheet`, `EquipmentPickerSheet`,
  `ExperienceLevelPicker`, `PlanGenerationProfileSheet`.
- `ResultsView` / `CardioResultsView` gain `statBuilder` + public
  `ResultsStatTile` / `CardioResultsStatTile`; `RunnerPanel` gains
  `headerBuilder` + `finishButtonBuilder`; `SetRow` gains
  `trailingBuilder` (+ `SetRowSlotData`, `SetRowState`).
- Accessibility pass: 48 dp min touch targets, semantics on stepper /
  timer / rest overlay (`liveRegion`), `MediaQuery.disableAnimationsOf`
  respected across rest overlay, runner pill button, set badge, rest
  chip, AnimatedPadding sheets.
- Set-type-aware visuals: warm-up dimmed, AMRAP/timed countdown,
  type pill badges via `theme.accentFor(type)`.

### Feedback layer
- `RunnerHaptics` (+ `DefaultRunnerHaptics`) and `RunnerHapticsBridge`.
- `RunnerAudio` / `SoundCue` / `RunnerVoiceCues` and
  `RunnerAudioBridge` — plugin stays audio-free; apps wire their
  engine.
- `SessionRating` + `SessionRatingStats` + storage.

### Composition & flow
- Set notes / form cues / completion rules / tags via side-car helpers
  (`WorkoutNotes`, `NotesTimeline`, `FormCues`, `WorkoutCompletion`
  + rule hierarchy, `WorkoutTags` + `TagFilter`).
- `WorkoutImport.fromBundle` with replace/duplicate/skip policies,
  `ShareHelpers.toShareText` / `toMarkdown` (strength + cardio),
  `ScheduledWorkout` + query helpers.

### Privacy & sync
- `DataExport.bundle` (versioned, indent-2 JSON) and `Redaction` helpers.
- `ConsentScope` + `ConsentState` + `ConsentGate`, `ExportAuditEntry` +
  `ExportAuditSink` (in-memory impl included).
- Generic `SyncEnvelope<T>` + `SyncMerge` with last-write-wins / source-
  priority / manual strategies and conflict reporting.

### Coach mode hooks
- `CoachingMessage`, `CoachSignal`, `DefaultCoachEngine` with a swappable
  signal → message mapper. Apps provide tonality; plugin only emits
  signals.

### Quality
- API snapshot test (`test/api/public_api_snapshot_test.dart`) guards
  the public surface from accidental regressions.
- Test count grew from 60 (1.0.0) to **685** — covering models,
  controllers, storage, intelligence, widgets and rendering paths.
- `flutter analyze` clean across the whole repo.

See `doc/ROADMAP.md` for the roadmap that drove this release and the
phases that are still open (cardio focus variant, undo, pace-zone
alerts, classic-runner deprecation timeline).

---

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
