import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan _plan(String id, {String? name}) =>
    WorkoutPlan(id: id, name: name ?? 'Plan $id', exercises: const []);

void main() {
  late InMemoryPlanDraftStorage storage;

  setUp(() {
    storage = InMemoryPlanDraftStorage();
  });

  test('round-trips a plan via default slot', () async {
    final plan = _plan('p1', name: 'Leg Day');

    await storage.saveDraft(plan);
    final read = await storage.readDraft();

    expect(read, isNotNull);
    expect(read!.id, 'p1');
    expect(read.name, 'Leg Day');
  });

  test('hasDraft reflects save / discard', () async {
    expect(await storage.hasDraft(), isFalse);

    await storage.saveDraft(_plan('p1'));
    expect(await storage.hasDraft(), isTrue);

    await storage.discardDraft();
    expect(await storage.hasDraft(), isFalse);
    expect(await storage.readDraft(), isNull);
  });

  test('multiple slots stay isolated', () async {
    await storage.saveDraft(_plan('a', name: 'Push'), slot: 'push');
    await storage.saveDraft(_plan('b', name: 'Pull'), slot: 'pull');

    final push = await storage.readDraft(slot: 'push');
    final pull = await storage.readDraft(slot: 'pull');

    expect(push?.name, 'Push');
    expect(pull?.name, 'Pull');

    await storage.discardDraft(slot: 'push');
    expect(await storage.hasDraft(slot: 'push'), isFalse);
    expect(await storage.hasDraft(slot: 'pull'), isTrue);
  });

  test('listSlots enumerates every slot with a saved draft', () async {
    expect(await storage.listSlots(), isEmpty);

    await storage.saveDraft(_plan('a'), slot: 'one');
    await storage.saveDraft(_plan('b'), slot: 'two');
    await storage.saveDraft(_plan('c'));

    final slots = await storage.listSlots();
    expect(slots.toSet(), {'one', 'two', 'default'});

    await storage.discardDraft(slot: 'one');
    expect((await storage.listSlots()).toSet(), {'two', 'default'});
  });

  test('saveDraft overwrites the slot in place', () async {
    await storage.saveDraft(_plan('p1', name: 'v1'));
    await storage.saveDraft(_plan('p1', name: 'v2'));

    final read = await storage.readDraft();
    expect(read?.name, 'v2');
    expect((await storage.listSlots()).length, 1);
  });
}