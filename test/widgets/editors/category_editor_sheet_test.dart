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
    ExerciseCategory? saved;
    await tester.pumpWidget(
      _wrap(CategoryEditorSheet(existing: null, onSave: (c) => saved = c)),
    );

    expect(find.text('New category'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(saved, isNull);
  });

  testWidgets('pre-fills fields for existing category', (tester) async {
    const existing = ExerciseCategory(
      id: 'compound',
      name: 'Compound Lifts',
      description: 'Multi-joint movements',
    );

    await tester.pumpWidget(
      _wrap(CategoryEditorSheet(existing: existing, onSave: (_) {})),
    );
    await tester.pump();

    expect(find.text('Edit category'), findsOneWidget);
    expect(find.text('Compound Lifts'), findsWidgets);
    expect(find.text('Multi-joint movements'), findsWidgets);
  });

  testWidgets('Save emits category with entered fields', (tester) async {
    ExerciseCategory? saved;
    await tester.pumpWidget(
      _wrap(CategoryEditorSheet(existing: null, onSave: (c) => saved = c)),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Isolation');
    await tester.enterText(fields.at(1), 'Single-joint moves');
    await tester.pump();

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.name, 'Isolation');
    expect(saved!.description, 'Single-joint moves');
    expect(saved!.id, 'isolation');
  });

  testWidgets('Save preserves existing id when editing', (tester) async {
    ExerciseCategory? saved;
    const existing = ExerciseCategory(
      id: 'keep-this-id',
      name: 'Keep',
      description: 'd',
    );
    await tester.pumpWidget(
      _wrap(CategoryEditorSheet(existing: existing, onSave: (c) => saved = c)),
    );

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.id, 'keep-this-id');
    expect(saved!.name, 'Keep');
    expect(saved!.description, 'd');
  });
}
