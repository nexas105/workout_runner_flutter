# fitness_workout / workout_runner_flutter

Ein flexibles Flutter-Package, um **Workouts zu starten, Sätze zu tracken und Ergebnisse auszuwerten**.  
Es liefert eine klare Trennung aus **Controller-Logik** (State, Timer, Persistenz) und **UI-Widgets** (Panels, Cards, Bottom-Banner).

---

## Features

- 📋 **Workout-Pläne** mit Übungen & Ziel-Sätzen (Reps, Gewicht)
- ▶️ **Starten/Fortsetzen** eines Workouts (inkl. Auto-Resume nach App-Neustart)
- ⏱️ **Timer**: Workout-, Set- und Pausen-Timer
- ✅ **Satz-Tracking**: Gewicht, Wiederholungen, RIR, Satzdauer
- 🧠 **Persistenz** via `SharedPreferences` (Storage-Interface austauschbar)
- 🧩 **Fertige Widgets**: `RunnerPanel`, `QuickRunner`, `CurrentExercise`, `CurrentSet/SetView`, `Results`, `RunnerDefaultScreen`
- 🎨 **Theming/Styling** per Parametern (Farben, TextStyles) überschreibbar

---

## Getting started

1. In der `pubspec.yaml` eintragen:
```yaml
dependencies:
  fitness_workout: ^0.0.3
```

2. Optional schon beim App-Start konfigurieren (inkl. Auto-Resume):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runner.configure(autoResume: true); // lädt aktives Workout, falls vorhanden
  runApp(const App());
}
```

---

## Usage (Schnellstart)

```dart
import 'dart:math';

