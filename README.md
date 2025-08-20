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
- 🧩 **Fertige Widgets**: `RunnerPanel`, `CurrentWorkout`, `CurrentExercise`, `CurrentSet/SetView`, `Results`, `RunnerScreen`
- 🎨 **Theming/Styling** per Parametern (Farben, TextStyles) überschreibbar

---

## Getting started

1. In der `pubspec.yaml` eintragen:
```yaml
dependencies:
  fitness_workout: ^0.0.1
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