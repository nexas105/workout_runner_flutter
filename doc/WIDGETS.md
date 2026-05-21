# Widgets

Every widget below is exported from `package:fitness_workout/fitness_workout.dart`
and reads its `WorkoutRunner` from the nearest [`RunnerScope`](#workoutrunnerscope).
Wrap any tree that needs them once, near the top of your app.

See [API.md](API.md) for the controller surface and [THEMING.md](THEMING.md)
for design-token overrides.

---

## `RunnerScope`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

final runner = WorkoutRunner();

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return RunnerScope(
      runner: runner,
      child: const MaterialApp(home: Home()),
    );
  }
}
```

`RunnerScope` is an `InheritedNotifier<WorkoutRunner>`. Descendants
read it with `RunnerScope.of(context)` (asserts presence) or
`RunnerScope.maybeOf(context)` (returns `null` when missing). Every
`notifyListeners()` triggers a rebuild of widgets that depend on it.

Behaviour when no workout is active: descendants see `runner.plan == null`,
`runner.isRunning == false`. Most bundled widgets render an empty
`SizedBox.shrink()` in that case.

---

## `RunnerPanel`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class WorkoutBody extends StatelessWidget {
  const WorkoutBody({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: RunnerPanel(
        followActiveExercise: true,
      ),
    );
  }
}
```

Headline widget: plan header card, exercise carousel (`PageView`), rest
strip, finish button. Constructor:

```dart
const RunnerPanel({
  Key? key,
  ValueChanged<bool>? onFinished,       // fired with `result != null` after finish()
  bool followActiveExercise = true,     // auto-scroll carousel to active exercise
  Widget? header,                       // optional widget above the summary card
});
```

When `runner.plan == null` it renders a centered empty state ("No active
workout"). When the workout is running, every plan exercise is a page in
the carousel containing a list of `SetRow`s and a *Start this exercise*
CTA. The bottom finish bar calls `runner.finish()` and forwards the result
flag to `onFinished`.

Use `RunnerPanel` inside your own `Scaffold` when you want to control the
`AppBar`. Use [`RunnerScreen`](#runnerscreen) when you want a ready-made
screen.

---

## `RunnerScreen`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

void openWorkout(BuildContext context, WorkoutRunner runner, WorkoutPlan plan) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RunnerScreen(plan: plan, runner: runner),
    ),
  );
}
```

A `Scaffold` wrapping `RunnerPanel`, with a built-in close-confirm dialog
and an automatic transition to `ResultsView` after `finish()`.

Constructor:

```dart
const RunnerScreen({
  Key? key,
  required WorkoutPlan plan,
  required WorkoutRunner runner,
  bool autoStart = true,                                       // calls runner.start in initState
  void Function(BuildContext context, WorkoutResult result)? onFinished,
});
```

`RunnerScreen` provides its **own** `RunnerScope`, so you do not
need to wrap it. Pass `autoStart: false` if you want to call
`runner.start(...)` yourself. Override `onFinished` to redirect to a
custom destination instead of `ResultsView`.

---

## `QuickRunner`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final WorkoutRunner runner;
  final List<WorkoutPlan> plans;
  const Home({super.key, required this.runner, required this.plans});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          QuickRunner(
            plans: plans,
            onOpen: (plan) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RunnerScreen(plan: plan, runner: runner),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

A single card that flips between two modes:

- **No active workout:** horizontal list of `plans`. Tapping a plan calls
  `runner.start(plan)` and then `onOpen(plan)`.
- **Active workout:** "Workout running" card with elapsed time + sets
  done. Tapping it calls `onOpen(activePlan)`.

Constructor:

```dart
const QuickRunner({
  Key? key,
  required List<WorkoutPlan> plans,
  void Function(WorkoutPlan plan)? onOpen,
});
```

Empty `plans` and no active workout renders `SizedBox.shrink()`.

---

## `ResultsView`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class ResultsRoute extends StatelessWidget {
  final WorkoutResult result;
  const ResultsRoute({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResultsView(
        result: result,
        onClose: () => Navigator.of(context).pop(),
        closeLabel: 'Done',
      ),
    );
  }
}
```

Hero card + stats row (exercises, sets, reps, optional volume) + per-exercise
breakdown. Pass a `result` you obtained from `runner.finish()` or from a
`finished` stream subscription.

Constructor:

```dart
const ResultsView({
  Key? key,
  required WorkoutResult result,
  VoidCallback? onClose,
  String closeLabel = 'Close',
});
```

Does **not** depend on `RunnerScope` — you can show it after the
runner has been torn down.

---

## Status indicators

All four render `SizedBox.shrink()` when no workout is running, so they are
safe to drop unconditionally.

### `RunnerStatusChip`

```dart
AppBar(
  title: const Text('Home'),
  actions: const [
    RunnerStatusChip(),
    SizedBox(width: 8),
  ],
)
```

A compact `mm:ss` pill. Constructor: `RunnerStatusChip({Key? key, VoidCallback? onTap})`.

