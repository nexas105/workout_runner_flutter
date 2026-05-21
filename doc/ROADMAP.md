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

### 2.5 Localization ✅ done (framework + hot surfaces)
- [x] `WorkoutRunnerLocalizations` Basis-Klasse mit englischen Defaults (set types, rest overlay, results headers + stat labels, units, actions, formatters)
- [x] `WorkoutRunnerLocalizationsScope` InheritedWidget mit Fallback auf English wenn nicht installiert
- [x] `formatWeight(double)` Hook für lokalisierte Zahl-Formatierung
- [x] Migriert: `RestOverlay`, `ResultsView` + Stats, `CardioResultsView` + Stats, `SetView` Set-Type-Labels + Target-Line
- [ ] Aufgeschoben: vollständige Migration von `SetInputSheet`, `HeroStepper` Dialog-Buttons, `_FinishBar` Strings — separater PR, ändert keinen Public Contract

### 2.6 Responsive & Reduced Motion QA ✅ done (a11y/overflow guards)
- [x] `MediaQuery.disableAnimationsOf` in den restlichen `Animated*` Widgets (`_SetBadge`, `_RestChip`, `SetInputSheet`, `cardio_runner_panel` Sheet, runner_panel `_Dot`)
- [x] Overflow-Guard auf `exercise.name`/`muscles` (maxLines + ellipsis) und `RunnerPillButton` Label (`Flexible` + ellipsis)
- [x] Widget Smoke-Tests für narrow (320×600) und wide (900×700), plus disableAnimations Pfad (`test/widgets/responsive_overflow_test.dart`)
- Screenshots auf Mobile/Tablet/Desktop offen — Quality-Gate-Phase

### 2.7 CRUD-Editoren als Drop-in Widgets ✅ done

Plugin liefert UI-Sheets/Screens, damit Apps Plans/Exercises/Muskeln nicht selbst bauen müssen. Look bleibt konsistent mit dem Fitness-Theme.

- [x] `MetaFieldRow.{text, toggle, stepper, dropdown<T>}` als Building Block (`lib/src/widgets/editors/meta_field_row.dart`, 4 Tests)
- [x] `CatalogPickerSheet<T>` mit Search-Filter, Single/Multi-Select, Static `show<T>(context, ...)` Convenience (`lib/src/widgets/editors/catalog_picker_sheet.dart`, 4 Tests)
- [x] `ExerciseEditorSheet({existing, categories, muscles, onSave})` — Name, Description, Category Picker, Muscle Multi-Picker, MET Stepper, Notes, Unilateral Toggle, Equipment/Movement/Difficulty Dropdowns, Aliases (4 Tests)
- [x] `MuscleEditorSheet({existing, onSave})` — Name + Group (4 Tests)
- [x] `CategoryEditorSheet({existing, onSave})` — Name + Description (4 Tests)
- [x] `PlanEditorScreen({existing, categories, muscles, onSave, onCancel})` — Reorderable Exercise List, inline Set Editor, Validation Badge gekoppelt an `WorkoutPlanValidation`, Save disabled bei Errors (5 Tests)
- [x] `CardioPlanEditorScreen({existing, onSave, onCancel})` — Discipline Dropdown, Reorderable Interval List mit Tap-to-Expand-Advanced (Intensity, Pace, Notes), `previewSummary` Live-Chip (5 Tests)
- [x] Alle Editoren exportiert via `lib/fitness_workout.dart`
- Flow-Integration (QuickRunner *Add plan* Tile → Editor) offen für Phase 2.8

