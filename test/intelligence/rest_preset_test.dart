import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kDefaultRestPresets', () {
    test('strength is 180s', () {
      expect(
        kDefaultRestPresets[RestGoal.strength]!.duration,
        const Duration(seconds: 180),
      );
      expect(kDefaultRestPresets[RestGoal.strength]!.label, 'Strength');
    });

    test('hypertrophy is 90s', () {
      expect(
        kDefaultRestPresets[RestGoal.hypertrophy]!.duration,
        const Duration(seconds: 90),
      );
      expect(kDefaultRestPresets[RestGoal.hypertrophy]!.label, 'Hypertrophy');
    });

    test('endurance is 45s', () {
      expect(
        kDefaultRestPresets[RestGoal.endurance]!.duration,
        const Duration(seconds: 45),
      );
      expect(kDefaultRestPresets[RestGoal.endurance]!.label, 'Endurance');
    });

    test('mobility is 30s', () {
      expect(
        kDefaultRestPresets[RestGoal.mobility]!.duration,
        const Duration(seconds: 30),
      );
      expect(kDefaultRestPresets[RestGoal.mobility]!.label, 'Mobility');
    });

    test('hiit is 20s', () {
      expect(
        kDefaultRestPresets[RestGoal.hiit]!.duration,
        const Duration(seconds: 20),
      );
      expect(kDefaultRestPresets[RestGoal.hiit]!.label, 'HIIT');
    });

    test('every RestGoal has a preset', () {
      for (final g in RestGoal.values) {
        expect(kDefaultRestPresets[g], isNotNull);
        expect(kDefaultRestPresets[g]!.goal, g);
      }
    });
  });

  group('RestPresetResolver.resolve', () {
    test('setDefault wins over everything else', () {
      final result = RestPresetResolver.resolve(
        planDefault: const Duration(seconds: 120),
        exerciseDefault: const Duration(seconds: 60),
        setDefault: const Duration(seconds: 15),
        planGoal: RestGoal.strength,
      );
      expect(result, const Duration(seconds: 15));
    });

    test('exerciseDefault wins when no setDefault', () {
      final result = RestPresetResolver.resolve(
        planDefault: const Duration(seconds: 120),
        exerciseDefault: const Duration(seconds: 60),
        planGoal: RestGoal.strength,
      );
      expect(result, const Duration(seconds: 60));
    });

    test('planDefault wins when no set/exercise default', () {
      final result = RestPresetResolver.resolve(
        planDefault: const Duration(seconds: 120),
        planGoal: RestGoal.strength,
      );
      expect(result, const Duration(seconds: 120));
    });

    test('planGoal resolves via preset map when no explicit defaults', () {
      final result = RestPresetResolver.resolve(planGoal: RestGoal.hiit);
      expect(result, const Duration(seconds: 20));
    });

    test('fallback is 90s when nothing supplied', () {
      expect(RestPresetResolver.resolve(), const Duration(seconds: 90));
    });
  });
}
