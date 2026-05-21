# workout_runner_flutter — Roadmap

Reihenfolge nach Abhängigkeiten: Phase 1 zuerst (Model-Foundation), danach läuft 2 & 3 parallel, dann 4, dann 5. Jede Phase sollte additive APIs bevorzugen und bestehende JSON-Formate rückwärtskompatibel lesen.

**Release-Prinzipien**
- Keine Breaking Changes ohne Migrationseintrag und Fallback beim JSON-Read.
- Neue Runner-Features zuerst als pure Controller-/Model-API bauen, UI danach.
- Alles, was Sound, Haptics, Backend, Auth oder Wearables betrifft, bleibt als Hook/Interface im Plugin und als Implementierung beim App-User.
- Jede neue Public API braucht mindestens Model-/Controller-Tests und ein README- oder Docs-Beispiel.

**Langfristige Vision**
- Core Engine: pure Models, Runner-State-Machines, Validation, Export, History,
  Stats. UI-unabhängig, deterministisch testbar.
- UI Kit: Drop-in Screens, Editors, Result Views, Stats Cards und Picker im
  bestehenden Fitness-Look, aber mit Builder-Slots anpassbar.
- Intelligence Layer: Progressive Overload, PR Detection, Empfehlungen,
  Suche/Filter und Template-Generierung.
- Ecosystem Layer: Storage-/Health-/Backend-Adapter als separate Packages,
  damit `fitness_workout` selbst schlank bleibt.

**North-Star Flow**
`Create Plan → Run Session → Finish Result → Save History → Show Progress → Suggest Next Workout`

Das Plugin sollte diesen Flow mit wenigen Zeilen Code ermöglichen.

---

## Phase 0 — API Hardening & Pub Readiness ✅ done

- [x] 0.1 Public API Audit
- [x] 0.2 Pub.dev Polish
- [x] 0.3 Stability Matrix

---

## Phase 1 — Model Foundation ✅ done

Additive Modell-Erweiterungen, alle rückwärtskompatibel.

- [x] **1.1 Set Types** — `SetType { working, warmup, drop, failure, amrap, timed }` auf `WorkoutSet` & `PerformedSet`
- [x] **1.2 Time-Based & AMRAP Sets** — `WorkoutSet.targetDuration`, `currentActiveSet` + `currentSetRemaining` + `isCurrentSetTimed`, `onTimedSetTargetReached`
- [x] **1.3 Rest Timer Hooks** — `onRestTick` / `onRestCompleted` / `onRestSkipped` + `extendRest(extra)` + `restTotal`
- [x] **1.4 Result Export** — `WorkoutResult.toCsv()` / `CardioResult.toCsv()` mit RFC-konformem Escaping (`lib/src/internal/csv.dart`)
- [x] **1.5 Versioned JSON & Migration Safety** — `kPluginSchemaVersion` in allen Top-Level-JSONs, Legacy-Reader, MIGRATION.md Section, Golden Tests
- [x] **1.6 History Interface** — `WorkoutHistoryStorage` + `InMemoryWorkoutHistoryStorage`
- [x] **1.7 Strength Pause / Resume** — `pause()/resume()`, `pausedFor` aus `elapsed` ausgenommen, `onPaused`/`onResumed(delta)`
- [x] **1.8 Energy Expenditure (MET → kcal)** — `EnergyEstimator` + Defaults, `met` auf Exercise/Interval/Lap/PerformedExerciseDetails, `kcal({bodyWeightKg})` auf beiden Results, `bodyWeightKg` auf beiden Runnern
- [x] **1.9 DX Helpers** — `WorkoutPlan.estimatedDuration` / `previewSummary` / `cloneWithId`, `WorkoutExercise.cloneWithId`, `CardioPlan.previewSummary` / `cloneWithId`, `CardioPlanBuilder`

---

## Phase 2 — UI & Theme Polish

Plugin liefert UI — gehört in den Scope.

### 2.1 Theme Helper Erweiterung ✅ done
- [x] `WorkoutRunnerTheme` um Set-Type-Farben, Timer-Styles, Rest-Overlay-Tokens
- [x] `.light()` / `.dark()` / `.fromColorScheme(ColorScheme)` Factories
- [x] `theme.accentFor(SetType)` Helper
- [x] `doc/THEMING.md` Sections für Set-Type-Accents, Timer/Rest-Tokens, ColorScheme