### 2.8 Runner UI Refactor — Premium Session Experience 🚧 components done, RunnerPanel-Migration offen
- [x] `SessionHeader` — Plan-Name + Elapsed + Progress + Pause/Finish Buttons (`lib/src/widgets/focus/session_header.dart`)
- [x] `FocusActionBar` — sticky Bottom-Bar mit Primary CTA + optionalen Secondary Icons (`focus_action_bar.dart`)
- [x] `ExerciseFocusCard` — State-driven Focus-View für Active Exercise (pending / running / resting / empty), Set-Type-aware (`exercise_focus_card.dart`)
- [x] `SetTimeline` — kompakte horizontale Set-Timeline mit Done/Active/Pending Dots (`set_timeline.dart`)
- [x] `NextUpStrip` — kleiner Preview-Strip für nächste Übung (`next_up_strip.dart`)
- [x] `RunnerFocusPanel` — komponiert alle Bausteine + Rest-Overlay + Auto-CTA-State-Machine, mit `sessionHeaderBuilder` / `focusActionBarBuilder` Slots (`runner_focus_panel.dart`)
- [x] Tests: 5 (`test/widgets/focus_runner_test.dart`)
- [ ] Classic `RunnerPanel` als opt-in beibehalten — keine Default-Umstellung
- [ ] Cardio Focus Layout (analog für CardioRunner) offen
- [ ] Example-App Toggle Classic ↔ Focus offen
- [ ] MIGRATION.md Snippets offen

#### 2.8.1 – 2.8.9 (Original-Spec — siehe Component-Liste oben für Status)

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

### 2.9 Runner Feedback & Microinteractions

Pluginziel: der Runner soll sich „nice to use" anfühlen — Haptics, sanfte
Animationen, klares visuelles Feedback an den richtigen Stellen. Alles bleibt
**hook-basiert**: Sound/Haptic-Implementierungen liefert die App, das Plugin
ruft sie an semantisch korrekten Stellen über sauber benannte Callbacks.

#### 2.9.1 Haptic Feedback Hooks ✅ done
- [x] `RunnerHaptics` abstract mit 10 leeren Default-Hooks (`setStarted`, `setCompleted`, `restTickCountdown`, `restCompleted`, `restSkipped`, `timedTargetReached`, `workoutFinished`, `prAchieved`, `pause`, `resume`)
- [x] `DefaultRunnerHaptics` mit `HapticFeedback`-Pattern (timed-target double-tap 80 ms, finish heavy+medium 120 ms, PR triple light 60 ms)
- [x] `NoOpRunnerHaptics` für Tests / Web
- [x] `RunnerHapticsBridge.wire(runner, haptics, {tickAt})` + `wireCardio(...)` — idempotent
- [x] Tests: 10 (`test/feedback/runner_haptics_test.dart`)

#### 2.9.2 Visual Feedback & Microinteractions
- Pulse-Animation auf der aktiven Set-Badge (Glow vom Theme-Accent)
- Flash-Animation auf Set-Abschluss (kurzer Accent-Sweep)
- Konfetti / Stat-Burst beim Workout-Finish (`PartySpark` Widget)
- Number-Counter-Animation auf Reps/Weight (smooth interpolation statt Hard-Cut)
- Hero-Animation zwischen Exercise-Karte und „active focus" State
- Slide/Fade-Transitions im Exercise-Karussell (motion-respecting)
- Mikrointeraktion auf jedem Button: scale 0.96 on press, return on release
- Set-Type-Accent Glow bei AMRAP/Timed Active State
- PR-Highlight-Banner im ResultsView wenn `newRecordsIn` nicht leer

#### 2.9.3 Audio / TTS Hooks ✅ done
- [x] `SoundCue` Enum (countdownTick / restComplete / setComplete / workoutComplete / prAchieved / targetReached) + `RunnerAudio.play(cue)` (abstract, no-op default) + `NoOpRunnerAudio`
- [x] `RunnerVoiceCues` abstract (announceSetStart/End/RestStart/End/WorkoutFinished, alle `Future<void>`) + `NoOpRunnerVoiceCues`
- [x] `RunnerAudioBridge.wire(runner, {audio, voice, tickAt})` + `wireCardio(...)` — idempotent
- [x] Pure dart, keine flutter/services oder Audio-Packages im Core
- [x] Tests: 2 (`test/feedback/runner_audio_test.dart`)

#### 2.9.4 Reduced-Motion & Accessibility-Konsistenz
- Alle Animationen respektieren `MediaQuery.disableAnimations`
- Haptics off-by-default; opt-in via Runner-Konfiguration
- VoiceOver/TalkBack Announce auf wichtige State-Wechsel (Set start / done / rest start / rest end)
- Settings-API: `RunnerFeedbackPreferences { haptics, animations, voice, sounds }` als Bundle, persistierbar

