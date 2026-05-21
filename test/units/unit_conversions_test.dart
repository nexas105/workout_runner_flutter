import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weight', () {
    test('kg ↔ lb round-trips', () {
      expect(kgToLb(1.0), closeTo(2.20462262, 1e-6));
      expect(lbToKg(1.0), closeTo(0.45359237, 1e-9));
      // Round-trip a few real-life weights.
      for (final kg in [0.5, 20.0, 60.0, 100.0, 142.5]) {
        expect(lbToKg(kgToLb(kg)), closeTo(kg, 1e-9));
      }
    });

    test('weightToSystem / weightFromSystem are inverses', () {
      for (final system in MeasurementSystem.values) {
        for (final kg in [0.0, 10.0, 60.0, 137.5]) {
          final v = weightToSystem(kg, system);
          expect(weightFromSystem(v, system), closeTo(kg, 1e-9));
        }
      }
    });

    test('metric passes through unchanged', () {
      expect(weightToSystem(42.0, MeasurementSystem.metric), 42.0);
      expect(weightFromSystem(42.0, MeasurementSystem.metric), 42.0);
    });
  });

  group('distance', () {
    test('1 mile = 1609.344 metres exact', () {
      expect(milesToMeters(1.0), kMetersPerMile);
      expect(metersToMiles(kMetersPerMile), 1.0);
    });

    test('km / mile round-trips through system helpers', () {
      for (final system in MeasurementSystem.values) {
        for (final meters in [100.0, 1000.0, 5000.0, 42195.0]) {
          final v = distanceToSystem(meters, system);
          expect(distanceFromSystem(v, system), closeTo(meters, 1e-6));
        }
      }
    });

    test('feet conversion is exact', () {
      expect(metersToFeet(1.0), closeTo(1.0 / 0.3048, 1e-9));
      expect(feetToMeters(metersToFeet(123.4)), closeTo(123.4, 1e-9));
    });
  });

  group('pace', () {
    test('pacePerKm returns null for zero distance or duration', () {
      expect(
        pacePerKm(duration: const Duration(minutes: 5), distanceMeters: 0),
        isNull,
      );
      expect(pacePerKm(duration: Duration.zero, distanceMeters: 1000), isNull);
    });

    test('5 min over 1 km → 5:00 /km', () {
      final p = pacePerKm(
        duration: const Duration(minutes: 5),
        distanceMeters: 1000,
      );
      expect(p, const Duration(minutes: 5));
    });

    test('km → mile conversion ~1.609x', () {
      const perKm = Duration(minutes: 5);
      final perMile = pacePerKmToPerMile(perKm);
      expect(perMile.inSeconds, closeTo(5 * 60 * (1609.344 / 1000), 1));
    });

    test('paceToSystem / paceFromSystem are inverses', () {
      const perKm = Duration(minutes: 5, seconds: 30);
      for (final system in MeasurementSystem.values) {
        final v = paceToSystem(perKm, system);
        expect(
          paceFromSystem(v, system).inSeconds,
          closeTo(perKm.inSeconds, 1),
        );
      }
    });
  });

  group('speed', () {
    test('metersPerSecond returns null for zero inputs', () {
      expect(
        metersPerSecond(duration: Duration.zero, distanceMeters: 100),
        isNull,
      );
      expect(
        metersPerSecond(
          duration: const Duration(seconds: 10),
          distanceMeters: 0,
        ),
        isNull,
      );
    });

    test('10 m/s = 36 km/h and ~22.37 mph', () {
      expect(mpsToKmh(10), closeTo(36.0, 1e-9));
      expect(mpsToMph(10), closeTo(22.369362920544, 1e-6));
    });
  });

  group('MeasurementSystem serializer', () {
    test('round-trips id', () {
      for (final s in MeasurementSystem.values) {
        expect(MeasurementSystemSerializer.fromId(s.id), s);
      }
    });

    test('falls back to metric on unknown / null', () {
      expect(
        MeasurementSystemSerializer.fromId('nonsense'),
        MeasurementSystem.metric,
      );
      expect(
        MeasurementSystemSerializer.fromId(null),
        MeasurementSystem.metric,
      );
    });
  });
}