### 2.2 Accessibility ✅ done
- [x] Min 48 dp Touch Targets in `RunnerPillButton`, `_StepButton` ist bereits 56×56
- [x] `Semantics` Labels für `HeroStepper`-Buttons, value-Region, `TimerText` mit spoken value, `RestOverlay` als liveRegion
- [x] `MediaQuery.disableAnimations` respektiert in `rest_overlay` und `runner_pill_button`
- [x] `restProgressColor` / `restProgressTrackColor` / `restBackdrop` aus Theme-Tokens statt hardcoded

### 2.3 Set-Type-aware UI ✅ done
- [x] Type-Pill in `_SetMeta` für warmup/drop/failure/amrap/timed (color from `theme.accentFor(type)`)
- [x] AMRAP/Timed Target-Line zeigen Dauer statt Reps („AMRAP — 01:00", „Hold 00:45")
- [x] Border + Badge nutzen `theme.accentFor(type)` für pending Sets
- [x] Warmup-Sets visuell gedämpft (opacity 0.85) wenn nicht aktiv/done
- [x] Running timed/AMRAP Sets zeigen Countdown (`currentSetRemaining`) statt Stoppuhr, switch to `success` Farbe bei reached target

### 2.4 Widget Customization Slots ✅ done
- [x] `ResultsView.statBuilder` + öffentliche `ResultsStatTile`
- [x] `CardioResultsView.statBuilder` + öffentliche `CardioResultsStatTile`
- [x] `RunnerPanel.headerBuilder` (reagiert auf Runner-State) + `finishButtonBuilder`
- [x] `SetRow.trailingBuilder` + `SetRowSlotData` + `SetRowState` Enum
- Defaults unverändert wenn Builder nicht gesetzt
- `SetInputSheet.builder` / `exerciseCardBuilder` aufgeschoben — größere Eingriffe, separater Issue

### 2.5 Localization 🚧 in progress (owner: claude)
- Sichtbare Strings zentralisieren, keine hardcoded Labels in Widgets
- `WorkoutRunnerLocalizations` mit Default English
- Optional German-Beispiel im Example-App
- Zahlen-/Dauerformatierung lokalisierbar machen

### 2.6 Responsive & Reduced Motion QA
- Mobile Small, Mobile Large, Tablet und Desktop Smoke-Screenshots
- `MediaQuery.disableAnimations` auch in Navigation/Transitions beachten
- Overflow-Tests für lange Plan-, Exercise- und Interval-Namen

### 2.7 CRUD-Editoren als Drop-in Widgets

Plugin liefert UI-Sheets/Screens, damit Apps Plans/Exercises/Muskeln nicht
selbst bauen müssen. Lehnt sich an den bestehenden Fitness-Look (Hero-
Stepper, RunnerCard, Pill-Buttons).

- `ExerciseEditorSheet({existing, onSave})` — Name, Beschreibung,
  Category-Picker, Muscle-Picker (multi-select), MET-Stepper, Notes.
  *create* und *edit* in einem Sheet.
- `MuscleEditorSheet({existing, onSave})` — Name + Gruppe.
- `CategoryEditorSheet({existing, onSave})` — Name + Beschreibung.
- `PlanEditorScreen({existing, onSave})` — Reorderable Übungs-Liste,
  per-Exercise Set-Bearbeitung (Sets `+`/`-`, Hero-Stepper für Reps /
  Weight / Rest), Validation-Badge gekoppelt an `WorkoutPlanValidation`.
- `CardioPlanEditorScreen` — analog, Interval-Liste mit Phase / Target
  Duration / Distance / Intensity.
- `CatalogPickerSheet({type, onPick})` — wiederverwendbarer Picker für
  defaults + user-defined.
- `MetaFieldRow` — kompakte editierbare Zeile (Label + Stepper / Text)
  als Building Block.
- Flow-Integration: `QuickRunner` / `QuickCardioRunner` *Add plan* Tile
  öffnet den passenden Editor. Active Card → Kebab → *Edit exercise* /
  *Add custom set*.

### 2.8 Runner UI Refactor — Premium Session Experience

Der Runner muss sich wie eine fertige Fitness-App anfühlen, nicht wie eine
Demo-Komponente. Ziel: bessere Fokusführung während einer Session, weniger
visuelles Gewicht, klarere Actions, bessere mobile Ergonomie und starke
Customization ohne Fork.

#### 2.8.1 UX-Ziele
- First screen beantwortet sofort: *Was mache ich gerade? Was kommt als
  Nächstes? Was ist die wichtigste Aktion?*
