import 'package:fitness_workout/fitness_workout.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoachingMessage JSON', () {
    test('round-trip preserves all fields including action', () {
      final original = CoachingMessage(
        id: 'msg-1',
        severity: CoachSeverity.success,
        title: 'New PR!',
        body: 'You just set a new personal record.',
        action: const CoachingAction(
          label: 'Log PR',
          actionId: 'pr.log',
          args: {'exerciseId': 'bench-press', 'weight': 102.5},
        ),
        at: DateTime.utc(2026, 5, 21, 10, 30),
        source: 'overload',
        meta: const {'streak': 3},
      );

      final json = original.toJson();
      final restored = CoachingMessage.fromJson(json);

      expect(restored, equals(original));
      expect(restored.action, equals(original.action));
      expect(restored.meta?['streak'], 3);
    });

    test('round-trip without optional fields', () {
      final original = CoachingMessage(
        id: 'msg-2',
        severity: CoachSeverity.info,
        title: 'Rest',
        body: 'Take a breath.',
        at: DateTime.utc(2026, 5, 21, 10, 31),
      );

      final restored = CoachingMessage.fromJson(original.toJson());
      expect(restored, equals(original));
      expect(restored.action, isNull);
      expect(restored.source, isNull);
      expect(restored.meta, isNull);
    });
  });

  group('DefaultCoachEngine', () {
    test('emits default message for prAchieved', () async {
      final engine = DefaultCoachEngine();
      final at = DateTime.utc(2026, 5, 21, 11, 0);
      final future = engine.messages.first;

      engine.emitSignal(CoachSignalEvent(signal: CoachSignal.prAchieved, at: at));

      final msg = await future.timeout(const Duration(seconds: 1));
      final tpl = DefaultCoachEngine.defaultTemplates[CoachSignal.prAchieved]!;

      expect(msg.severity, CoachSeverity.success);
      expect(msg.title, tpl.severity == CoachSeverity.success ? 'New PR!' : msg.title);
      expect(msg.title, 'New PR!');
      expect(msg.body, 'You just set a new personal record.');
      expect(msg.source, 'overload');
      expect(msg.at, at);

      await engine.dispose();
    });

    test('every CoachSignal has a default template', () {
      for (final s in CoachSignal.values) {
        expect(
          DefaultCoachEngine.defaultTemplates.containsKey(s),
          isTrue,
          reason: 'missing default template for $s',
        );
      }
    });

    test('custom mapper overrides defaults', () async {
      final engine = DefaultCoachEngine(
        mapper: (event) => CoachingMessage(
          id: 'custom-${event.signal.id}',
          severity: CoachSeverity.alert,
          title: 'CUSTOM',
          body: 'mapped body',
          at: event.at,
          source: 'app:userCoach',
        ),
      );
      final at = DateTime.utc(2026, 5, 21, 11, 1);
      final future = engine.messages.first;

      engine.emitSignal(CoachSignalEvent(signal: CoachSignal.prAchieved, at: at));

      final msg = await future.timeout(const Duration(seconds: 1));
      expect(msg.id, 'custom-prAchieved');
      expect(msg.severity, CoachSeverity.alert);
      expect(msg.title, 'CUSTOM');
      expect(msg.source, 'app:userCoach');

      await engine.dispose();
    });

    test('mapper returning null suppresses emission', () async {
      final engine = DefaultCoachEngine(mapper: (_) => null);
      final received = <CoachingMessage>[];
      final sub = engine.messages.listen(received.add);

      engine.emitSignal(
        CoachSignalEvent(
          signal: CoachSignal.setMissed,
          at: DateTime.utc(2026, 5, 21, 11, 2),
        ),
      );
      engine.emitSignal(
        CoachSignalEvent(
          signal: CoachSignal.prAchieved,
          at: DateTime.utc(2026, 5, 21, 11, 3),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received, isEmpty);

      await sub.cancel();
      await engine.dispose();
    });

    test('dispose closes the stream cleanly', () async {
      final engine = DefaultCoachEngine();
      final done = Completer<void>();
      engine.messages.listen(
        (_) {},
        onDone: done.complete,
      );

      await engine.dispose();
      await done.future.timeout(const Duration(seconds: 1));

      // Second dispose is a no-op.
      await engine.dispose();

      // Post-dispose emission is silently dropped.
      engine.emitSignal(
        CoachSignalEvent(
          signal: CoachSignal.hitTarget,
          at: DateTime.utc(2026, 5, 21, 11, 4),
        ),
      );
    });
  });
}