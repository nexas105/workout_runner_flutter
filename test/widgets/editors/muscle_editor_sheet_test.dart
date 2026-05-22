import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: WorkoutRunnerTheme(
    data: WorkoutRunnerThemeData.dark(),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('renders empty form when existing is null', (tester) async {
    Muscle? saved;
    await tester.pumpWidget(
      _wrap(MuscleEditorSheet(existing: null, onSave: (m) => saved = m)),
    );

    expect(find.text('New muscle'), findsOneWidget);
    // Save disabled with empty name
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(saved, isNull);
  });

  testWidgets('pre-fills fields for existing muscle', (tester) async {
    const existing = Muscle(
      id: 'biceps-brachii',
      name: 'Biceps Brachii',
      group: 'Upper arm',
    );

    await tester.pumpWidget(
      _wrap(MuscleEditorSheet(existing: existing, onSave: (_) {})),
    );
    await tester.pump();

    expect(find.text('Edit muscle'), findsOneWidget);
    expect(find.text('Biceps Brachii'), findsWidgets);
    expect(find.text('Upper arm'), findsWidgets);
  });

  testWidgets('Save emits muscle with entered name and group', (tester) async {
    Muscle? saved;
    await tester.pumpWidget(
      _wrap(MuscleEditorSheet(existing: null, onSave: (m) => saved = m)),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Triceps');
    await tester.enterText(fields.at(1), 'Upper arm');
    await tester.pump();

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.name, 'Triceps');
    expect(saved!.group, 'Upper arm');
    expect(saved!.id, 'triceps');
  });

  testWidgets('Save preserves existing id when editing', (tester) async {
    Muscle? saved;
    const existing = Muscle(id: 'keep-me', name: 'Keep Me', group: 'g');
    await tester.pumpWidget(
      _wrap(MuscleEditorSheet(existing: existing, onSave: (m) => saved = m)),
    );

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.id, 'keep-me');
    expect(saved!.name, 'Keep Me');
    expect(saved!.group, 'g');
  });
}