- Primäre Action immer eindeutig: Start Set, Finish Set, Continue, Finish
  Workout
- Weniger Card-Stapel, mehr kompakte Session-Flächen und klare Hierarchie
- Aktiver Set-/Rest-/Timed-State ist aus 1 m Entfernung erkennbar
- Einhandbedienung auf Mobile: wichtige Controls im unteren Daumenbereich
- Keine Layoutsprünge bei Timer-Ticks, langen Namen oder Set-Type-Badges

#### 2.8.2 Neue UI-Architektur
- `RunnerScaffold` als gemeinsames Layout für Strength und Cardio
- `SessionHeader` für Planname, elapsed, progress, pause/resume
- `FocusActionBar` als sticky Bottom-Bar mit primärer/sekundärer Action
- `ExerciseFocusCard` ersetzt schwere Exercise-Cards im laufenden Flow
- `SetTimeline` zeigt Sets als kompakte horizontale/vertikale Timeline
- `NextUpStrip` zeigt nächstes Set / nächste Übung / nächsten Rest
- `RestOverlay` wird zu optionalem Fullscreen/Bottom-Sheet-Modus
- `RunnerPanel.compact` / `RunnerPanel.focused` Layout-Modi

#### 2.8.3 Strength Flow
- Pending Exercise: Start-CTA prominent, Sets darunter scanbar
- Running Set: großer Timer/Countdown, Target kompakt, Finish CTA sticky
- Done Set: editierbar, aber nicht lauter als nächster Pending-State
- Rest: Rest-Timer übernimmt Fokus, Quick Actions: Skip, +15s, +30s
- Timed/AMRAP: Countdown + Rep-Counter parallel, keine normale Rep-only UI
- Warmup/Drop/Failure: Set-Type visuell klar, aber nicht überdekoriert

#### 2.8.4 Cardio Flow
- CardioRunnerPanel nutzt dieselben Layout-Prinzipien wie Strength
- Aktuelles Interval als Fokusfläche, Laps als Timeline
- Zielwerte: pace, distance, duration, HR-zone kompakt und scanbar
- Complete/Skip/Pause/Finish in konsistenter Action-Bar
- Auto-advance-State sichtbar: "Auto next in 00:12"
- Free-form Cardio ohne targetDuration wirkt nicht leer oder kaputt

#### 2.8.5 Customization & API
- Bestehende Widgets bleiben nutzbar; Refactor ist additive
- Builder-Slots:
  `sessionHeaderBuilder`, `focusActionBarBuilder`, `exerciseFocusBuilder`,
  `setTimelineBuilder`, `nextUpBuilder`
- Style über `WorkoutRunnerThemeData`, keine hardcoded Colors
- Public Slot-Data-Klassen statt private UI-State-Leaks
- Deprecated UI-Aliases erst nach stabiler neuer API markieren

#### 2.8.6 Accessibility & Responsiveness
- Alle Touch Targets mindestens 48 dp
- Semantics für Timer, Progress, Primary Action und Set Status
- `MediaQuery.disableAnimations` überall respektieren
- Mobile Small, Mobile Large, Tablet, Desktop Layouts
- Lange Exercise-/Plan-/Interval-Namen dürfen nichts überdecken
- Landscape-Modus: Header kompakter, Timeline und Fokus nebeneinander

#### 2.8.7 Visual QA
- Playwright/Flutter screenshot smoke tests für:
  idle, pending, running set, timed set, rest, finished, cardio interval
- Canvas-/Screenshot-Checks gegen blank/overflow/overlap
- Light/Dark Theme Screenshots
- Metric/Imperial String-Längen testen
- Reduced Motion Snapshot

#### 2.8.8 Migration Plan
- Neue Komponenten zuerst parallel einführen
- Example-App bekommt Toggle: Classic Runner vs. Focus Runner
- Nach Feedback: `RunnerPanel` default auf neuen Focus Mode umstellen
- Classic Mode mindestens eine Minor-Version behalten
- `doc/MIGRATION.md` mit Vorher/Nachher-Snippets

#### 2.8.9 Acceptance Criteria
- Eine komplette Strength-Session ist mit einer Hand bedienbar
- Keine sichtbaren Overflows auf 360 px Breite
- Primäre Action ist in jedem State eindeutig
- Analyze/Test/Screenshot-Smoke grün
- README zeigt neuen Runner als Standard
- Alte Builder-Slots funktionieren weiter oder haben dokumentierte Aliases

---

## Phase 3 — Composition

