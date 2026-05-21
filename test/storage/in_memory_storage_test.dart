import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryRunnerStorage storage;

  setUp(() {
    storage = InMemoryRunnerStorage();
  });

  group('InMemoryRunnerStorage', () {
    test('round-trips state in the default slot', () async {
      final state = {'planId': 'p1', 'isActive': true};

      await storage.saveState(state);
      final read = await storage.readState();

      expect(read, isNotNull);
      expect(read!['planId'], 'p1');
      expect(read['isActive'], isTrue);
    });

    test('round-trips a plan in the default slot', () async {
      final plan = {'id': 'p1', 'name': 'P', 'exercises': <dynamic>[]};

      await storage.savePlan(plan);
      final read = await storage.readPlan();

      expect(read, isNotNull);
      expect(read!['id'], 'p1');
    });

    test('keeps separate slots isolated', () async {
      await storage.saveState({'planId': 'A'}, slot: 'user_a');
      await storage.saveState({'planId': 'B'}, slot: 'user_b');
      await storage.savePlan({'id': 'plan_A'}, slot: 'user_a');
      await storage.savePlan({'id': 'plan_B'}, slot: 'user_b');

      final stateA = await storage.readState(slot: 'user_a');
      final stateB = await storage.readState(slot: 'user_b');
      final planA = await storage.readPlan(slot: 'user_a');
      final planB = await storage.readPlan(slot: 'user_b');

      expect(stateA!['planId'], 'A');
      expect(stateB!['planId'], 'B');
      expect(planA!['id'], 'plan_A');
      expect(planB!['id'], 'plan_B');
    });

    test('clearState removes only the requested slot', () async {
      await storage.saveState({'planId': 'A'}, slot: 'a');
      await storage.saveState({'planId': 'B'}, slot: 'b');

      await storage.clearState(slot: 'a');

      expect(await storage.readState(slot: 'a'), isNull);
      expect((await storage.readState(slot: 'b'))!['planId'], 'B');
    });

    test('clearPlan removes only the requested slot', () async {
      await storage.savePlan({'id': 'A'}, slot: 'a');
      await storage.savePlan({'id': 'B'}, slot: 'b');

      await storage.clearPlan(slot: 'a');

      expect(await storage.readPlan(slot: 'a'), isNull);
      expect((await storage.readPlan(slot: 'b'))!['id'], 'B');
    });

    test('reading a missing slot returns null', () async {
      expect(await storage.readState(slot: 'nope'), isNull);
      expect(await storage.readPlan(slot: 'nope'), isNull);
    });

    test('saving copies the map (mutating the original is safe)', () async {
      final original = <String, dynamic>{'planId': 'A'};
      await storage.saveState(original);

      original['planId'] = 'TAMPERED';

      final read = await storage.readState();
      expect(read!['planId'], 'A');
    });
  });
}
