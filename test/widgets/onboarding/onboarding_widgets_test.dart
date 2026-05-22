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
  group('GoalPickerSheet', () {
    testWidgets('renders all 4 goals', (tester) async {
      await tester.pumpWidget(_wrap(GoalPickerSheet(onPick: (_) {})));
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Hypertrophy'), findsOneWidget);
      expect(find.text('Conditioning'), findsOneWidget);
      expect(find.text('General fitness'), findsOneWidget);
    });

    testWidgets('tap fires onPick with the goal', (tester) async {
      TrainingGoal? picked;
      await tester.pumpWidget(
        _wrap(GoalPickerSheet(onPick: (g) => picked = g)),
      );
      // Wrap in a navigator so Navigator.pop in the widget does not crash —
      // the MaterialApp root provides one.
      await tester.tap(find.text('Hypertrophy'));
      await tester.pumpAndSettle();
      expect(picked, TrainingGoal.hypertrophy);
    });

    testWidgets('static show resolves with the tapped goal', (tester) async {
      late BuildContext capturedCtx;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) {
              capturedCtx = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final future = GoalPickerSheet.show(capturedCtx);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Strength'));
      await tester.pumpAndSettle();
      expect(await future, TrainingGoal.strength);
    });
  });

  group('EquipmentPickerSheet', () {
    testWidgets('toggles selection and Done emits the set', (tester) async {
      Set<EquipmentItem>? saved;
      await tester.pumpWidget(
        _wrap(EquipmentPickerSheet(onSave: (s) => saved = s)),
      );

      await tester.tap(find.text('Barbell'));
      await tester.pump();
      await tester.tap(find.text('Dumbbell'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved, contains(EquipmentItem.barbell));
      expect(saved, contains(EquipmentItem.dumbbell));
      expect(saved!.length, 2);
    });

    testWidgets('toggling an already-selected item removes it', (tester) async {
      Set<EquipmentItem>? saved;
      await tester.pumpWidget(
        _wrap(
          EquipmentPickerSheet(
            initial: const {EquipmentItem.barbell},
            onSave: (s) => saved = s,
          ),
        ),
      );

      await tester.tap(find.text('Barbell'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!, isEmpty);
    });

    testWidgets('Bodyweight only quick-pick replaces the selection', (
      tester,
    ) async {
      Set<EquipmentItem>? saved;
      await tester.pumpWidget(
        _wrap(
          EquipmentPickerSheet(
            initial: const {EquipmentItem.barbell, EquipmentItem.dumbbell},
            onSave: (s) => saved = s,
          ),
        ),
      );

      await tester.tap(find.text('Bodyweight only'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(saved, contains(EquipmentItem.bodyweight));
      expect(saved, contains(EquipmentItem.pullupBar));
      expect(saved, isNot(contains(EquipmentItem.barbell)));
    });
  });

  group('ExperienceLevelPicker', () {
    testWidgets('renders all 3 levels and reflects value', (tester) async {
      ExperienceLevel current = ExperienceLevel.beginner;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (ctx, setState) {
              return ExperienceLevelPicker(
                value: current,
                onChanged: (l) => setState(() => current = l),
              );
            },
          ),
        ),
      );

      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);

      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      expect(current, ExperienceLevel.advanced);

      await tester.tap(find.text('Intermediate'));
      await tester.pumpAndSettle();
      expect(current, ExperienceLevel.intermediate);
    });
  });

  group('PlanGenerationProfileSheet', () {
    testWidgets('round-trips an initial profile', (tester) async {
      final initial = PlanGenerationProfile(
        goal: TrainingGoal.hypertrophy,
        level: ExperienceLevel.advanced,
        daysPerWeek: 4,
        equipment: {EquipmentItem.barbell.id, EquipmentItem.dumbbell.id},
      );

      PlanGenerationProfile? saved;
      await tester.pumpWidget(
        _wrap(
          PlanGenerationProfileSheet(
            initial: initial,
            onSave: (p) => saved = p,
          ),
        ),
      );

      // Sanity: initial level shown.
      expect(find.text('Advanced'), findsOneWidget);
      // daysPerWeek echoes "4".
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.goal, TrainingGoal.hypertrophy);
      expect(saved!.level, ExperienceLevel.advanced);
      expect(saved!.daysPerWeek, 4);
      expect(saved!.equipment, contains(EquipmentItem.barbell.id));
      expect(saved!.equipment, contains(EquipmentItem.dumbbell.id));
      expect(saved!.equipment.length, 2);
    });

    testWidgets('days-per-week stepper clamps to 3..6', (tester) async {
      PlanGenerationProfile? saved;
      await tester.pumpWidget(
        _wrap(PlanGenerationProfileSheet(onSave: (p) => saved = p)),
      );

      // Default 3 — decrement should stay at 3.
      final minusFinder = find.byIcon(Icons.remove_rounded);
      await tester.tap(minusFinder);
      await tester.pump();
      expect(find.text('3'), findsOneWidget);

      // Bump to 6.
      final plusFinder = find.byIcon(Icons.add_rounded);
      for (var i = 0; i < 5; i++) {
        await tester.tap(plusFinder);
        await tester.pump();
      }
      expect(find.text('6'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.daysPerWeek, 6);
    });
  });
}
