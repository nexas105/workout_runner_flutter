import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutResult _result() => WorkoutResult(
  planId: 'p',
  startedAt: DateTime.utc(2026, 5, 21),
  finishedAt: DateTime.utc(2026, 5, 21, 0, 30),
  duration: const Duration(minutes: 30),
  exercises: const [],
);

CardioResult _cardioResult() => CardioResult(
  planId: 'p',
  planName: 'Run',
  discipline: CardioDiscipline.running,
  startedAt: DateTime.utc(2026, 5, 21),
  finishedAt: DateTime.utc(2026, 5, 21, 0, 20),
  duration: const Duration(minutes: 20),
  laps: const [],
);

Widget _wrap(Widget child) => MaterialApp(
  home: WorkoutRunnerTheme(
    data: WorkoutRunnerThemeData.dark(),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('ResultsView.statBuilder replaces the default stat row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ResultsView(
          result: _result(),
          statBuilder:
              (ctx, r) => const [ResultsStatTile(label: 'Custom', value: '42')],
        ),
      ),
    );
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    // Default tiles should NOT appear.
    expect(find.text('Exercises'), findsNothing);
  });

  testWidgets('CardioResultsView.statBuilder replaces the default stat row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CardioResultsView(
          result: _cardioResult(),
          statBuilder:
              (ctx, r) => const [
                CardioResultsStatTile(label: 'Calories', value: '420'),
              ],
        ),
      ),
    );
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Laps'), findsNothing);
  });
}
