import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryCustomEntityRegistry registry;
  late Catalog catalog;

  setUp(() {
    registry = InMemoryCustomEntityRegistry();
    catalog = Catalog(registry);
  });

  test('without custom entries the catalog yields the defaults', () async {
    final muscles = await catalog.muscles();
    expect(muscles, isNotEmpty);
    expect(muscles.length, DefaultMuscles.all.length);
  });

  test('custom entries override defaults with the same id', () async {
    const customChest = Muscle(
      id: 'm_chest',
      name: 'Pectorals (custom)',
      group: 'upper',
    );
    await registry.put(CustomEntityKinds.muscles, customChest.toJson());

    final muscles = await catalog.muscles();
    final chest = muscles.firstWhere((m) => m.id == 'm_chest');
    expect(chest.name, 'Pectorals (custom)');
    // Total count stays the same (override, not append).
    expect(muscles.length, DefaultMuscles.all.length);
  });

  test('custom entries with new ids are appended', () async {
    const customMuscle = Muscle(id: 'm_forearm', name: 'Forearm', group: 'arm');
    await registry.put(CustomEntityKinds.muscles, customMuscle.toJson());
    final muscles = await catalog.muscles();
    expect(muscles.any((m) => m.id == 'm_forearm'), isTrue);
  });

  test('InMemoryCustomEntityRegistry rejects entries without an id', () async {
    expect(
      () => registry.put(CustomEntityKinds.muscles, {'name': 'no id'}),
      throwsArgumentError,
    );
  });

  test('remove drops a single entry; clear wipes the kind', () async {
    await registry.put(
      CustomEntityKinds.exercises,
      const WorkoutExercise(id: 'custom_ex', name: 'Custom').toJson(),
    );
    await registry.remove(CustomEntityKinds.exercises, 'custom_ex');
    expect(await registry.readAll(CustomEntityKinds.exercises), isEmpty);

    await registry.put(
      CustomEntityKinds.exercises,
      const WorkoutExercise(id: 'a', name: 'A').toJson(),
    );
    await registry.clear(CustomEntityKinds.exercises);
    expect(await registry.readAll(CustomEntityKinds.exercises), isEmpty);
  });
}