Baut auf Phase 1 auf — Runner-State-Machine wird non-trivial.

### 3.1 Supersets / Circuits
- `WorkoutBlock { exercises, rounds, restBetween, restAfterBlock }`
- `WorkoutPlan.blocks` zusätzlich zu `exercises` (beides erlaubt)
- Rest-Logic: zwischen Übungen im Block ≠ zwischen Runden ≠ nach Block
- UI: `block_view.dart` mit Runden-Indikator

### 3.2 Exercise Substitution mid-session
- `WorkoutRunner.substituteExercise(index, replacement)`
- History bleibt erhalten: `PerformedExercise.substitutedFrom?`
- UI: Dialog/Sheet im `runner_panel`

### 3.3 Plan Editing API
- `WorkoutRunner.addExercise`, `removeExercise`, `moveExercise`
- `replaceSet`, `duplicateSet`, `reorderSets`
- Regeln für bereits performed Sets dokumentieren
- Builder und Validation müssen editierte Pläne sauber abdecken

### 3.4 Exercise Library Metadata
- `ExerciseEquipment` (`barbell`, `dumbbell`, `machine`, `bodyweight`, ...)
- Movement Pattern: `push`, `pull`, `squat`, `hinge`, `carry`, `core`
- `difficulty`, `unilateral`, `aliases`, `searchTerms`
- Grundlage für Filter, Templates und Substitution

### 3.5 Custom-Catalog Storage (CRUD Backbone)
- `CustomEntityRegistry<T>` — user-editierte Einträge neben den
  `Default*`-Catalogs persistiert via `RunnerStorage`.
- Neue `RunnerStorage`-Slots: `exercises`, `muscles`, `categories`, `plans`,
  `cardio_plans`. Alle optional / backward-compatible.
- Convenience-Reader `Catalog.exercises` etc. mergt Defaults +
  Custom-Registry. Sucht zuerst in Custom (Override-Möglichkeit).
- `WorkoutPlanBuilder.fromPlan(plan)` + `WorkoutExerciseBuilder` als
  Seed-Helper für Editor-Sheets.
- `WorkoutRunner.replacePlan(plan)` — laufenden Plan tauschen ohne
  performed sets zu verlieren (für mid-session Edits aus dem Editor).

### 3.6 Generic Session Engine
- `WorkoutSession` als übergreifendes Ausführungsmodell für Strength, Cardio,
  AMRAP, Timed Sets, Supersets und Circuits
- `SessionStep`, `SessionStepType`, `SessionProgress`, `SessionResult`
- Bestehende `WorkoutRunner` / `CardioRunner` bleiben Facades über der Engine
- Ziel: weniger Sonderfälle in UI und Persistenz
- Migrationspfad: erst intern nutzen, später optional public machen

---

## Phase 4 — Smart Helpers

Optionale Add-ons, keine Pflicht für Plugin-User.

### 4.1 Progressive Overload Engine
- `OverloadSuggestion.from(history, strategy)`
- Strategien: `linear` (+2.5 kg), `doubleProgression` (Reps zuerst), `rpe`
- Pure function — kein UI-Zwang
- Optionaler Widget-Helper `OverloadHintBadge`

### 4.2 Stats Helpers
- `WorkoutStats.volume(results)` (kg × reps)
- `.prs(results)` (Personal Records pro Exercise)
- `.streak(results)` (consistency)
- `.weeklySummary(results)`
- Optionale Widgets in `lib/src/widgets/stats/`

### 4.3 Personal Record Detection
- Max Weight pro Exercise
- Max Reps at Weight
- Estimated 1RM
- Best Volume Set
- Cardio: longest distance, fastest pace, longest work time
- Result-Annotations: `isPr`, `prType`, `previousBest`

### 4.4 Recommendation Helpers
- `NextSetSuggestion.fromLastResult(...)`
- `RestSuggestion.fromRpe(...)`
- `DeloadSuggestion.fromFatigue(...)`
- Pure functions, keine UI-Pflicht
- Optional: kleine Hint-Badges für UI-Integration

### 4.5 Filtering & Search Helpers
- `ExerciseSearch.query(exercises, text)`
- Filter nach Muscle, Equipment, Movement Pattern, Category
- Alias-aware Suche
- Nützlich für Substitution und Plan-Editor

### 4.6 Plan Generator Helpers
- `PlanGenerator.fullBody(...)`
- `PlanGenerator.pushPullLegs(...)`
- `PlanGenerator.fromEquipment(...)`
- Berücksichtigt verfügbare Tage, Equipment, Ziel (`strength`, `hypertrophy`,
  `conditioning`) und Erfahrung