import 'package:example/runner_screen.dart';
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runner.configure();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    // HIER REGISTRIERST DU DEN LISTENER
    // Diese Funktion wird ausgeführt, egal wo `runner.finish()` aufgerufen wird.
    runner.onWorkoutFinished = (result) {
      // Ignoriere, wenn das Widget nicht mehr im Baum ist.
      if (!mounted) return;

      debugPrint('WORKOUT VOM LISTENER IN HOME EMPFANGEN!');
      debugPrint(
        'Plan: ${result.planId}, Dauer: ${result.finishedAt.difference(result.startedAt)}',
      );

      // Zeige eine Bestätigung in deiner App an.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Super! Workout "${result.planId}" abgeschlossen.'),
          backgroundColor: Colors.green,
        ),
      );

      // Hier kannst du die Daten an Supabase senden, in einer lokalen DB speichern etc.
    };
  }

  // List<WorkoutExercise> get _defaultExercises =>
  Muscle _findOrCreateMuscle(String name, {String? group}) {
    // 1. Versuche, den Muskel aus der Plugin-Datenbank zu finden.
    final existingMuscle = Muscle.findByName(name);
    if (existingMuscle != null) {
      return existingMuscle;
    }

    // 2. Wenn nicht gefunden, erstelle ein neues Objekt für die App.
    return Muscle(id: Random().toString(), name: name, group: group);
  }

  List<WorkoutExercise> _buildCustomExercises() {
    return [
      WorkoutExercise(
        id: 'custom_ex_001',
        name: 'Konzentrationscurls',
        desc: 'Eine Isolationsübung für den Bizeps.',
        category: ExerciseCategorie.findByName('Krafttraining'),
        // Hier nutzen wir den Helfer. 'Bizeps' wird gefunden.
        muscles: [_findOrCreateMuscle('Bizeps')],
        sets: [
          WorkoutSet(targetReps: 12, targetWeight: 10),
          WorkoutSet(targetReps: 12, targetWeight: 10),
        ],
      ),
      WorkoutExercise(
        id: 'custom_ex_002',
        name: 'Wadenheben an der Wand',
        desc: 'Stärkt die Wadenmuskulatur ohne Geräte.',
        category: ExerciseCategorie.findByName('Krafttraining'),
        // 'Tibialis Anterior' existiert nicht, also wird ein neues Muscle-Objekt erstellt.
        muscles: [
          _findOrCreateMuscle('Waden'),
          _findOrCreateMuscle('Tibialis Anterior', group: 'Unterkörper'),
        ],
        sets: [WorkoutSet(targetReps: 20), WorkoutSet(targetReps: 20)],
      ),
    ];
  }

  List<WorkoutPlan> _createWorkoutPlans() {
    // 1. Hole dir die Daten aus dem Plugin
    final defaultStrengthExercises = WorkoutExercise.getStrengthExercises();
    final defaultCardioExercises = WorkoutExercise.getCardioExercises();

    // 2. Hole dir die eigenen Übungen der App
    final customExercises = _buildCustomExercises();

    // 3. Kombiniere sie zu Plänen
    return [
      WorkoutPlan(
        id: 'plan_fullbody_001',
        name: 'Ganzkörper & Eigene Übungen',
        // Nimm 2 Kraft-Übungen, 1 Cardio-Übung und alle eigenen Übungen
        exercises: [
          ...defaultStrengthExercises.take(2),
          ...defaultCardioExercises.take(1),
          ...customExercises,
        ],
      ),
      WorkoutPlan(
        id: 'plan_oberkoerper_001',
        name: 'Fokus Oberkörper',
        // Nutze die Plugin-Funktion, um alle OK-Übungen zu filtern
        exercises: WorkoutExercise.getByMuscleGroup("Oberkörper"),
      ),
      WorkoutPlan(
        id: 'plan_custom_only_001',
        name: 'Nur meine Übungen',
        exercises: customExercises,
      ),
    ];
  }

  final List<Muscle> customMuscles = [
    Muscle(id: 'id001', name: 'Bizeps'),
    Muscle(id: 'id003', name: 'Brust'),
  ];

  @override
  Widget build(BuildContext context) {
    final plans = _createWorkoutPlans();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: RunnerStatusChip(controller: runner),
          ),
        ],
      ),
      body: Column(
        children: [
          QuickRunner(controller: runner, plans: plans),
          RunnerStatusBanner(controller: runner),
          Expanded(
            child: ListView.builder(
              itemCount: plans.length,
              itemBuilder: (context, i) {
                final plan = plans[i];
                return ListTile(
                  title: Text(plan.name),
                  subtitle: Text('${plan.exercises.length} Übungen'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RunnerScreen(plan: plan),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: RunnerStatusBottomBar(controller: runner),
    );
  }
}

      ```
      ---

## Die wichtigsten Widgets

- **`RunnerScreen`** – Kompletter Screen mit AppBar, Panel, Finish-Flow
- **`RunnerPanel`** – Panel mit Workout-Header, Übungsauswahl, Sets, Finish-Button
- **`CurrentWorkout`** – Zeigt Plan/Timer/Gesamtstatus
- **`CurrentExercise`** – Pager zur Auswahl/Start der Übung (inkl. „pinned“ State)
- **`CurrentSet` / `SetView`** – Kompakte/ausführliche Ansicht zum aktuellen Satz
- **`Results`** – Abschlussansicht mit Finish-Callback
- **Status-Widgets**: `RunnerStatusAppBar`, `RunnerStatusChip`, `RunnerStatusBanner`, `RunnerStatusBottomBar`

---

## Controller & Persistenz

- **Controller**: `WorkoutRunnerController` (Singleton `runner`) hält State & Timer
- **Persistenz**: Standard `PrefsRunnerStorage` (SharedPreferences)
- **Auto-Resume**: `await runner.configure(autoResume: true)` beim App-Start aufrufen

### Manuell starten

```dart
await runner.start(plan, resumeIfPossible: false);
```

### Satz-APIs (UI-unabhängig)

```dart
runner.setActiveExercise(index);
runner.startSet(exerciseIndex, setIndex);
await runner.finishActiveSet(weight: 80, reps: 8, rir: 2);
runner.skipRest();
final done = runner.getPerformedSet(exerciseIndex, setIndex);
```

### Workout beenden

```dart
final result = await runner.finish();



```

---
## Screenshots

### RunnerScreen
![RunnerScreen](assets/screens/runner_screen.png)

### QuickRunner
![RunnerPanel](assets/screens/quick_runner1.png)
![RunnerPanel](assets/screens/quick_runner2.png)

![RunnerPanel](assets/screens/quick_runner3.png)

### Bottom
![RunnerPanel](assets/screens/bottom.png)

### Bar
![RunnerPanel](assets/screens/bar.png)
---

---

## Contribution

- Issues & Feature-Wünsche: bitte via GitHub-Issues
- PRs sind willkommen. Bitte kleine, thematisch saubere Branches.

---

## Lizenz

MIT License – siehe `LICENSE`.
