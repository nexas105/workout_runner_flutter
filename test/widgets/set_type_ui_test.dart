import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required WorkoutRunner runner, required Widget child}) =>
    MaterialApp(
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: RunnerScope(
          runner: runner,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

WorkoutPlan _typedPlan() => const WorkoutPlan(
      id: 'p',
      name: 'Push',
      exercises: [
        WorkoutExercise(
          id: 'ex',
          name: 'Bench',
          sets: [
            WorkoutSet(targetReps: 8, type: SetType.warmup),
            WorkoutSet(
              targetReps: 0,
              type: SetType.amrap,
              targetDuration: Duration(seconds: 60),
            ),
            WorkoutSet(
              targetReps: 0,
              type: SetType.timed,
              targetDuration: Duration(seconds: 45),
            ),
            WorkoutSet(targetReps: 8, targetWeight: 60),
          ],
        ),
      ],
    );

void main() {
  Future<void> runWithPlan(
    WidgetTester tester,
    Future<void> Function(WorkoutRunner runner, WorkoutPlan plan) body,
  ) async {
    final runner = WorkoutRunner(storage: InMemoryRunnerStorage());
    await runner.start(_typedPlan());
    try {
      await body(runner, runner.plan!);
    } finally {
      await runner.cancel();
      runner.dispose();
    }
  }

  testWidgets('SetRow shows the type label for non-working sets',
      (tester) async {
    await runWithPlan(tester, (runner, plan) async {
      await tester.pumpWidget(_wrap(
        runner: runner,
        child: Column(
          children: [
            for (var i = 0; i < plan.exercises.first.sets.length; i++)
              SetRow(
                exerciseIndex: 0,
                setIndex: i,
                target: plan.exercises.first.sets[i],
              ),
          ],
        ),
      ));

      expect(find.text('Warmup'), findsOneWidget);
      expect(find.text('AMRAP'), findsOneWidget);
      expect(find.text('Timed'), findsOneWidget);
    });
  });

  testWidgets('AMRAP set shows AMRAP target line, timed shows Hold',
      (tester) async {
    await runWithPlan(tester, (runner, plan) async {
      await tester.pumpWidget(_wrap(
        runner: runner,
        child: Column(
          children: [
            for (var i = 0; i < plan.exercises.first.sets.length; i++)
              SetRow(
                exerciseIndex: 0,
                setIndex: i,
                target: plan.exercises.first.sets[i],
              ),
          ],
        ),
      ));

      expect(find.textContaining('AMRAP — '), findsOneWidget);
      expect(find.textContaining('Hold '), findsOneWidget);
    });
  });
}
