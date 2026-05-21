import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

class _DefaultGate extends ConsentGate {
  const _DefaultGate();
}

void main() {
  group('ConsentState', () {
    test('defaults all scopes to false', () {
      const state = ConsentState();
      for (final scope in ConsentScope.values) {
        expect(state.isGranted(scope), isFalse);
      }
      expect(state.lastUpdated, isNull);
    });

    test('grant returns a new state without mutating the original', () {
      const original = ConsentState();
      final at = DateTime.utc(2026, 5, 21, 12);
      final next = original.grant(ConsentScope.healthExport, at: at);

      expect(identical(original, next), isFalse);
      expect(original.isGranted(ConsentScope.healthExport), isFalse);
      expect(next.isGranted(ConsentScope.healthExport), isTrue);
      expect(next.lastUpdated, at);
    });

    test('revoke flips a previously granted scope', () {
      final granted = const ConsentState().grant(ConsentScope.backendSync);
      final revoked = granted.revoke(ConsentScope.backendSync);

      expect(granted.isGranted(ConsentScope.backendSync), isTrue);
      expect(revoked.isGranted(ConsentScope.backendSync), isFalse);
    });

    test('granted map is unmodifiable after grant', () {
      final state = const ConsentState().grant(ConsentScope.analytics);
      expect(
        () => state.granted[ConsentScope.crashReports] = true,
        throwsUnsupportedError,
      );
    });

    test('toJson / fromJson round trips', () {
      final at = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final state = const ConsentState()
          .grant(ConsentScope.healthExport, at: at)
          .grant(ConsentScope.analytics, at: at)
          .revoke(ConsentScope.crashReports, at: at);

      final restored = ConsentState.fromJson(state.toJson());

      expect(
        restored.isGranted(ConsentScope.healthExport),
        state.isGranted(ConsentScope.healthExport),
      );
      expect(
        restored.isGranted(ConsentScope.analytics),
        state.isGranted(ConsentScope.analytics),
      );
      expect(
        restored.isGranted(ConsentScope.crashReports),
        state.isGranted(ConsentScope.crashReports),
      );
      expect(
        restored.isGranted(ConsentScope.backendSync),
        state.isGranted(ConsentScope.backendSync),
      );
      expect(restored.lastUpdated, state.lastUpdated);
    });

    test('fromJson tolerates unknown scope names and bad shapes', () {
      final state = ConsentState.fromJson({
        'granted': {
          'healthExport': true,
          'unknownScope': true,
          'analytics': 'nope',
        },
        'lastUpdated': 'not-a-date',
      });
      expect(state.isGranted(ConsentScope.healthExport), isTrue);
      expect(state.isGranted(ConsentScope.analytics), isFalse);
      expect(state.lastUpdated, isNull);
    });
  });

  group('ConsentGate default', () {
    test('echoes current state without prompting', () async {
      const gate = _DefaultGate();
      const empty = ConsentState();
      final granted = empty.grant(ConsentScope.healthExport);

      expect(await gate.requireConsent(ConsentScope.healthExport, empty),
          isFalse);
      expect(
        await gate.requireConsent(ConsentScope.healthExport, granted),
        isTrue,
      );
      expect(
        await gate.requireConsent(ConsentScope.backendSync, granted),
        isFalse,
      );
    });
  });
}