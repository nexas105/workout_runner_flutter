import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: child,
      ),
    );

WorkoutPlan _samplePlan() => WorkoutPlanBuilder('Push day', id: 'push-day')
    .exercise('Bench press', id: 'bench')
    .set(reps: 5, weight: 80)
    .set(reps: 5, weight: 80)
    .exercise('Overhead press', id: 'ohp')
    .set(reps: 8, weight: 40)
    .build();

void main() {
  testWidgets(
      'PlanEditorScreen with existing: null renders empty form and Save is disabled',
      (tester) async {
    WorkoutPlan? saved;
    await tester.pumpWidget(_wrap(PlanEditorScreen(
      existing: null,
      onSave: (plan) => saved = plan,
    )));

    // Empty header summary
    expect(find.text('Empty plan'), findsOneWidget);

    // No exercises message
    expect(
      find.text('No exercises yet. Tap "Add exercise" below.'),
      findsOneWidget,
    );

    // Validation badge surfaces errors (red).
    expect(find.byKey(const Key('plan_editor_validation_badge')),
        findsOneWidget);
    expect(find.text('Errors'), findsOneWidget);

    // Tap the save button — should not fire onSave because it's disabled.
    await tester.tap(
      find.byKey(const Key('plan_editor_save_button')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(saved, isNull);
  });

  testWidgets('PlanEditorScreen pre-fills name and exercises from existing plan',
      (tester) async {
    await tester.pumpWidget(_wrap(PlanEditorScreen(
      existing: _samplePlan(),
      onSave: (_) {},
    )));

    // Name field shows the plan name (it appears in both the AppBar TextField
    // and the meta-block "Name" MetaFieldRow input).
    expect(find.text('Push day'), findsNWidgets(2));

    // Both exercises render.
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Overhead press'), findsOneWidget);

    // Summary lines: 2 × 5 @ 80 kg, 1 × 8 @ 40 kg.
    expect(find.text('2 × 5 @ 80 kg'), findsOneWidget);
    expect(find.text('1 × 8 @ 40 kg'), findsOneWidget);

    // Plan should validate cleanly — badge is "Valid".
    expect(find.text('Valid'), findsOneWidget);
  });

  testWidgets('Editing the name and tapping Save fires onSave with new name',
      (tester) async {
    WorkoutPlan? saved;
    await tester.pumpWidget(_wrap(PlanEditorScreen(
      existing: _samplePlan(),
      onSave: (plan) => saved = plan,
    )));

    // Rewrite the name in the AppBar field.
    await tester.enterText(
      find.byKey(const Key('plan_editor_name_field')),
      'Renamed plan',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('plan_editor_save_button')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.name, 'Renamed plan');
    // id preserved from the existing plan.
    expect(saved!.id, 'push-day');
    expect(saved!.exercises.length, 2);
  });

  testWidgets('Reordering exercises is reflected in the saved plan',
      (tester) async {
    WorkoutPlan? saved;
    await tester.pumpWidget(_wrap(PlanEditorScreen(
      existing: _samplePlan(),
      onSave: (plan) => saved = plan,
    )));

    // Use the private reorderable state poke via the public callback path:
    // tap & long-press drag would be flaky in a unit test, so we invoke the
    // ReorderableListView's onReorder directly by finding the widget.
    final reorderableFinder =
        find.byKey(const Key('plan_editor_exercise_list'));
    expect(reorderableFinder, findsOneWidget);
    final reorderable =
        tester.widget<ReorderableListView>(reorderableFinder);
    // Move exercise at index 0 (Bench) past index 1 (OHP).
    reorderable.onReorder(0, 2);
    await tester.pump();

    await tester.tap(find.byKey(const Key('plan_editor_save_button')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.exercises.first.name, 'Overhead press');
    expect(saved!.exercises.last.name, 'Bench press');
  });

  testWidgets('Add-exercise via inline editor increases exercise count',
      (tester) async {
    WorkoutPlan? saved;
    await tester.pumpWidget(_wrap(PlanEditorScreen(
      existing: _samplePlan(),
      onSave: (plan) => saved = plan,
    )));

    final initialExerciseCount = 2;
    expect(find.text('Bench press'), findsOneWidget);

    // Open the inline exercise editor.
    await tester.tap(find.byKey(const Key('plan_editor_add_exercise_button')));
    await tester.pumpAndSettle();

    // Sheet header.
    expect(find.text('New exercise'), findsOneWidget);

    // Fill in the name field (the bottom-sheet's "Name" MetaFieldRow.text).
    // There are several text fields, but only the inline editor's are
    // currently mounted alongside the plan name. We target the new ones by
    // typing into the first TextField in the bottom sheet — the inline
    // editor uses the standard text input layout.
    final sheetNameField = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    expect(sheetNameField, findsWidgets);
    await tester.enterText(sheetNameField.first, 'Squat');
    await tester.pump();

    await tester.tap(find.byKey(const Key('plan_editor_inline_save_button')));
    await tester.pumpAndSettle();

    // List grew by one.
    expect(find.text('Squat'), findsOneWidget);

    await tester.tap(find.byKey(const Key('plan_editor_save_button')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.exercises.length, initialExerciseCount + 1);
    expect(saved!.exercises.last.name, 'Squat');
  });
}
