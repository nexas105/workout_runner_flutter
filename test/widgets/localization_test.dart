import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _De extends WorkoutRunnerLocalizations {
  const _De();
  @override
  String labelForSetType(SetType type) => switch (type) {
    SetType.working => 'Satz',
    SetType.warmup => 'Aufwärmen',
    SetType.drop => 'Drop',
    SetType.failure => 'Failure',
    SetType.amrap => 'AMRAP',
    SetType.timed => 'Zeit',
  };
  @override
  String get workoutComplete => 'Training abgeschlossen';
  @override
  String get statExercises => 'Übungen';
  @override
  String get statSets => 'Sätze';
  @override
  String get statReps => 'Wdh';
  @override
  String get statVolume => 'Volumen';
  @override
  String get restSkip => 'Pause überspringen';
}

WorkoutResult _result() => WorkoutResult(
  planId: 'p',
  startedAt: DateTime.utc(2026, 5, 21),
  finishedAt: DateTime.utc(2026, 5, 21, 0, 30),
  duration: const Duration(minutes: 30),
  exercises: [
    PerformedExerciseDetails(
      exerciseId: 'ex',
      exerciseName: 'Bench',
      sets: [
        PerformedSet(
          exerciseIndex: 0,
          setIndex: 0,
          actualReps: 8,
          actualWeight: 60,
          completedAt: DateTime.utc(2026, 5, 21),
        ),
      ],
    ),
  ],
);

Widget _wrap(Widget child, {WorkoutRunnerLocalizations? l}) => MaterialApp(
  home: WorkoutRunnerTheme(
    data: WorkoutRunnerThemeData.dark(),
    child:
        l == null
            ? child
            : WorkoutRunnerLocalizationsScope(data: l, child: child),
  ),
);

void main() {
  test('default localizations expose English defaults', () {
    const l = WorkoutRunnerLocalizations();
    expect(l.workoutComplete, 'Workout complete');
    expect(l.labelForSetType(SetType.warmup), 'Warmup');
    expect(l.formatWeight(60), '60');
    expect(l.formatWeight(62.5), '62.5');
  });

  testWidgets('ResultsView uses the localized "Workout complete" header', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(Scaffold(body: ResultsView(result: _result())), l: const _De()),
    );
    expect(find.text('Training abgeschlossen'), findsOneWidget);
    expect(find.text('Übungen'), findsOneWidget);
    expect(find.text('Sätze'), findsOneWidget);
  });

  testWidgets('Fallback to English when no scope is provided', (tester) async {
    await tester.pumpWidget(
      _wrap(Scaffold(body: ResultsView(result: _result()))),
    );
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
  });
}
