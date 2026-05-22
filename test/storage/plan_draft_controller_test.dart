import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _plan(String id, {String? name}) =>
    WorkoutPlan(id: id, name: name ?? 'Plan $id', exercises: const []);

const _debounce = Duration(milliseconds: 40);
final _afterDebounce = _debounce * 3;

void main() {
  late InMemoryPlanDraftStorage storage;
  late PlanDraftController controller;

  setUp(() {
    storage = InMemoryPlanDraftStorage();
    controller = PlanDraftController(storage: storage, debounce: _debounce);
  });

  tearDown(() async {
    await controller.dispose();
  });

  test(
    'rapid onPlanChanged calls only save the LAST plan after debounce',
    () async {
      await controller.onPlanChanged(_plan('p', name: 'v1'));
      await controller.onPlanChanged(_plan('p', name: 'v2'));
      await controller.onPlanChanged(_plan('p', name: 'v3'));

      expect(
        await storage.hasDraft(),
        isFalse,
        reason: 'nothing should be persisted before the debounce elapses',
      );

      await Future<void>.delayed(_afterDebounce);

      final saved = await storage.readDraft();
      expect(saved, isNotNull);
      expect(saved!.name, 'v3');
    },
  );

  test('resume returns the active slot draft', () async {
    await storage.saveDraft(_plan('p', name: 'resumed'));
    final plan = await controller.resume();
    expect(plan?.name, 'resumed');
  });

  test('publish clears storage and cancels pending save', () async {
    await storage.saveDraft(_plan('p', name: 'old'));
    await controller.onPlanChanged(_plan('p', name: 'pending'));

    await controller.publish();
    expect(await storage.hasDraft(), isFalse);

    await Future<void>.delayed(_afterDebounce);
    expect(
      await storage.hasDraft(),
      isFalse,
      reason: 'the cancelled debounce must not resurrect the draft',
    );
  });

  test('dispose flushes any pending plan immediately', () async {
    await controller.onPlanChanged(_plan('p', name: 'pending'));
    expect(await storage.hasDraft(), isFalse);

    await controller.dispose();

    final saved = await storage.readDraft();
    expect(saved, isNotNull);
    expect(saved!.name, 'pending');
  });

  test('controller honors custom slot', () async {
    final slotted = PlanDraftController(
      storage: storage,
      slot: 'editor-b',
      debounce: _debounce,
    );
    await slotted.onPlanChanged(_plan('p', name: 'slotted'));
    await Future<void>.delayed(_afterDebounce);

    expect(await storage.hasDraft(slot: 'editor-b'), isTrue);
    expect(await storage.hasDraft(), isFalse);
    expect((await storage.readDraft(slot: 'editor-b'))?.name, 'slotted');
    await slotted.dispose();
  });
}