### `RunnerStatusAppBarAction`

```dart
AppBar(
  actions: [
    RunnerStatusAppBarAction(onTap: () => /* navigate to RunnerScreen */),
  ],
)
```

Tiny convenience wrapper that centres a `RunnerStatusChip` with horizontal
padding so it sits cleanly next to other `AppBar` actions. Same `onTap`
parameter.

### `RunnerStatusBanner`

```dart
Column(
  children: [
    RunnerStatusBanner(onTap: () => /* open runner */),
    // ...rest of the page
  ],
)
```

Inline accent banner you can place under an `AppBar` or hero block.

```dart
const RunnerStatusBanner({
  Key? key,
  VoidCallback? onTap,
  EdgeInsetsGeometry? padding,
});
```

### `RunnerStatusBottomBar`

```dart
Scaffold(
  body: const _MyHome(),
  bottomNavigationBar: RunnerStatusBottomBar(
    label: 'Continue',
    onTap: () => Navigator.of(context).push(/* RunnerScreen */),
  ),
)
```

`SafeArea`-aware bottom CTA suitable for `bottomNavigationBar`. Shows plan
name + elapsed time + a "Continue workout" pill button.

```dart
const RunnerStatusBottomBar({
  Key? key,
  VoidCallback? onTap,
  String label = 'Continue workout',
});
```

---

## `SetRow`

```dart
import 'package:fitness_workout/fitness_workout.dart';

ListView.separated(
  itemCount: exercise.sets.length,
  separatorBuilder: (_, __) => const SizedBox(height: 8),
  itemBuilder: (context, i) => SetRow(
    exerciseIndex: 0,
    setIndex: i,
    target: exercise.sets[i],
    performed: runner.getPerformedSet(0, i),
  ),
)
```

State machine for a single set row, used by `RunnerPanel` and reusable in
your own layouts.

```dart
const SetRow({
  Key? key,
  required int exerciseIndex,
  required int setIndex,
  required WorkoutSet target,
  PerformedSet? performed,
});
```

States (driven by `WorkoutRunner`):

- **pending** — the exercise is active and no set is running. Tap calls
  `runner.startSet(...)`.
- **running** — this set's ticker is active. Tap opens an internal
  bottom-sheet input (reps / weight / RIR / rest). Submitting calls
  `runner.finishCurrentSet(...)`.
- **done** — `performed != null`. Renders the achieved values; tap is a
  no-op.
- **locked** — another exercise is active, or another set on this exercise
  is running. Tap is a no-op.

The bottom-sheet is internal (private to `set_view.dart`) but is the
**only** way `SetRow` finishes a set. If you need a different input flow,
build your own row and call `runner.finishCurrentSet(...)` yourself.

---

## Internal helpers (exported)

These are the building blocks the package uses internally — exposed so
you can compose UI in the same style without re-implementing them.

### `RunnerCard`

```dart
RunnerCard(
  padding: const EdgeInsets.all(16),
  borderRadius: const BorderRadius.all(Radius.circular(22)),
  borderColor: Colors.transparent,
  elevated: true,
  onTap: () {},
  child: const Text('Custom card'),
);
```

The base surface: rounded rectangle with theme colour, border and shadow.
All knobs are optional; defaults come from `WorkoutRunnerTheme.of(context)`.
`elevated: true` swaps the fill from `surface` to `surfaceElevated`.

### `RunnerPillButton` / `RunnerButtonStyle`

```dart
RunnerPillButton(
  label: 'Start',
  icon: Icons.play_arrow_rounded,
  style: RunnerButtonStyle.accent,  // filled, accent, hot, danger, outline, ghost
  expand: true,
  onPressed: () {},
);
```

The pill-shaped buttons used throughout the package. `style` picks the
colour role from the theme. Passing `onPressed: null` renders the disabled
state.

### `TimerText`

```dart
TimerText(duration: runner.elapsed)
TimerText.format(const Duration(minutes: 3, seconds: 4)) // '03:04'
```

Renders a `Duration` as `mm:ss` (or `hh:mm:ss` past one hour) with tabular
numerals. The static `format` helper is handy in plain `Text` widgets.

```dart
const TimerText({
  Key? key,
  required Duration duration,
  TextStyle? style,
  Color? color,
  bool compact = false,
});
```

### `SectionLabel`

```dart
SectionLabel('performed exercises', color: const Color(0xFF9BA3AE))
```

Uppercase "eyebrow" caption used on cards. Optional `trailing` slot
displays a widget aligned to the right of the label.

```dart
const SectionLabel(String text, {Key? key, Color? color, Widget? trailing});
```

---

## Cardio widgets

