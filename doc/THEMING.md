# Theming

The bundled widgets read `WorkoutRunnerThemeData` from the nearest
`WorkoutRunnerTheme` ancestor. The package theme is **independent** from
`MaterialApp.theme` — they coexist. You can keep using your app's Material
theme for everything else and only override package tokens here.

See [WIDGETS.md](WIDGETS.md) for what the tokens actually drive and
[API.md](API.md#theme) for the type signatures.

---

## Quick start

```dart
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  final WorkoutRunner runner;
  const App({super.key, required this.runner});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: RunnerScope(runner: runner, child: const Home()),
      ),
    );
  }
}
```

If you skip the `WorkoutRunnerTheme` widget entirely, every call to
`WorkoutRunnerTheme.of(context)` falls back to
`WorkoutRunnerThemeData.dark()`.

---

## Tokens

`WorkoutRunnerThemeData` is a flat record of design tokens. Defaults below.

### Colors

| Token             | `.dark()`                    | `.light()`                    |
| ----------------- | ---------------------------- | ----------------------------- |
| `background`      | `#0B0C0F`                    | `#F5F6F8`                     |
| `surface`         | `#15171C`                    | `#FFFFFF`                     |
| `surfaceElevated` | `#1C1F25`                    | `#F9FAFB`                     |
| `border`          | `#142DE8B0` (lime @ 8%)      | `#14000000` (black @ 8%)      |
| `accent`          | `#C8F44A` (lime)             | `#6E8F00`                     |
| `accentMuted`     | accent @ 20%                 | accent @ 20%                  |
| `hot`             | `#FF6A1A` (orange)           | `#E85B12`                     |
| `hotMuted`        | hot @ 20%                    | hot @ 20%                     |
| `success`         | `#7CE2A8`                    | `#1E9D5B`                     |
| `danger`          | `#FF5A5F`                    | `#E5484D`                     |
| `textPrimary`     | `#F3F5F7`                    | `#15171C`                     |
| `textMuted`       | `#9BA3AE`                    | `#5C636E`                     |
| `textDim`         | `#5C636E`                    | `#9BA3AE`                     |
| `onAccent`        | `#0B0C0F`                    | `#FFFFFF`                     |

`accent` is used on the "running workout" surfaces; `hot` is used for the
in-progress set ticker and the rest strip. `success` and `danger` are
reserved for confirm / destructive affordances (e.g. the "Leave workout"
dialog button).

### Typography

| Token         | Default                                                                 |
| ------------- | ----------------------------------------------------------------------- |
| `heroNumber`  | 64px, w800, tabular figures, height 1.0, letter-spacing -1.5            |
| `titleLarge`  | 22px, w800, height 1.1, letter-spacing -0.4                             |
| `title`       | 16px, w700, height 1.2                                                  |
| `body`        | 14px, w500, height 1.35                                                 |
| `bodyMuted`   | 14px, w500, `textMuted`, height 1.35                                    |
| `caption`     | 12px, w600, `textMuted`, height 1.3                                     |
| `eyebrow`     | 11px, w700, `textMuted`, letter-spacing 1.2 (uppercase usage)           |

Both presets share the same text shape; `.light()` only swaps the colours.

### Shape

| Token          | Value                  |
| -------------- | ---------------------- |
| `radiusSmall`  | 10 px                  |
| `radiusMedium` | 16 px                  |
| `radiusLarge`  | 22 px                  |
| `radiusHero`   | 28 px                  |
| `radiusPill`  | 999 px (pill)          |

### Spacing scale

A simple 4-step grid (4 / 8 / 12 / 16 / 20 / 24 / 32). Fields are
`double` — use them anywhere you would normally write a hard-coded gap:

| Token    | Px |
| -------- | -- |
| `space1` | 4  |
| `space2` | 8  |
| `space3` | 12 |
| `space4` | 16 |
| `space5` | 20 |
| `space6` | 24 |
| `space7` | 32 |

### Effects

| Token         | Default (`.dark()`)                                            |
| ------------- | -------------------------------------------------------------- |
| `shadowCard`  | `[BoxShadow(color: #33000000, blur: 24, offset: (0, 8))]`      |
| `shadowGlow`  | `[BoxShadow(color: #55C8F44A, blur: 28, spreadRadius: -4)]`    |

`.light()` softens both: `shadowCard` becomes `#14000000` / 18 / (0, 6) and
`shadowGlow` switches to the light-mode accent.

### Motion

| Token           | Default |
| --------------- | ------- |
| `motionFast`    | 180 ms  |
| `motionMedium`  | 320 ms  |

`motionFast` powers chip / pill / set-row transitions; `motionMedium`
powers carousel page-changes.

### Set-type accents

`setTypeAccents` is a `Map<SetType, Color>` used by `SetView` (and any
consumer that wants to badge / tint a set row by type). Defaults:

| Type            | Dark accent     | Light accent    |
| --------------- | --------------- | --------------- |
| `working`       | `accent` (lime) | `accent`        |
| `warmup`        | cool blue       | deep blue       |
| `drop`          | `hot` (orange)  | `hot`           |
| `failure`       | `danger` (red)  | `danger`        |
| `amrap`         | `success` (mint)| `success`       |
| `timed`         | violet          | violet          |

Use `theme.accentFor(set.type)` for a guaranteed-non-null lookup that falls
back to the regular `accent` colour when a type is missing from the map.

### Timer & rest tokens

| Token                    | Drives                                              |
| ------------------------ | --------------------------------------------------- |
| `timerDefault`           | Default countdown text style (AMRAP / timed sets)   |
| `timerWarning`           | Tinted hot when the countdown is in the last seconds|
| `timerSuccess`           | Tinted success when target duration has been reached|
| `restProgressColor`      | Foreground of the rest progress ring                |
| `restProgressTrackColor` | Track behind the rest progress ring                 |
| `restBackdrop`           | Scrim color behind a full-screen rest overlay       |

### Building from a Material ColorScheme

If your app already drives all colours from `Theme.of(context).colorScheme`,
use the opinionated `fromColorScheme` factory and override only the deltas
you care about:

```dart
final theme = WorkoutRunnerThemeData.fromColorScheme(
  Theme.of(context).colorScheme,
);
```

`fromColorScheme` chooses the dark- or light-preset baseline based on
`scheme.brightness`, then overrides colour tokens to match the scheme.
Typography, spacing, radii and motion stay on the package defaults.

---

## Overriding tokens

Both presets expose `copyWith(...)` so you only need to specify the deltas:

```dart
final brand = WorkoutRunnerThemeData.dark().copyWith(
  accent: const Color(0xFFFF7E2A),         // orange brand
  hot: const Color(0xFFE91E63),            // pink hot
  shadowGlow: const [
    BoxShadow(color: Color(0x55FF7E2A), blurRadius: 28, spreadRadius: -4),
  ],
);

return WorkoutRunnerTheme(
  data: brand,
  child: const RunnerScreen(plan: ..., runner: ...),
);
```

For a light-themed brand:

```dart
final brandLight = WorkoutRunnerThemeData.light().copyWith(
  accent: const Color(0xFF6E2ACF),
  accentMuted: const Color(0x336E2ACF),
  textPrimary: const Color(0xFF14102B),
);
```

---

## Following the system theme

`WorkoutRunnerTheme` is just an `InheritedTheme`; pick the data yourself
from `MediaQuery.platformBrightnessOf` or your app's preference:

```dart
@override
Widget build(BuildContext context) {
  final brightness = MediaQuery.platformBrightnessOf(context);
  final data = brightness == Brightness.dark
      ? WorkoutRunnerThemeData.dark()
      : WorkoutRunnerThemeData.light();

  return WorkoutRunnerTheme(data: data, child: const RunnerPanel());
}
```

---

## Reading tokens in your own widgets

```dart
final t = WorkoutRunnerTheme.of(context);

return Container(
  padding: EdgeInsets.symmetric(horizontal: t.space4, vertical: t.space3),
  decoration: BoxDecoration(
    color: t.surface,
    borderRadius: t.radiusMedium,
    border: Border.all(color: t.border),
  ),
  child: Text('Custom content', style: t.body),
);
```

Use the [internal helpers](WIDGETS.md#internal-helpers-exported) —
`RunnerCard`, `RunnerPillButton`, `TimerText`, `SectionLabel` — when you
want widgets that already consume the tokens for you.
