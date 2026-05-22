import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: WorkoutRunnerTheme(
    data: WorkoutRunnerThemeData.dark(),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

WorkoutResult _result({
  String planId = 'Push Day',
  DateTime? finishedAt,
  int sets = 12,
  double volume = 4200,
}) {
  final finished = finishedAt ?? DateTime.utc(2026, 5, 18, 18, 30);
  final started = finished.subtract(const Duration(minutes: 45));
  // Build one exercise with enough sets/volume to satisfy the helpers.
  final perSet = sets == 0 ? 0.0 : (volume / sets);
  final performedSets = [
    for (var i = 0; i < sets; i++)
      PerformedSet(
        exerciseIndex: 0,
        setIndex: i,
        type: SetType.working,
        actualReps: 10,
        actualWeight: perSet / 10.0,
        completedAt: finished,
      ),
  ];
  return WorkoutResult(
    planId: planId,
    startedAt: started,
    finishedAt: finished,
    duration: finished.difference(started),
    exercises: [
      PerformedExerciseDetails(
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        sets: performedSets,
      ),
    ],
  );
}

void main() {
  group('WeeklySummaryCard', () {
    testWidgets('renders numeric values from the summary', (tester) async {
      final summary = WeeklyWorkoutSummary(
        start: DateTime.utc(2026, 5, 11),
        end: DateTime.utc(2026, 5, 18),
        workoutCount: 4,
        totalSets: 33,
        totalReps: 245,
        totalVolume: 12500,
        totalDuration: const Duration(hours: 3, minutes: 12),
      );
      await tester.pumpWidget(_wrap(WeeklySummaryCard(summary: summary)));

      expect(find.text('4'), findsOneWidget);
      expect(find.text('workouts'), findsOneWidget);
      expect(find.text('33'), findsOneWidget); // sets
      expect(find.text('245'), findsOneWidget); // reps
      expect(find.text('12500'), findsOneWidget); // volume
      // Duration formatted hh:mm:ss when > 1h via TimerText.format.
      expect(find.text('03:12:00'), findsOneWidget);
    });
  });

  group('PrHighlightsCard', () {
    testWidgets('limits to maxItems and sorts newest first', (tester) async {
      final older = PersonalRecord(
        exerciseId: 'squat',
        type: PrType.maxWeight,
        value: 100,
        unit: 'kg',
        achievedAt: DateTime.utc(2026, 1, 1),
        sourceResultId: 'a',
      );
      final mid = PersonalRecord(
        exerciseId: 'bench',
        type: PrType.estimated1RM,
        value: 120,
        unit: 'kg',
        achievedAt: DateTime.utc(2026, 3, 1),
        sourceResultId: 'b',
      );
      final newer = PersonalRecord(
        exerciseId: 'deadlift',
        type: PrType.maxWeight,
        value: 180,
        unit: 'kg',
        achievedAt: DateTime.utc(2026, 5, 1),
        sourceResultId: 'c',
      );
      final newest = PersonalRecord(
        exerciseId: 'row',
        type: PrType.bestVolumeSet,
        value: 900,
        unit: 'kg·reps',
        achievedAt: DateTime.utc(2026, 5, 15),
        sourceResultId: 'd',
      );

      await tester.pumpWidget(
        _wrap(
          PrHighlightsCard(
            // Intentionally unsorted input.
            prs: [older, newest, mid, newer],
            maxItems: 2,
          ),
        ),
      );

      // The two newest should be visible: newest + newer.
      expect(find.text('row'), findsOneWidget);
      expect(find.text('deadlift'), findsOneWidget);
      // The older two must NOT be visible.
      expect(find.text('bench'), findsNothing);
      expect(find.text('squat'), findsNothing);
    });

    testWidgets('shows empty state when no PRs are passed', (tester) async {
      await tester.pumpWidget(_wrap(const PrHighlightsCard(prs: [])));
      expect(find.text('No personal records yet.'), findsOneWidget);
    });
  });

  group('VolumeTrendChart', () {
    testWidgets('renders empty state for an empty data list', (tester) async {
      await tester.pumpWidget(_wrap(const VolumeTrendChart(data: [])));
      // Pump completes without throwing — that's the core requirement.
      expect(find.text('Not enough data yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders bars for non-empty data', (tester) async {
      await tester.pumpWidget(
        _wrap(
          VolumeTrendChart(
            data: [
              (weekStart: DateTime.utc(2026, 4, 6), volume: 1000),
              (weekStart: DateTime.utc(2026, 4, 13), volume: 2000),
              (weekStart: DateTime.utc(2026, 4, 20), volume: 1500),
              (weekStart: DateTime.utc(2026, 4, 27), volume: 2500),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // CustomPaint instance is present.
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('RecentSessionsList', () {
    testWidgets('shows plan names and fires onTap', (tester) async {
      WorkoutResult? tapped;
      final results = [
        _result(
          planId: 'Push Day',
          finishedAt: DateTime.utc(2026, 5, 18, 18, 30),
        ),
        _result(
          planId: 'Pull Day',
          finishedAt: DateTime.utc(2026, 5, 16, 19, 0),
        ),
      ];
      await tester.pumpWidget(
        _wrap(RecentSessionsList(results: results, onTap: (r) => tapped = r)),
      );

      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('Pull Day'), findsOneWidget);

      await tester.tap(find.text('Pull Day'));
      await tester.pump();
      expect(tapped, isNotNull);
      expect(tapped!.planId, 'Pull Day');
    });

    testWidgets('shows empty state with no results', (tester) async {
      await tester.pumpWidget(_wrap(const RecentSessionsList(results: [])));
      expect(find.text('No sessions yet.'), findsOneWidget);
    });
  });
}
