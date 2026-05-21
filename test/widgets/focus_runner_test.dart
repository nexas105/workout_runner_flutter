import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _plan() => const WorkoutPlan(
      id: 'p',
      name: 'Push day',
      exercises: [
        WorkoutExercise(
          id: 'bench',
          name: 'Bench press',
          sets: [
            WorkoutSet(targetReps: 8, targetWeight: 60),
            WorkoutSet(targetReps: 8, targetWeight: 60),
          ],
        ),
        WorkoutExercise(
          id: 'press',
          name: 'OHP',
          sets: [WorkoutSet(targetReps: 6, targetWeight: 40)],
        ),
      ],
    );

Widget _wrap({required WorkoutRunner runner, required Widget child}) =>
    MaterialApp(
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: RunnerScope(
          runner: runner,
          child: Scaffold(body: child),
        ),
      ),
    );

Future<void> _withRunner(
  WidgetTester tester,
  Future<void> Function(WorkoutRunner runner) body,
) async {
  final runner = WorkoutRunner(storage: InMemoryRunnerStorage());
  await runner.start(_plan());
  try {
    await body(runner);
  } finally {
    await runner.cancel();
    runner.dispose();
  }
}

void main() {
  testWidgets('SessionHeader renders plan name + progress + elapsed',
      (tester) async {
    await _withRunner(tester, (runner) async {
      await tester.pumpWidget(_wrap(
        runner: runner,
        child: const SessionHeader(),
      ));
      expect(find.text('Push day'), findsOneWidget);
      // 0 of 3 sets done initially.
      expect(find.text('0 / 3'), findsOneWidget);
    });
  });

  testWidgets('ExerciseFocusCard shows "Up next" when nothing is running',
      (tester) async {
    await _withRunner(tester, (runner) async {
      runner.setActiveExercise(0);
      await tester.pumpWidget(_wrap(
        runner: runner,
        child: const ExerciseFocusCard(),
      ));
      expect(find.text('Bench press'), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
    });
  });

  testWidgets('NextUpStrip previews the next exercise', (tester) async {
    await _withRunner(tester, (runner) async {
      runner.setActiveExercise(0);
      await tester.pumpWidget(_wrap(
        runner: runner,
        child: const NextUpStrip(),
      ));
      expect(find.text('OHP'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
    });
  });

  testWidgets('SetTimeline renders one dot per set', (tester) async {
    await _withRunner(tester, (runner) async {
      runner.setActiveExercise(0);
      await tester.pumpWidget(_wrap(
        runner: runner,
        child: const SetTimeline(),
      ));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  testWidgets('FocusActionBar renders the primary action label',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: Scaffold(
          body: FocusActionBar(
            primaryLabel: 'Start set',
            primaryIcon: Icons.play_arrow_rounded,
            onPrimary: () {},
          ),
        ),
      ),
    ));
    expect(find.text('Start set'), findsOneWidget);
  });
}
