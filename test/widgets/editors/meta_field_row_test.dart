import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: WorkoutRunnerTheme(
    data: WorkoutRunnerThemeData.dark(),
    child: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  testWidgets('MetaFieldRow.text renders label + value and fires onChanged', (
    tester,
  ) async {
    String captured = '';
    await tester.pumpWidget(
      _wrap(
        MetaFieldRow.text(
          label: 'Name',
          value: 'Bench Press',
          hint: 'Enter name',
          onChanged: (v) => captured = v,
        ),
      ),
    );

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Goblet Squat');
    await tester.pump();
    expect(captured, 'Goblet Squat');
  });

  testWidgets('MetaFieldRow.toggle renders Switch and fires onChanged', (
    tester,
  ) async {
    bool? captured;
    await tester.pumpWidget(
      _wrap(
        MetaFieldRow.toggle(
          label: 'Unilateral',
          value: false,
          onChanged: (v) => captured = v,
        ),
      ),
    );

    expect(find.text('Unilateral'), findsOneWidget);
    final switchFinder = find.byWidgetPredicate((w) => w is Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(captured, isTrue);
  });

  testWidgets('MetaFieldRow.stepper renders HeroStepper and fires onChanged', (
    tester,
  ) async {
    num captured = 0;
    await tester.pumpWidget(
      _wrap(
        MetaFieldRow.stepper(
          label: 'MET',
          value: 5,
          min: 0,
          max: 20,
          smallStep: 1,
          integer: true,
          onChanged: (v) => captured = v,
        ),
      ),
    );

    // Label rendered (from both the row and the stepper itself).
    expect(find.text('MET'), findsWidgets);
    // Current value rendered.
    expect(find.text('5'), findsOneWidget);

    // Tap the increment "+" icon to advance.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(captured, 6);
  });

  testWidgets(
    'MetaFieldRow.dropdown renders DropdownButton and fires onChanged',
    (tester) async {
      String? captured;
      await tester.pumpWidget(
        _wrap(
          MetaFieldRow.dropdown<String>(
            label: 'Group',
            value: 'push',
            items: const [
              DropdownMenuItem(value: 'push', child: Text('Push')),
              DropdownMenuItem(value: 'pull', child: Text('Pull')),
            ],
            onChanged: (v) => captured = v,
          ),
        ),
      );

      expect(find.text('Group'), findsOneWidget);

      await tester.tap(find.text('Push').first);
      await tester.pumpAndSettle();
      // The dropdown opens; tap the "Pull" entry from the menu.
      await tester.tap(find.text('Pull').last);
      await tester.pumpAndSettle();
      expect(captured, 'pull');
    },
  );
}
