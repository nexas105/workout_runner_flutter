import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('TimerText announces hours/minutes/seconds via Semantics',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const TimerText(duration: Duration(minutes: 1, seconds: 30))),
    );

    final node = tester.getSemantics(find.byType(TimerText));
    expect(node.value, contains('1 minutes'));
    expect(node.value, contains('30 seconds'));
  });

  testWidgets('TimerText hides the raw digits from screen readers',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(const TimerText(duration: Duration(seconds: 42))),
    );
    final node = tester.getSemantics(find.byType(TimerText));
    expect(node.label, isEmpty);
    handle.dispose();
  });

  testWidgets('RunnerPillButton enforces a minimum 48 dp tap target',
      (tester) async {
    await tester.pumpWidget(
      _wrap(RunnerPillButton(label: 'Go', onPressed: () {})),
    );
    final size = tester.getSize(find.byType(RunnerPillButton));
    expect(size.height, greaterThanOrEqualTo(48.0));
  });
}
