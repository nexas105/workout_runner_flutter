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