Cardio mirrors the strength widget set one-for-one. Every widget below
reads its `CardioRunner` from the nearest [`CardioRunnerScope`](#cardiorunnerscope).
Status widgets render `SizedBox.shrink()` while no session is active,
so they are safe to drop unconditionally. See
[API.md → `CardioRunner`](API.md#cardiorunner) for the controller surface.

### `CardioRunnerScope`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

final cardio = CardioRunner();

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return CardioRunnerScope(
      runner: cardio,
      child: const MaterialApp(home: Home()),
    );
  }
}
```

`InheritedNotifier<CardioRunner>`. Read it with
`CardioRunnerScope.of(context)` (asserts presence) or
`CardioRunnerScope.maybeOf(context)` (returns `null`). Wrap it together
with a `RunnerScope` near the top of your app to support both
runners at once.

### `CardioRunnerPanel`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class CardioBody extends StatelessWidget {
  const CardioBody({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: CardioRunnerPanel());
  }
}
```

Headline cardio widget: hero timer + active-interval card + lap timeline
+ control bar (pause/resume, skip, complete interval, finish).
Constructor:

```dart
const CardioRunnerPanel({
  Key? key,
  ValueChanged<bool>? onFinished,  // fired with `result != null` after finish()
  Widget? header,                  // optional widget above the hero block
});
```

When `runner.plan == null` it renders a centered empty state. *Complete
interval* opens an internal lap-input bottom sheet (distance / heart-rate
/ RPE) and forwards the values to `runner.completeInterval(...)`. The
sheet is private — if you need a different flow, build your own row and
call `runner.completeInterval(...)` directly.

### `CardioRunnerScreen`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

void openCardio(BuildContext context, CardioRunner runner, CardioPlan plan) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CardioRunnerScreen(plan: plan, runner: runner),
    ),
  );
}
```

A `Scaffold` wrapping `CardioRunnerPanel`, with a built-in close-confirm
dialog and an automatic transition to `CardioResultsView` after
`finish()`. Provides its **own** `CardioRunnerScope`, so you do not need
to wrap it.

```dart
const CardioRunnerScreen({
  Key? key,
  required CardioPlan plan,
  required CardioRunner runner,
  bool autoStart = true,
  void Function(BuildContext context, CardioResult result)? onFinished,
});
```

Pass `autoStart: false` if you want to call `runner.start(...)` yourself.
Override `onFinished` to skip the bundled results view.

### `CardioQuickRunner`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final CardioRunner runner;
  const Home({super.key, required this.runner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          CardioQuickRunner(
            plans: DefaultCardioPlans.all,
            onOpen: (plan) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CardioRunnerScreen(plan: plan, runner: runner),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

A single card that flips between two modes:

- **No active session:** horizontal list of `plans`, each with a
  discipline icon, an interval count and the planned total duration.
  Tapping calls `runner.start(plan)` then `onOpen(plan)`.
- **Active session:** "Cardio running" card with elapsed time +
  `currentIntervalIndex / intervals.length`. Tapping calls
  `onOpen(activePlan)`.

```dart
const CardioQuickRunner({
  Key? key,
  required List<CardioPlan> plans,
  void Function(CardioPlan plan)? onOpen,
});
```

Empty `plans` and no active session renders `SizedBox.shrink()`.

### `CardioResultsView`

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class CardioResultsRoute extends StatelessWidget {
  final CardioResult result;
  const CardioResultsRoute({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CardioResultsView(
        result: result,
        onClose: () => Navigator.of(context).pop(),
        closeLabel: 'Done',
      ),
    );
  }
}
```

Hero card + stats row (laps, work time, optional distance + average
pace) + per-lap breakdown. Does **not** depend on `CardioRunnerScope`.

```dart
const CardioResultsView({
  Key? key,
  required CardioResult result,
  VoidCallback? onClose,
  String closeLabel = 'Close',
});
```

### `CardioRunnerStatusChip`

```dart
AppBar(
  title: const Text('Home'),
  actions: const [
    CardioRunnerStatusChip(),
    SizedBox(width: 8),
  ],
)
```

Compact accent pill with a run icon and the elapsed `mm:ss`. Renders
nothing when `runner.plan == null`.

```dart
const CardioRunnerStatusChip({Key? key, VoidCallback? onTap});
```

### `CardioRunnerStatusBanner`

```dart
Column(
  children: [
    CardioRunnerStatusBanner(onTap: () => /* open cardio screen */),
    // ...rest of the page
  ],
)
```

Inline banner showing `plan.name` + elapsed time. Renders nothing while
idle.

```dart
const CardioRunnerStatusBanner({
  Key? key,
  VoidCallback? onTap,
  EdgeInsetsGeometry? padding,
});
```

### `CardioRunnerStatusBottomBar`

```dart
Scaffold(
  body: const _MyHome(),
  bottomNavigationBar: CardioRunnerStatusBottomBar(
    label: 'Continue',
    onTap: () => Navigator.of(context).push(/* CardioRunnerScreen */),
  ),
)
```

`SafeArea`-aware bottom CTA. Shows the run icon, plan name, elapsed
time and a labelled pill button. Renders nothing while idle.

```dart
const CardioRunnerStatusBottomBar({
  Key? key,
  VoidCallback? onTap,
  String label = 'Continue cardio',
});
```
