import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weight formatting', () {
    test('integer kg has no decimals', () {
      expect(
        WorkoutRunnerUnitFormatters.weight(60, MeasurementSystem.metric),
        '60 kg',
      );
    });

    test('fractional kg keeps one decimal by default', () {
      expect(
        WorkoutRunnerUnitFormatters.weight(22.5, MeasurementSystem.metric),
        '22.5 kg',
      );
    });

    test('imperial converts kg → lb', () {
      // 60 kg = 132.277… lb → "132 lb" at the default 1-decimal precision.
      expect(
        WorkoutRunnerUnitFormatters.weight(60.0, MeasurementSystem.imperial),
        '132.3 lb',
      );
    });

    test('includeUnit: false drops the suffix', () {
      expect(
        WorkoutRunnerUnitFormatters.weight(
          60,
          MeasurementSystem.metric,
          includeUnit: false,
        ),
        '60',
      );
    });
  });

  group('distance formatting', () {
    test('metric < 1 km falls back to metres', () {
      expect(
        WorkoutRunnerUnitFormatters.distance(320, MeasurementSystem.metric),
        '320 m',
      );
    });

    test('metric km uses 2 decimals by default', () {
      expect(
        WorkoutRunnerUnitFormatters.distance(5000, MeasurementSystem.metric),
        '5 km',
      );
      expect(
        WorkoutRunnerUnitFormatters.distance(5250, MeasurementSystem.metric),
        '5.25 km',
      );
    });

    test('imperial < 1 mile falls back to feet', () {
      expect(
        WorkoutRunnerUnitFormatters.distance(500, MeasurementSystem.imperial),
        // 500 m = ~1640 ft
        '1640 ft',
      );
    });

    test('imperial miles', () {
      expect(
        WorkoutRunnerUnitFormatters.distance(5000, MeasurementSystem.imperial),
        '3.11 mi',
      );
    });
  });

  group('pace formatting', () {
    test('null pace renders as em-dash', () {
      expect(
        WorkoutRunnerUnitFormatters.pace(null, MeasurementSystem.metric),
        '—',
      );
      expect(
        WorkoutRunnerUnitFormatters.pace(
          Duration.zero,
          MeasurementSystem.metric,
        ),
        '—',
      );
    });

    test('5:30 /km in metric', () {
      expect(
        WorkoutRunnerUnitFormatters.pace(
          const Duration(minutes: 5, seconds: 30),
          MeasurementSystem.metric,
        ),
        '5:30 /km',
      );
    });

    test('imperial converts km → mile', () {
      // 5:30 /km × 1.609 ≈ 8:51 /mi
      expect(
        WorkoutRunnerUnitFormatters.pace(
          const Duration(minutes: 5, seconds: 30),
          MeasurementSystem.imperial,
        ),
        '8:51 /mi',
      );
    });

    test('pads seconds to two digits', () {
      expect(
        WorkoutRunnerUnitFormatters.pace(
          const Duration(minutes: 4, seconds: 5),
          MeasurementSystem.metric,
        ),
        '4:05 /km',
      );
    });
  });

  group('speed formatting', () {
    test('metric km/h', () {
      expect(
        WorkoutRunnerUnitFormatters.speed(10.0, MeasurementSystem.metric),
        '36 km/h',
      );
    });

    test('imperial mph', () {
      // 10 m/s = ~22.37 mph
      expect(
        WorkoutRunnerUnitFormatters.speed(10.0, MeasurementSystem.imperial),
        '22.4 mph',
      );
    });
  });

  group('unit labels', () {
    test('weight / distance / pace / speed', () {
      expect(
        WorkoutRunnerUnitFormatters.weightUnit(MeasurementSystem.metric),
        'kg',
      );
      expect(
        WorkoutRunnerUnitFormatters.weightUnit(MeasurementSystem.imperial),
        'lb',
      );
      expect(
        WorkoutRunnerUnitFormatters.longDistanceUnit(
          MeasurementSystem.imperial,
        ),
        'mi',
      );
      expect(
        WorkoutRunnerUnitFormatters.shortDistanceUnit(
          MeasurementSystem.imperial,
        ),
        'ft',
      );
      expect(
        WorkoutRunnerUnitFormatters.paceUnit(MeasurementSystem.imperial),
        '/mi',
      );
      expect(
        WorkoutRunnerUnitFormatters.speedUnit(MeasurementSystem.imperial),
        'mph',
      );
    });
  });
}