#### 2.9.5 Set Completion Polish
- Optionaler Auto-Save-Hint nach Set-Finish (animiertes Häkchen)
- Velocity-Feedback: wenn `actualReps < target` → orange Tönung, wenn ≥ target → success
- Rep-Counter Bounce bei jedem Tap im Stepper

#### 2.9.6 Rest Overlay Glow-Up
- Smooth Ring-Animation (frame-rate-stabil, nicht per Sekunden-Hopser)
- Optionaler Background-Pattern Pulse synchron zum Atem-Tempo (4-7-8)
- Skip-Button-Hold-to-confirm (200 ms hold) als Anti-Misstap

#### 2.9.7 Stepper Input UX & Layout Robustness
- [x] `HeroStepper` Row in `FittedBox(BoxFit.scaleDown)` — keine Overflows bei engen Spalten (Editor-Sheets, Side-by-side `Reps × Weight`)
- [x] Hint-Text mit `maxLines: 1` + ellipsis
- Slider als Alternative-Input-Mode: `HeroStepperMode { stepper, slider, hybrid }`, Slider zeigt Range + aktuellen Wert, Stepper-Buttons bleiben für ±large
- Tastatur-Quick-Edit: Tap auf Wert (nicht nur Long-Press) öffnet Keyboard direkt; aktueller Wert vorselektiert
- Optional `keyboardType` + `inputFormatters` durchreichen für strikte Dezimal-/Integer-Eingabe
- Hint-Text-Kürzel sollte Localizable sein (aktuell hardcoded EN)

---

## Phase 3 — Composition

Pure-model + Controller-API ist done; UI für Supersets/Substitution-Sheets folgt in Phase 2.7/2.8.

- [x] **3.1 Supersets / Circuits** ✅ — `WorkoutBlock { id, exerciseIndices, rounds, restBetween, restAfterBlock }` + `WorkoutPlan.blocks` additiv + `blockForExerciseIndex` Helper + Validation (`block_id_empty/duplicate/empty/exercise_index_out_of_range/rounds_invalid`). UI `block_view.dart` offen für 2.8.
- [x] **3.2 Exercise Substitution mid-session** ✅ — `WorkoutRunner.substituteExercise(index, replacement)`, `PerformedExercise.substitutedFrom?` + `PerformedExerciseDetails.substitutedFrom?` für History, refuses bei bereits performed sets. UI-Sheet offen für 2.7/2.8.
- [x] **3.3 Plan Editing API** ✅ — `WorkoutRunner.{addExercise, removeExercise, moveExercise, replaceSet, duplicateSet, reorderSets}` + Remap performed-Indizes bei `moveExercise`, Refuse-Rules dokumentiert.
- [x] **3.4 Exercise Library Metadata** ✅ — `ExerciseEquipment` (12 items) + `MovementPattern` (8) + `ExerciseDifficulty` (3) Enums, `unilateral`, `aliases`, `searchTerms` als first-class Felder auf `WorkoutExercise`, Legacy `meta`-Reader bleibt funktional.
- [x] **3.5 Custom-Catalog Storage** ✅ — `CustomEntityRegistry` Interface + `InMemoryCustomEntityRegistry`, `CustomEntityKinds.{exercises, muscles, categories, plans, cardio_plans}`. `Catalog` Merger (Custom shadows Default by id). `WorkoutRunner.replacePlan(plan, {preservePerformed})` + `WorkoutPlanBuilder.fromPlan(plan)` Seed.

### 3.6 Generic Session Engine
- `WorkoutSession` als übergreifendes Ausführungsmodell für Strength, Cardio,
  AMRAP, Timed Sets, Supersets und Circuits
- `SessionStep`, `SessionStepType`, `SessionProgress`, `SessionResult`
- Bestehende `WorkoutRunner` / `CardioRunner` bleiben Facades über der Engine
- Ziel: weniger Sonderfälle in UI und Persistenz
- Migrationspfad: erst intern nutzen, später optional public machen

---

## Phase 4 — Smart Helpers

Pure-function intelligence layer — keine UI-Pflicht, alle additiv.