- Liefert normale `WorkoutPlan`s, keine eigene Runtime

### 4.7 Fatigue & Readiness Signals
- Pure Helpers für einfache Readiness-Heuristiken aus History
- Eingaben optional: RPE, verpasste Reps, Schlaf/Readiness aus App-Schicht
- Ausgabe: `TrainingReadiness`, `DeloadSuggestion`, `VolumeAdjustment`
- Keine medizinischen Claims, nur Trainingsheuristik

---

## Phase 5 — Content

### 5.1 Workout Templates
- `default_plans.dart` ausbauen: PPL, FullBody, 5x5, Upper/Lower
- Als `WorkoutPlan` Konstanten — User kann clonen & customizen

### 5.2 Cardio Presets
- `default_cardio_plans.dart`: HIIT, LISS, Tabata, Pyramid
- Konfigurierbar über Builder-Pattern

### 5.3 Exercise Library Ausbau
- Mehr Bodyweight-, Dumbbell-, Barbell- und Machine-Übungen
- Exercise-Metadaten aus Phase 3.4 befüllen
- Alternativen/Substitutionsgruppen pflegen
- Beispiele: Home Gym, Beginner, Strength, Hypertrophy

### 5.4 Example App als Showcase
- Eigene Tabs für Builder, History, Stats, Plan Editing
- Demo für Custom Storage / History Storage
- Demo für Localization und Theme-Switch
- Golden-ish Smoke-Screenshots für Kernflows

### 5.5 Documentation Recipes
- "Build a workout app in 10 minutes"
- "Use your own backend"
- "Create custom exercises and plans"
- "Add history and stats"
- "Theme the runner"
- "Run strength and cardio side by side"

---

## Phase 5.5 — Practical Training Utilities

Zweckmäßige Features, die echte Trainings-Apps schnell besser machen, ohne
gleich große Architektur-Umbauten zu erzwingen.

### 5.5.1 Unit System ✅ done (opus-1m)
- [x] `MeasurementSystem.metric` / `imperial` enum + defensive
      `fromId` serializer fallback to `metric`.
- [x] Gewicht: `kgToLb` / `lbToKg` + `weightToSystem` / `weightFromSystem`
      (NIST-exact `kKgPerLb = 0.45359237`).
- [x] Distanz: m ↔ km / mi / ft via `distanceToSystem` /
      `distanceFromSystem`, `metersToFeet` etc. (exact international mile
      and foot constants).
- [x] Pace: `pacePerKm({duration, distanceMeters})` (null for zero inputs)
      and `pacePerKmToPerMile` / `pacePerMileToPerKm` + system helpers.
- [x] Speed: `metersPerSecond`, `mpsToKmh`, `mpsToMph`, `speedToSystem`.
- [x] `WorkoutRunnerUnitFormatters` with `weight` / `distance` / `pace` /
      `speed` formatters (short-unit fallback for distances < 1 km / mile)
      plus `*Unit(system)` label helpers.
- [x] Storage stays metric — formatters are display-only.
- [x] Tests: 29 unit tests under `test/units/`.
- [x] Public exports via `lib/fitness_workout.dart`.

### 5.5.2 Workout Notes
- Notizen pro Workout-Session
- Notizen pro Exercise im Result
- Notizen pro Set / Lap
- `WorkoutRunner.updateSessionNote(...)`
- Results-Views zeigen Notes optional als kompakte Timeline

### 5.5.3 Session Rating
- Nach Finish: `mood`, `difficulty`, `energy`, `sleepQuality`,
  `overallRating`
- Optionaler `SessionRatingSheet`
- Rating fließt später in Readiness / Deload / Recommendations ein
- Keine Pflichtfelder, damit Runner-Flow schnell bleibt

### 5.5.4 Partial / Abandoned Results
- `WorkoutCompletionStatus { completed, partial, cancelled, abandoned }`
- `cancel(savePartial: true)` erzeugt optional ein Result
- Result markiert erledigte Sets/Laps und offenen Rest
- History kann abgebrochene Sessions trotzdem auswerten

### 5.5.5 Undo Last Action
- `WorkoutRunner.undoLastAction()`
- Rückgängig für: `finishCurrentSet`, `logSet`, `skipRest`,
  `completeInterval`, `skipInterval`
- Kleine Action-History im Runner-State, persisted für Auto-Resume
- UI: Snackbar mit Undo nach Set/Lap-Completion

