import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: child,
      ),
    );

CardioPlan _samplePlan() => CardioPlanBuilder(
      '5x400m intervals',
      discipline: CardioDiscipline.running,
      description: 'Lactate threshold session',
    )
        .warmup(duration: const Duration(minutes: 5))
        .interval(
          name: 'Sprint',
          duration: const Duration(minutes: 2),
          met: 11,
        )
        .rest(duration: const Duration(minutes: 1))
        .cooldown(duration: const Duration(minutes: 5))
        .build();

void main() {
  testWidgets(
    'renders empty form when existing is null and Save is disabled',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          CardioPlanEditorScreen(
            onSave: (_) {},
          ),
        ),
      );

      expect(find.byType(CardioPlanEditorScreen), findsOneWidget);

      final nameField = tester.widget<TextField>(
        find.byKey(const ValueKey('cardio-plan-name-field')),
      );
      expect(nameField.controller!.text, isEmpty);

      // No interval rows when starting empty.
      expect(find.text('No intervals yet'), findsOneWidget);

      // Save button is disabled (no name, no intervals).
      final save = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(const ValueKey('cardio-plan-save-button')),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(save.onTap, isNull);
    },
  );

  testWidgets(
    'pre-fills from existing plan: intervals count and discipline',
    (tester) async {
      final plan = _samplePlan();
      await tester.pumpWidget(
        _wrap(
          CardioPlanEditorScreen(
            existing: plan,
            onSave: (_) {},
          ),
        ),
      );

      // The name field is populated.
      final nameField = tester.widget<TextField>(
        find.byKey(const ValueKey('cardio-plan-name-field')),
      );
      expect(nameField.controller!.text, '5x400m intervals');

      // Each interval renders as a row keyed by its id.
      for (final interval in plan.intervals) {
        expect(
          find.byKey(ValueKey('cardio-plan-interval-${interval.id}')),
          findsOneWidget,
        );
      }

      // Discipline dropdown reflects the existing plan.
      final dropdown = tester.widget<DropdownButton<CardioDiscipline>>(
        find.byType(DropdownButton<CardioDiscipline>),
      );
      expect(dropdown.value, CardioDiscipline.running);
    },
  );

  testWidgets('adding an interval increments the row count', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CardioPlanEditorScreen(
          existing: _samplePlan(),
          onSave: (_) {},
        ),
      ),
    );

    int countRows() => find
        .byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.key is ValueKey &&
              (w.key as ValueKey).value is String &&
              ((w.key as ValueKey).value as String)
                  .startsWith('cardio-plan-interval-'),
        )
        .evaluate()
        .length;

    final before = countRows();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('cardio-plan-add-interval')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('cardio-plan-editor-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('cardio-plan-add-interval')));
    await tester.pump();

    final after = countRows();

    expect(after, before + 1);
  });

  testWidgets('removing the last interval disables Save', (tester) async {
    final plan = CardioPlanBuilder(
      'Solo',
      discipline: CardioDiscipline.running,
    ).interval(name: 'Only', duration: const Duration(minutes: 5)).build();

    await tester.pumpWidget(
      _wrap(
        CardioPlanEditorScreen(
          existing: plan,
          onSave: (_) {},
        ),
      ),
    );

    // Save starts enabled.
    final saveBefore = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byKey(const ValueKey('cardio-plan-save-button')),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(saveBefore.onTap, isNotNull);

    await tester.tap(
      find.byKey(const ValueKey('cardio-plan-interval-kebab')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();

    // The interval row is gone and Save is disabled again.
    expect(find.text('No intervals yet'), findsOneWidget);
    final saveAfter = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byKey(const ValueKey('cardio-plan-save-button')),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(saveAfter.onTap, isNull);
  });

  testWidgets('Save fires onSave with the constructed plan', (tester) async {
    CardioPlan? captured;
    final plan = _samplePlan();

    await tester.pumpWidget(
      _wrap(
        CardioPlanEditorScreen(
          existing: plan,
          onSave: (p) => captured = p,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('cardio-plan-save-button')));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.name, '5x400m intervals');
    expect(captured!.discipline, CardioDiscipline.running);
    expect(captured!.intervals.length, plan.intervals.length);
    expect(
      captured!.intervals.map((i) => i.phase).toList(),
      plan.intervals.map((i) => i.phase).toList(),
    );
  });
}