- [x] **4.1 Progressive Overload Engine** ✅ — `OverloadEngine.from(history, currentTarget, strategy)` mit `linear` / `doubleProgression` / `rpe`, `OverloadSuggestion` immutable + JSON, Warmup-Sets in History gefiltert. (`lib/src/intelligence/overload.dart`, 14 Tests)
- [x] **4.2 Stats Helpers** ✅ — `WorkoutStats.{totalVolume, totalSets, totalReps, totalDuration, totalKcal, streakDays, weeklySummary, volumePerExercise}`, `WeeklyWorkoutSummary` mit JSON. (`lib/src/stats/workout_stats.dart`, 13 Tests)
- [x] **4.3 Personal Record Detection** ✅ — `PersonalRecord` + `PersonalRecords.{forExercise, forAllExercises, forCardio, newRecordsIn}` mit Epley est-1RM, bodyweight-skip für Volume-PRs, Cardio: longestDistance / fastestPace / longestWorkTime. (`lib/src/stats/personal_records.dart`, 10 Tests)
- [x] **4.4 Recommendation Helpers** ✅ — `Recommendations.{fromLastSet, fromRpe, fromFatigue}` mit `NextSetSuggestion` / `RestSuggestion` / `DeloadSuggestion`. (`lib/src/intelligence/recommendations.dart`, 15 Tests)
- [x] **4.5 Filtering & Search Helpers** ✅ — `ExerciseSearch.{query, filter, suggest}` mit token-AND, alias-Lookup via `meta`, Score-Ranking (exact > prefix > contains), forward-compat für equipment/movementPattern aus Phase 3.4. (`lib/src/search/exercise_search.dart`, 15 Tests)

- [x] **4.6 Plan Generator** ✅ — `PlanGenerator.{fullBody, pushPullLegs, upperLower, fromEquipment}` + `PlanGenerationProfile { goal, level, daysPerWeek, equipment }`. Rep/set scheme by goal (strength 5×5, hypertrophy 4×8–12, conditioning 3×15). Equipment-Filter via `meta['equipment']`. (`lib/src/intelligence/plan_generator.dart`, 21 Tests)
- [x] **4.7 Fatigue & Readiness Signals** ✅ — `Readiness.fromHistory(recent, {window, selfReportedRpe, sleepHours})` + `Readiness.adjust(readiness)`, asymmetrische Volumen-Trend-Heuristik, RPE/Sleep-Anpassung, `ReadinessLevel { fresh, ready, cautious, fatigued }`, dartdoc warnt vor medizinischen Claims. (`lib/src/intelligence/readiness.dart`, 16 Tests)

---

## Phase 5 — Content

### 5.1 Workout Templates ✅ done
- [x] `StrengthTemplates.{fullBodyBeginner, pushDay, pullDay, legDay, upperA, lowerA, fiveByFive}` + `.all` (`lib/src/data/strength_templates.dart`)
- [x] Stable ids `tmpl_*`, warmup-Sets vor Main-Lifts, alle `validate().isValid`
- [x] Tests: 6 (`test/data/strength_templates_test.dart`)

### 5.2 Cardio Presets ✅ done
- [x] `CardioTemplates.{tabataClassic, hiit_30_30, lissRun, pyramid, easyBike, runWalk}` + `.all` (`lib/src/data/cardio_templates.dart`)
- [x] Stable ids `cardio_tmpl_*`, MET-Werte pro Interval, `CardioPlanBuilder`-basiert
- [x] Tests: 6 (`test/data/cardio_templates_test.dart`)

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

### 5.5.2 Workout Notes ✅ done (side-car via meta)
- [x] `WorkoutNotes.{readSessionNote, writeSessionNote, readExerciseNote, writeExerciseNote, setNoteKey, readResultSessionNote}` — speichert in `meta['sessionNote']` / `meta['note']`, keine Model-Änderung
- [x] `NotesTimeline.buildFor(result, {setNotes})` für UI-Timeline
- [x] Tests: 10 (`test/notes/workout_notes_test.dart`)