### 5.5.6 Workout Tags
- Tags auf `WorkoutPlan`, `WorkoutResult`, `CardioPlan`, `CardioResult`
- Beispiele: `strength`, `hypertrophy`, `rehab`, `home`, `gym`, `deload`
- Tag-Filter für History und Plan Picker
- Tags bleiben freie Strings, optionale Helper für bekannte Tags

### 5.5.7 Draft / Scheduled Workouts
- `scheduledAt`, `startedAt`, `completedAt`, `skippedAt`
- Lightweight Planning ohne volles Program-System
- `ScheduledWorkout` DTO: Plan + Datum + Status
- Example-App: einfache "Today" / "Upcoming" Liste

### 5.5.8 Workout Import
- `WorkoutPlan.fromImportJson(...)`
- Conflict Handling bei gleicher ID: `replace`, `duplicate`, `skip`
- `ImportResult` mit imported/skipped/errors
- Kompatibel mit späterem Backend Sync

### 5.5.9 Share Helpers
- `WorkoutResult.toShareText()`
- `WorkoutResult.toMarkdown()`
- `CardioResult.toShareText()` / `toMarkdown()`
- Keine Social-Integration, nur pure Formatting Helpers

### 5.5.10 Exercise Favorites & Recents
- Favorite Exercises
- Recently Used Exercises
- Most Used Exercises aus History ableitbar
- Picker priorisiert Favorites/Recents vor großem Catalog

### 5.5.11 Warmup Generator 🚧 in progress (owner: opus-1m)
- `WarmupGenerator.forSet(weight, reps, strategy)`
- Strategien: `linear`, `powerlifting`, `hypertrophy`
- Ausgabe: Liste von `WorkoutSet(type: SetType.warmup, ...)`
- Optional direkt im Plan Editor anwendbar

### 5.5.12 Plate Calculator ✅ done (opus-1m)
- [x] `PlateCalculator.load({targetWeight, barWeight, availablePlates,
      plateCounts?})` — pure greedy heaviest-first algorithm, unit-blind so
      one API serves kg and lb.
- [x] `PlateLoading` result with `perSide`, `achieved`, `delta`, `isExact`,
      `isEmptyBar`, `isBelowBar`, `totalPlateWeight`. 0.5 mg epsilon to
      neutralise IEEE-754 noise.
- [x] Optional `plateCounts: Map<double, int>` parameter to model a finite
      rack (pairs are consumed in twos, so `stock < 2` skips the plate).
- [x] `DefaultBars` constants: men's / women's Olympic kg + lb, EZ curl.
- [x] `DefaultPlateSets.standardKg` / `standardLb` + `forSystem(...)` /
      `defaultBarForSystem(...)` to pick per `MeasurementSystem`.
- [x] Non-positive / unsorted plate inputs are tolerated (filtered + sorted
      internally). Inputs below the bar return `isBelowBar: true` with an
      empty load.
- [x] 15 unit tests covering exact / partial / undershoot / bar-only /
      below-bar / finite-stock / unsorted / non-positive paths.
- [x] Public export via `lib/fitness_workout.dart`.
- Optional `PlateCalculatorSheet` UI is deferred — the spec only required
  the pure helper; the sheet can be picked up in a follow-on phase.

### 5.5.13 Rest Presets
- Globale, planweite und exercise-spezifische Rest-Presets
- Beispiele: `strength: 180s`, `hypertrophy: 90s`, `endurance: 45s`
- `RestPreset.resolve(plan, exercise, set)`
- UI: Quick chips im SetInputSheet

### 5.5.14 Workout Completion Rules
- Completion Rules: alle Sets, mindestens X Sets, freie Session,
  bestimmte Pflichtübungen
- Result erhält `completionStatus` und `completionRatio`
- UI kann "Finish anyway?" sauber begründen

### 5.5.15 Auto-save Draft Plan
- Plan Editor speichert Drafts automatisch
- `PlanDraftStorage` Interface
- `resumeDraft`, `discardDraft`, `publishDraft`
- Verhindert verlorene Eingaben bei langen Plan-Edits

### 5.5.16 Personal Equipment Profile
- User kann verfügbares Equipment hinterlegen
- `EquipmentProfile` für Plan Generator, Exercise Filter und Plate Calculator
- Beispiele: Home Gym, Commercial Gym, Bodyweight Only
- Keine Account-Pflicht, lokal/adapterbasiert

