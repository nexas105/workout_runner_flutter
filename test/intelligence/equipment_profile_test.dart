import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EquipmentProfile', () {
    test('bodyweightOnly contains bodyweight and pullupBar only', () {
      final p = EquipmentProfile.bodyweightOnly();
      expect(p.has(EquipmentItem.bodyweight), isTrue);
      expect(p.has(EquipmentItem.pullupBar), isTrue);
      expect(p.has(EquipmentItem.barbell), isFalse);
      expect(p.items.length, 2);
    });

    test('commercialGym has barbell', () {
      final p = EquipmentProfile.commercialGym();
      expect(p.has(EquipmentItem.barbell), isTrue);
      expect(p.items.length, EquipmentItem.values.length);
    });

    test('copyWith overrides items', () {
      final base = EquipmentProfile.homeGymBasic();
      final updated = base.copyWith(items: {EquipmentItem.dumbbell});
      expect(updated.items, equals({EquipmentItem.dumbbell}));
      expect(updated.name, equals(base.name));
    });

    test('copyWith overrides name', () {
      final base = EquipmentProfile.bodyweightOnly();
      final renamed = base.copyWith(name: 'My Setup');
      expect(renamed.name, 'My Setup');
      expect(renamed.items, equals(base.items));
    });

    test('JSON round-trip preserves items and name', () {
      final p = EquipmentProfile(
        items: {EquipmentItem.barbell, EquipmentItem.bench},
        name: 'Garage',
      );
      final restored = EquipmentProfile.fromJson(p.toJson());
      expect(restored.items, equals(p.items));
      expect(restored.name, 'Garage');
      expect(restored, equals(p));
    });

    test('fromJson drops unknown ids without throwing', () {
      final json = {
        'items': ['barbell', 'time_machine', 42, 'dumbbell'],
        'name': 'Mixed',
      };
      final p = EquipmentProfile.fromJson(json);
      expect(p.items, equals({EquipmentItem.barbell, EquipmentItem.dumbbell}));
      expect(p.name, 'Mixed');
    });

    test('idSet plugs into PlanGenerationProfile.equipment', () {
      final equip = EquipmentProfile.homeGymBasic();
      final gen = PlanGenerationProfile(
        goal: TrainingGoal.hypertrophy,
        level: ExperienceLevel.intermediate,
        daysPerWeek: 4,
        equipment: equip.idSet,
      );
      expect(gen.equipment, contains('barbell'));
      expect(gen.equipment, contains('dumbbell'));
      expect(gen.equipment, contains('bench'));
      expect(gen.equipment.length, equip.items.length);
    });

    test('isEmpty reflects items', () {
      expect(EquipmentProfile().isEmpty, isTrue);
      expect(EquipmentProfile.bodyweightOnly().isEmpty, isFalse);
    });
  });
}