### 5.5.3 Session Rating ✅ done
- [x] `SessionRating { sessionKey, mood, difficulty, energy, sleepQuality, overallRating, notes, ratedAt }` + `SessionMood` enum + JSON
- [x] `SessionRating.keyFor(result) / keyForCardio(result)` stable composite key
- [x] `SessionRatingStorage` Interface + `InMemorySessionRatingStorage` (recent / since / limit / remove / clear)
- [x] `SessionRatingStats.{averageOverall, moodHistogram, averageDifficulty}`
- [x] Tests: 18 (`test/feedback/session_rating_test.dart` + `test/storage/in_memory_session_rating_storage_test.dart`)

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

### 5.5.6 Workout Tags ✅ done
- [x] `WorkoutTags.{read, write, add, remove, has}` side-car helper via `meta['tags']` — keine Model-Änderung nötig
- [x] `KnownTag` Konstanten (strength, hypertrophy, rehab, home, gym, deload, cardio, hiit, liss, morning, evening)
- [x] `TagFilter.{apply, filterPlans, filterResults, filterCardioPlans, filterCardioResults}` mit `TagMatchMode { any, all, none }`
- [x] Tests: 28 (`test/tags/workout_tags_test.dart` + `test/tags/tag_filter_test.dart`)

### 5.5.7 Draft / Scheduled Workouts ✅ done
- [x] `ScheduledWorkout { id, planId, planName, isCardio, scheduledAt, startedAt, completedAt, skippedAt, status, notes, meta }` + `ScheduledStatus { upcoming, completed, skipped, cancelled }` + `derivedStatus` getter
- [x] `ScheduledWorkoutQuery.{upcoming, today}` Helpers, `ScheduledWorkoutStorage` + `InMemoryScheduledWorkoutStorage`
- [x] Tests: 26 (`test/scheduling/` + `test/storage/in_memory_scheduled_workout_storage_test.dart`)

### 5.5.8 Workout Import ✅ done
- [x] `WorkoutImport.fromBundle(json, policy)` + `WorkoutImport.fromJsonString(...)`
- [x] `ImportConflictPolicy { replace, duplicate, skip }`, `ImportResult` mit `imported*`/`skipped*`/`duplicated*`/`errors`
- [x] Pure helper, kein Backend; per-Plan Parse-Failures werden zu `ImportError` ohne den Rest zu kippen
- [x] Tests: 10 (`test/import/workout_import_test.dart`)

### 5.5.9 Share Helpers ✅ done
- [x] `ShareHelpers.{toShareText, toShareTextCardio, toMarkdown, toMarkdownCardio}` als pure Funktionen (`lib/src/export/share_helpers.dart`)
- [x] Keine `package:flutter/*` Imports, kein Emoji, mm:ss / hh:mm:ss Auto-Switch
- [x] Tests: 9 (`test/export/share_helpers_test.dart`)

### 5.5.10 Exercise Favorites & Recents ✅ done
- [x] `ExerciseFavoritesStorage` Interface + `InMemoryExerciseFavoritesStorage`
- [x] `addFavorite/removeFavorite/isFavorite/favorites/recordUsage/recents/mostUsed/usageCounts/clear`
- [x] `ExercisePicker.prioritised(catalog, storage)` mit konfigurierbaren Weights, score = fav + recent + capped usage
- [x] Tests: 16 (`test/storage/in_memory_exercise_favorites_storage_test.dart` + `test/intelligence/exercise_picker_test.dart`)

### 5.5.11 Warmup Generator ✅ done (opus-1m)
- [x] `WarmupGenerator.forSet({workingWeight, workingReps, strategy,
      barWeight?, roundTo?, rest})` — pure, deterministic.
- [x] Three pre-baked `WarmupStrategy`s: `linear` (4 ramps), `powerlifting`
      (5 → 3 → 2 → 1 reps), `hypertrophy` (12 → 10 → 8 reps).
- [x] Each emitted `WorkoutSet` is tagged `SetType.warmup` and gets the
      caller-supplied `rest`.
- [x] Optional `roundTo` snaps each warm-up weight **up** to the nearest
      plate increment (`2.5` kg, `5` lb, `1.25` kg, …).
- [x] Optional `barWeight` drops warm-up sets below an empty bar — keeps
      output realistic for barbell lifts. Bar-only / below-bar working
      weights return an empty list (no warm-up needed).
- [x] Rounding-induced duplicate weights are collapsed to a single set
      ("plateau dedupe") — small working weights don't yield three
      identical warm-ups after snapping.