### 5.5.17 Target Pace / Target Zone Alerts
- CardioInterval kann Ziel-Pace oder HR-Zone beschreiben
- Runner liefert Hook: `onTargetZoneChanged(inZone/outOfZone)`
- Keine Sensor-Integration im Core; App liefert Messwerte
- UI zeigt Zone-Status optional im CardioPanel

### 5.5.18 Exercise Alternatives
- `ExerciseAlternativeGroup`
- Alternative nach Equipment, Muscle, Movement Pattern
- Nutzt Exercise Metadata und Search
- Substitution Sheet kann sinnvolle Vorschläge anzeigen

### 5.5.19 Deload / Recovery Week Templates
- Leichte Plan-Varianten aus bestehendem Plan generieren
- Regeln: weniger Sets, weniger Gewicht, weniger Intensität
- Pure Helper: `DeloadPlan.from(plan, strategy)`
- Gute Brücke zu Fatigue & Readiness

### 5.5.20 Form Cues & Technique Notes
- Exercise-level `cues`
- `commonMistakes`
- `setupInstructions`
- UI: optionaler Info-Drawer im RunnerPanel
- Content bleibt lokal im Exercise Catalog, keine Videos nötig

---

## Phase 6 — Adapter Ecosystem

Separate Packages, nicht zwingend Teil des Core-Pakets. Core definiert nur
Interfaces und Export-Formate.

### 6.1 Storage Adapters
- `fitness_workout_hive`
- `fitness_workout_isar`
- `fitness_workout_supabase`
- `fitness_workout_firestore`
- Alle Adapter implementieren `RunnerStorage` und optional
  `WorkoutHistoryStorage`

### 6.2 Health Platform Adapters
- `fitness_workout_healthkit`
- `fitness_workout_google_fit`
- Import/Export über klare DTOs, keine direkte Pflichtabhängigkeit im Core
- Wearables bleiben separate App-/Adapter-Schicht

### 6.3 Backend Sync Contracts
- DTOs für Conflict-safe Sync: `updatedAt`, `deletedAt`, `source`, `schemaVersion`
- Merge-Strategien dokumentieren, aber nicht erzwingen
- Offline-first Apps sollen auf den Interfaces aufbauen können

---

## Phase 7 — Developer Tooling

Alles, was Maintainer- und Nutzer-Erfahrung verbessert.

### 7.1 Example-Driven Tests
- Beispiel-App-Flows als Widget-/integration tests
- Smoke-Test: Plan erstellen → Workout starten → Set finishen → Result speichern
- Cardio Smoke-Test analog

### 7.2 Screenshot & Visual QA
- Script für Screenshots der wichtigsten Widgets
- Desktop/Mobile Viewports
- Optional als Assets für README/pub.dev

### 7.3 API Snapshot Tests
- Public exports snapshotten
- Breaking API Changes vor Release sichtbar machen
- Deprecated APIs gezielt tracken

---

## Phase 8 — Performance, Scale & Robustness

Wenn Apps das Paket ernsthaft nutzen, werden History, Catalogs und UI-Listen
groß. Diese Phase hält das Paket schnell und vorhersehbar.

### 8.1 Large History Performance
- Benchmarks für 1k / 10k / 100k Results
- Stats-Helpers müssen lazy oder inkrementell arbeiten können
- Pagination-Kontrakte für `WorkoutHistoryStorage`
- Keine O(n²)-Scans in häufigen UI-Pfaden

### 8.2 Catalog Indexing
- `ExerciseIndex` für schnelle Suche nach Name, Alias, Muscle, Equipment
- Index rebuild nur bei Catalog-Änderung
- `CatalogSnapshot` als immutable View für UI und Search
- Optional fuzzy search ohne schwere Dependency

### 8.3 Timer Reliability
- Drift-Tests für Global-, Set-, Rest- und Interval-Timer
- Recovery nach App-Suspend / Resume dokumentieren
- Persistenz-Frequenz begrenzen, aber Hard-Kill-Datenverlust klein halten
- Einheitliche Clock-Abstraktion für Tests (`RunnerClock`)

### 8.4 Error Handling Model
- `RunnerActionResult` für komplexere Mutationen statt nur `bool`
- Fehlercodes: `noActivePlan`, `indexOutOfRange`, `alreadyRunning`,
  `invalidPlan`, `storageFailed`
- UI kann daraus Snackbars/Dialogs bauen
- Silent no-ops nur dort behalten, wo Flutter-Widget-Konventionen passen

---

