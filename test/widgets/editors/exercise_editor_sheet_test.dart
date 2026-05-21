import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _category = ExerciseCategory(id: 'compound', name: 'Compound');
const _otherCategory =
    ExerciseCategory(id: 'isolation', name: 'Isolation');
const _muscle = Muscle(id: 'quads', name: 'Quadriceps', group: 'Lower');
const _muscle2 = Muscle(id: 'glutes', name: 'Glutes', group: 'Lower');

Widget _wrap(Widget child) => MaterialApp(
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('renders empty form when existing is null', (tester) async {
    WorkoutExercise? saved;
    await tester.pumpWidget(
      _wrap(
        ExerciseEditorSheet(
          existing: null,
          categories: const [_category, _otherCategory],
          muscles: const [_muscle, _muscle2],
          onSave: (ex) => saved = ex,
        ),
      ),
    );

    expect(find.text('New exercise'), findsOneWidget);
    // Save should be disabled until name is provided — tap should be a no-op.
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(saved, isNull);
  });

  testWidgets('pre-fills fields for existing exercise', (tester) async {
    const existing = WorkoutExercise(
      id: 'goblet-squat',
      name: 'Goblet Squat',
      description: 'Front-loaded squat',
      category: _category,
      muscles: [_muscle],
      met: 6.0,
      notes: 'Keep heels grounded',
      unilateral: false,
      equipment: ExerciseEquipment.dumbbell,
      movementPattern: MovementPattern.squat,
      difficulty: ExerciseDifficulty.beginner,
      aliases: ['db squat'],
    );

    await tester.pumpWidget(
      _wrap(
        ExerciseEditorSheet(
          existing: existing,
          categories: const [_category, _otherCategory],
          muscles: const [_muscle, _muscle2],
          onSave: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Edit exercise'), findsOneWidget);
    // Name field is pre-filled (EditableText + a Text mirror inside
    // Flutter's TextField render tree both match `find.text`).
    expect(find.text('Goblet Squat'), findsWidgets);
    // Category appears in the picker row
    expect(find.text('Compound'), findsWidgets);
    // Muscle appears in the picker row summary
    expect(find.text('Quadriceps'), findsWidgets);
  });

  testWidgets('Save emits exercise with edited name', (tester) async {
    WorkoutExercise? saved;
    await tester.pumpWidget(
      _wrap(
        ExerciseEditorSheet(
          existing: null,
          categories: const [_category],
          muscles: const [_muscle],
          onSave: (ex) => saved = ex,
        ),
      ),
    );

    // Enter a name in the first TextField (the "Name" row).
    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'Front Squat');
    await tester.pump();

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.name, 'Front Squat');
    // Id is slugified from the name on create.
    expect(saved!.id, 'front-squat');
    // MET defaults to 5.0 in create mode.
    expect(saved!.met, 5.0);
  });

  testWidgets('Save preserves existing id when editing', (tester) async {
    WorkoutExercise? saved;
    const existing = WorkoutExercise(
      id: 'preserved-id',
      name: 'Old Name',
      met: 4.0,
      equipment: ExerciseEquipment.barbell,
    );
    await tester.pumpWidget(
      _wrap(
        ExerciseEditorSheet(
          existing: existing,
          categories: const [_category],
          muscles: const [_muscle],
          onSave: (ex) => saved = ex,
        ),
      ),
    );

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.id, 'preserved-id');
    expect(saved!.name, 'Old Name');
    expect(saved!.met, 4.0);
    expect(saved!.equipment, ExerciseEquipment.barbell);
  });
}