- [x] Defensive on bad input: `null` / zero / negative weight or reps
      return an empty list instead of throwing.
- [x] 16 unit tests covering each strategy, rounding paths, bar clamp,
      plateau dedupe, and input hygiene.
- [x] Public export via `lib/fitness_workout.dart`.

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

### 5.5.13 Rest Presets ✅ done
- [x] `RestGoal { strength, hypertrophy, endurance, mobility, hiit }` + `RestPreset` + `kDefaultRestPresets` (180/90/45/30/20 s)
- [x] `RestPresetResolver.resolve({setDefault, exerciseDefault, planDefault, planGoal})` — Priorität set > exercise > plan > goal-preset > 90s Fallback
- [x] Tests: 11 (`test/intelligence/rest_preset_test.dart`)
- [x] Public export via `lib/fitness_workout.dart`
- UI Quick-chips im SetInputSheet bleiben offen (2.7 / 2.8 territory)

### 5.5.14 Workout Completion Rules ✅ done (+ 5.5.4 partial/abandoned status)
- [x] `WorkoutCompletionStatus { completed, partial, cancelled, abandoned }`
- [x] `CompletionRule` Hierarchie: `AllSetsCompletionRule`, `MinimumSetsCompletionRule`, `FreeSessionCompletionRule`, `RequiredExercisesCompletionRule`
- [x] `WorkoutCompletion.evaluate(result, plan, rule)` → `CompletionEvaluation { status, ratio, missingExerciseIds }` mit JSON
- [x] Status-Mapping: `cancelled` (0 sets), `abandoned` (ratio<0.5 + missing), `partial` (Regel verletzt), `completed` (Regel erfüllt + ratio≥1)
- [x] Tests: 10 (`test/completion/completion_rules_test.dart`)

### 5.5.15 Auto-save Draft Plan ✅ done
- [x] `PlanDraftStorage` Interface (`saveDraft`/`readDraft`/`hasDraft`/`discardDraft`/`listSlots`) + `InMemoryPlanDraftStorage`
- [x] `PlanDraftController({storage, slot, debounce})` mit `onPlanChanged`/`resume`/`publish`/`dispose` (debounced auto-save)
- [x] Tests: 10 (`test/storage/in_memory_plan_draft_storage_test.dart` + `test/storage/plan_draft_controller_test.dart`)

### 5.5.16 Personal Equipment Profile ✅ done
- [x] `EquipmentItem` Enum (16 items: barbell, dumbbell, kettlebell, machine, cable, bodyweight, bands, plates, bench, rack, pullupBar, treadmill, rower, stationaryBike, jumpRope, medball)
- [x] `EquipmentProfile { items, name, isEmpty, has(), idSet, copyWith, toJson/fromJson }` + named ctors `.bodyweightOnly() / .homeGymBasic() / .commercialGym() / .cardioStudio()`
- [x] `idSet` plug-in für `PlanGenerationProfile.equipment`
- [x] Tests: 8 (`test/intelligence/equipment_profile_test.dart`)

### 5.5.17 Target Pace / Target Zone Alerts
- CardioInterval kann Ziel-Pace oder HR-Zone beschreiben
- Runner liefert Hook: `onTargetZoneChanged(inZone/outOfZone)`
- Keine Sensor-Integration im Core; App liefert Messwerte
- UI zeigt Zone-Status optional im CardioPanel

### 5.5.18 Exercise Alternatives ✅ done
- [x] `ExerciseAlternatives.forExercise(source, catalog, {limit, availableEquipment})` + `ExerciseAlternativeGroup`
- [x] `AlternativeMatch { sameMovementSameEquipment 1.0, sameMovementDifferentEquipment 0.8, sameMuscleGroup 0.6, sameCategoryFallback 0.3 }`, equipment-Filter optional
- [x] Tests: 8 (`test/search/exercise_alternatives_test.dart`)

### 5.5.19 Deload / Recovery Week Templates ✅ done
- [x] `DeloadPlan.from(plan, strategy, {config, idSuffix})` + `DeloadStrategy { volume, intensity, balanced, mobility }` + `DeloadConfig { setMultiplier, weightMultiplier, repMultiplier }`
- [x] Warmup-Sets bleiben unverändert, Working-Sets bekommen reduzierte Sets/Reps/Weight (auf 0.5 kg gerundet)
- [x] Tests: 8 (`test/intelligence/deload_test.dart`)

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