## Phase 9 — Privacy, Safety & Compliance

Fitnessdaten sind sensibel. Das Core-Paket soll keine Policy erzwingen, aber
saubere Datenschutz- und Safety-Hooks ermöglichen.

### 9.1 Data Ownership Helpers
- Export aller lokalen Daten als JSON-Bundle
- Delete/clear helpers pro Storage-Slot
- `anonymized()` / `redacted()` DTO-Helper für Debug-Logs und Support
- Keine impliziten Netzwerk- oder Tracking-Funktionen im Core

### 9.2 Health Claim Boundaries
- Dokumentieren: Stats und Empfehlungen sind Trainingsheuristik, keine Medizin
- MET/kcal als Schätzung kennzeichnen
- Readiness/Deload-Suggestions ohne Diagnose-Sprache
- README-Safety-Note für App-Entwickler

### 9.3 Consent & Audit Hooks
- Optionaler Hook vor Health-Export / Adapter-Sync
- `ExportAuditEntry` für Apps, die Sync/Export protokollieren wollen
- Keine Pflicht-Implementierung im Core

---

## Phase 10 — Product Accelerators

Features, die App-Entwicklern direkt “fertige Produktflächen” geben, ohne das
Core-Paket mit Businesslogik zu überladen.

### 10.1 Onboarding Widgets
- `GoalPickerSheet`
- `EquipmentPickerSheet`
- `ExperienceLevelPicker`
- Ausgabe: `PlanGenerationProfile`
- Direkt kompatibel mit `PlanGenerator`

### 10.2 Dashboard Widgets
- `WeeklySummaryCard`
- `PrHighlightsCard`
- `VolumeTrendChart`
- `RecentSessionsList`
- Alles optional, alle Widgets nehmen pure Daten/Stats entgegen

### 10.3 Program Blocks
- `TrainingProgram` mit Wochen, Tagen und geplanten Sessions
- `ProgramProgress` aus History berechenbar
- Templates: Beginner Strength, 5x5, PPL, 10K Base
- Runner bleibt session-fokussiert; Program ist Planungsschicht

### 10.4 Coach Mode Hooks
- Apps können eigene Coaching-Texte einspeisen
- `CoachingMessage` Modell: `severity`, `title`, `body`, `action`
- Engine liefert nur Signale, App formuliert Tonalität
- Keine generative AI im Core, aber saubere Extension Points

---

## Phase 11 — Release Channels & Governance

Damit das Paket langfristig nicht chaotisch wächst.

### 11.1 Release Channels
- `stable`: pub.dev Releases
- `beta`: prerelease tags für größere API-Änderungen
- `experimental`: APIs mit `@experimental` Annotation
- Experimentelle APIs nie in README-Quickstart verwenden

### 11.2 Deprecation Policy
- Deprecated APIs mindestens eine Minor-Version behalten
- Migration-Beispiel direkt am Deprecated Doc-Kommentar
- Entfernen nur in Major-Version
- `doc/MIGRATION.md` enthält Vorher/Nachher-Snippets

### 11.3 Contribution Standards
- Issue Templates: Bug, Feature, API Proposal
- PR Checklist: Tests, Docs, Changelog, Migration
- Architektur-Entscheidungen als kurze ADRs in `doc/adr/`
- Maintainer-Guide für Release-Prozess

### 11.4 API Proposal Process
- Größere Features erst als `doc/proposals/*.md`
- Enthält Motivation, API Sketch, Alternatives, Migration, Tests
- Besonders Pflicht für Session Engine, Storage Adapters, Program Blocks

---

## Quality Gates

- `flutter analyze`
- `flutter test`
- `flutter pub publish --dry-run`
- Public API Änderungen in `doc/API.md`, `README.md`, `CHANGELOG.md`
- JSON-Roundtrip-Test für jedes neue Modellfeld
- Controller-Test für jeden neuen Runner-State-Übergang
- Example-App Smoke-Test für neue UI-Flows
- Public export snapshot prüfen
- Performance-Benchmark bei Stats/Search/History-Änderungen
- Privacy/Safety-Review bei kcal, readiness, export und adapterbezogenen APIs

---

## Out of Scope (bewusst nicht im Plugin)

- Persistenz-Backend (User-spezifisch — Plugin liefert Interfaces + Export)
- Account-/Auth-System
- Social Features
- Wearable-Integrationen (separates Plugin / separate App-Schicht)
- Audio-/Haptic-Implementierungen (nur Hooks im Plugin)
