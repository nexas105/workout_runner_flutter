import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutRunnerThemeData defaults', () {
    test('dark preset exposes a set-type accent for every SetType', () {
      final theme = WorkoutRunnerThemeData.dark();
      for (final type in SetType.values) {
        expect(theme.setTypeAccents[type], isNotNull,
            reason: 'missing accent for $type');
      }
    });

    test('light preset exposes a set-type accent for every SetType', () {
      final theme = WorkoutRunnerThemeData.light();
      for (final type in SetType.values) {
        expect(theme.setTypeAccents[type], isNotNull,
            reason: 'missing accent for $type');
      }
    });

    test('accentFor returns the regular accent for unknown types', () {
      final theme = WorkoutRunnerThemeData.dark()
          .copyWith(setTypeAccents: const <SetType, Color>{});
      expect(theme.accentFor(SetType.working), theme.accent);
    });

    test('timer styles inherit the body color in the dark preset', () {
      final theme = WorkoutRunnerThemeData.dark();
      expect(theme.timerDefault.color, theme.textPrimary);
      expect(theme.timerWarning.color, theme.hot);
      expect(theme.timerSuccess.color, theme.success);
    });
  });

  group('WorkoutRunnerThemeData.fromColorScheme', () {
    test('uses the dark baseline when scheme.brightness is dark', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.dark,
      );
      final theme = WorkoutRunnerThemeData.fromColorScheme(scheme);

      expect(theme.accent, scheme.primary);
      expect(theme.background, scheme.surface);
      expect(theme.danger, scheme.error);
      // Every set type still has an accent.
      for (final type in SetType.values) {
        expect(theme.setTypeAccents[type], isNotNull);
      }
    });

    test('uses the light baseline when scheme.brightness is light', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF6E2ACF),
      );
      final theme = WorkoutRunnerThemeData.fromColorScheme(scheme);

      expect(theme.accent, scheme.primary);
      expect(theme.textPrimary, scheme.onSurface);
    });
  });
}