### 6.3 Backend Sync Contracts ✅ done
- [x] Generic `SyncEnvelope<T> { id, operation, updatedAt, deletedAt?, source, schemaVersion, payload? }` mit JSON-Round-Trip
- [x] `SyncMerge.resolve` / `resolveBatch` mit Strategien `lastWriteWins`, `sourcePriority`, `manual`
- [x] `SyncConflict<T>` + `SyncMergeResult<T>` für manuelle Konflikt-Behandlung
- [x] Tie-break: gleicher `updatedAt` → delete schlägt update/create
- [x] Tests: 9 (`test/sync/sync_envelope_test.dart` + `test/sync/sync_merge_test.dart`)

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

### 8.1 Large History Performance ✅ done (contracts + lazy stats)
- [x] `PagedWorkoutHistoryStorage` Interface mit `pagedWorkouts/pagedCardio/workoutCountSince/cardioCountSince` + opaque base64-cursor
- [x] `HistoryPage<T> { items, totalCount, nextCursor, hasMore }`
- [x] `InMemoryPagedHistoryStorage` implementiert beide Interfaces additiv
- [x] `StreamingStats.{totalVolume, totalSets, walk}` page-walking helpers für O(1)-memory stats
- [x] Tests: 11 (`test/storage/in_memory_paged_history_storage_test.dart` + `test/stats/streaming_stats_test.dart`)
- Benchmarks für 1k/10k/100k Results offen (separate Quality-Gate)

### 8.2 Catalog Indexing ✅ done
- [x] `ExerciseIndex` mit O(1) Lookups: `byId/byMuscle/byMuscleGroup/byCategory/byEquipment/byPrefix`
- [x] Eager O(N·M) Build, alle Lookups returnen `List.unmodifiable(...)`
- [x] `CatalogSnapshot.from(source)` mit `builtAt` Zeitstempel
- [x] Defensive `meta['equipment']` Reader (String + Iterable<String>)
- [x] Tests: 18 (`test/search/exercise_index_test.dart`)

### 8.3 Timer Reliability
- Drift-Tests für Global-, Set-, Rest- und Interval-Timer
- Recovery nach App-Suspend / Resume dokumentieren
- Persistenz-Frequenz begrenzen, aber Hard-Kill-Datenverlust klein halten
- Einheitliche Clock-Abstraktion für Tests (`RunnerClock`)

### 8.4 Error Handling Model ✅ done (types only)
- [x] `RunnerActionResult { success, error?, message? }` immutable + `ok()` / `fail(error, message?)` Factories + JSON-Round-Trip + value equality
- [x] `RunnerActionError` Enum: `noActivePlan, indexOutOfRange, alreadyRunning, invalidPlan, performedSetLocked, idCollision, notRunning, storageFailed, unknown`
- [x] `RunnerErrorMessages.defaultMessage(error)` mit englischen Defaults
- [x] Tests: 13 (`test/error/runner_action_result_test.dart`)
- Migration der Runner-Methoden auf `RunnerActionResult` offen — Bool-Return-Type bleibt vorerst (backward-compat).

---

## Phase 9 — Privacy, Safety & Compliance

Fitnessdaten sind sensibel. Das Core-Paket soll keine Policy erzwingen, aber
saubere Datenschutz- und Safety-Hooks ermöglichen.

### 9.1 Data Ownership Helpers ✅ done
- [x] `DataBundle { schemaVersion, exportedAt, workoutResults, cardioResults, workoutPlans, cardioPlans }` + `DataExport.{bundle, toJsonString}` (indent 2)
- [x] `Redaction.{anonymized, anonymizedCardio, redactedJson}` mit konfigurierbarem Drop-Set (Default: `planId`, `planName`, `exerciseName`, `notes`, `meta`)
- [x] Keine Netzwerk-Funktionen, pure dart:core
- [x] Tests: 12 (`test/privacy/data_export_test.dart` + `test/privacy/redaction_test.dart`)

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
