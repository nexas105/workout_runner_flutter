import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final completedAt = DateTime.utc(2026, 5, 21, 11, 0, 0);

  CardioResult buildResult({List<CardioLap> laps = const []}) => CardioResult(
    planId: 'plan_run',
    planName: 'Morning, run',
    discipline: CardioDiscipline.running,
    startedAt: completedAt.subtract(const Duration(minutes: 20)),
    finishedAt: completedAt,
    duration: const Duration(minutes: 20),
    laps: laps,
  );

  group('CardioResult.toCsv', () {
    test('emits header plus one row per lap', () {
      final result = buildResult(
        laps: [
          CardioLap.computed(
            intervalIndex: 0,
            duration: const Duration(minutes: 5),
            distanceMeters: 1000,
            avgHeartRate: 150,
            completedAt: completedAt,
          ),
          CardioLap.computed(
            intervalIndex: 1,
            duration: const Duration(minutes: 3),
            completedAt: completedAt,
          ),
        ],
      );

      final csv = result.toCsv();
      final lines = csv.trim().split('\n');
      expect(lines.length, 3);
      expect(lines.first.startsWith('planId,planName'), isTrue);
      // Comma in plan name must be quoted.
      expect(lines[1].contains('"Morning, run"'), isTrue);
      expect(lines[1].contains(',running,'), isTrue);
      // First lap has distance + HR; second is null on both.
      expect(lines[1].split(',').contains('1000.0'), isTrue);
      expect(
        lines[2].split(',').where((c) => c.isEmpty).length,
        greaterThanOrEqualTo(3),
      );
    });

    test('header-only output when no laps', () {
      final lines = buildResult().toCsv().trim().split('\n');
      expect(lines.length, 1);
      expect(lines.first.startsWith('planId'), isTrue);
    });
  });

  group('CardioResult JSON round-trip', () {
    test('round-trips with non-empty laps', () {
      final original = buildResult(
        laps: [
          CardioLap.computed(
            intervalIndex: 0,
            duration: const Duration(seconds: 90),
            distanceMeters: 250,
            completedAt: completedAt,
          ),
        ],
      );

      final round = CardioResult.fromJson(original.toJson());
      expect(round.planId, original.planId);
      expect(round.planName, original.planName);
      expect(round.discipline, original.discipline);
      expect(round.laps.length, 1);
      expect(round.laps.first.distanceMeters, 250);
    });
  });
}
