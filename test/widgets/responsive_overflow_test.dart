import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(360, 800)}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: WorkoutRunnerTheme(
      data: WorkoutRunnerThemeData.dark(),
      child: Scaffold(body: SizedBox.expand(child: child)),
    ),
  ),
);

void main() {
  testWidgets('TimerText survives both narrow and wide constraints', (
    tester,
  ) async {
    for (final size in const [Size(320, 600), Size(900, 700)]) {
      await tester.pumpWidget(
        _wrap(
          const Center(child: TimerText(duration: Duration(minutes: 12))),
          size: size,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(TimerText), findsOneWidget);
    }
  });

  testWidgets('RunnerPillButton stays >=48 dp tall under tight width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Center(
          child: SizedBox(
            width: 160,
            child: RunnerPillButton(
              label: 'A very very very long label that would overflow',
              onPressed: () {},
            ),
          ),
        ),
        size: const Size(320, 600),
      ),
    );

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(RunnerPillButton));
    expect(size.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('ResultsView renders with disableAnimations without throwing', (
    tester,
  ) async {
    final result = WorkoutResult(
      planId: 'p',
      startedAt: DateTime.utc(2026, 5, 21),
      finishedAt: DateTime.utc(2026, 5, 21, 0, 30),
      duration: const Duration(minutes: 30),
      exercises: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            disableAnimations: true,
          ),
          child: WorkoutRunnerTheme(
            data: WorkoutRunnerThemeData.dark(),
            child: Scaffold(body: ResultsView(result: result)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Workout complete'), findsOneWidget);
  });
}
