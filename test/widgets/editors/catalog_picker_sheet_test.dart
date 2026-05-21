import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget Function(BuildContext) builder) => MaterialApp(
      home: WorkoutRunnerTheme(
        data: WorkoutRunnerThemeData.dark(),
        child: Scaffold(body: Builder(builder: builder)),
      ),
    );

void main() {
  testWidgets('Empty list shows an empty-state placeholder', (tester) async {
    await tester.pumpWidget(_host((context) {
      return Center(
        child: ElevatedButton(
          onPressed: () => CatalogPickerSheet.show<String>(
            context,
            items: const <String>[],
            labelOf: (s) => s,
            title: 'Pick exercise',
          ),
          child: const Text('open'),
        ),
      );
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Pick exercise'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('Search filters items (typing reduces results)', (tester) async {
    await tester.pumpWidget(_host((context) {
      return Center(
        child: ElevatedButton(
          onPressed: () => CatalogPickerSheet.show<String>(
            context,
            items: const ['Bench Press', 'Squat', 'Deadlift', 'Benchmark'],
            labelOf: (s) => s,
            title: 'Pick',
          ),
          child: const Text('open'),
        ),
      );
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Deadlift'), findsOneWidget);
    expect(find.text('Benchmark'), findsOneWidget);

    // Type "bench" into the search box — should leave only items containing it.
    await tester.enterText(find.byType(TextField).first, 'bench');
    await tester.pump();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Benchmark'), findsOneWidget);
    expect(find.text('Squat'), findsNothing);
    expect(find.text('Deadlift'), findsNothing);
  });

  testWidgets('Single-select returns the tapped item immediately',
      (tester) async {
    List<String>? result;
    await tester.pumpWidget(_host((context) {
      return Center(
        child: ElevatedButton(
          onPressed: () async {
            result = await CatalogPickerSheet.show<String>(
              context,
              items: const ['Alpha', 'Beta', 'Gamma'],
              labelOf: (s) => s,
              title: 'Pick one',
            );
          },
          child: const Text('open'),
        ),
      );
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Single-select tap on a row dismisses the sheet with that item.
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, ['Beta']);
  });

  testWidgets('Multi-select returns the list of toggled items on Done',
      (tester) async {
    List<String>? result;
    await tester.pumpWidget(_host((context) {
      return Center(
        child: ElevatedButton(
          onPressed: () async {
            result = await CatalogPickerSheet.show<String>(
              context,
              items: const ['Chest', 'Back', 'Legs', 'Shoulders'],
              labelOf: (s) => s,
              multiSelect: true,
              initialSelection: const ['Legs'],
              title: 'Pick muscles',
            );
          },
          child: const Text('open'),
        ),
      );
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Toggle "Chest" on, toggle "Legs" off, leave "Back" off.
    await tester.tap(find.text('Chest'));
    await tester.pump();
    await tester.tap(find.text('Legs'));
    await tester.pump();
    await tester.tap(find.text('Shoulders'));
    await tester.pump();

    // Tap "OK" to confirm the multi-select.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.toSet(), {'Chest', 'Shoulders'});
  });
}
