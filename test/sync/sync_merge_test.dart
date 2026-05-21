import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

SyncEnvelope<Map<String, dynamic>> _env({
  required String id,
  required SyncOperation op,
  required DateTime updatedAt,
  required String source,
  Map<String, dynamic>? payload,
  DateTime? deletedAt,
}) {
  return SyncEnvelope<Map<String, dynamic>>(
    id: id,
    operation: op,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    source: source,
    schemaVersion: 1,
    payload: payload,
  );
}

void main() {
  group('SyncMerge.resolve', () {
    test('lastWriteWins: newer updatedAt wins', () {
      final local = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21, 10),
        source: 'a',
        payload: {'v': 1},
      );
      final remote = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21, 12),
        source: 'b',
        payload: {'v': 2},
      );

      final winner = SyncMerge.resolve(local, remote);
      expect(winner.source, 'b');
      expect(winner.payload?['v'], 2);
    });

    test('lastWriteWins tie: delete wins over update', () {
      final ts = DateTime.utc(2026, 5, 21, 9);
      final updated = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: ts,
        source: 'a',
        payload: {'v': 1},
      );
      final deleted = _env(
        id: 'x',
        op: SyncOperation.delete,
        updatedAt: ts,
        deletedAt: ts,
        source: 'b',
      );

      expect(SyncMerge.resolve(updated, deleted).operation,
          SyncOperation.delete);
      expect(SyncMerge.resolve(deleted, updated).operation,
          SyncOperation.delete);
    });

    test('sourcePriority overrides updatedAt order', () {
      final older = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21, 8),
        source: 'primary',
        payload: {'v': 1},
      );
      final newer = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21, 20),
        source: 'secondary',
        payload: {'v': 2},
      );

      final winner = SyncMerge.resolve(
        older,
        newer,
        strategy: SyncMergeStrategy.sourcePriority,
        sourcePriority: const ['primary', 'secondary'],
      );

      expect(winner.source, 'primary');
      expect(winner.payload?['v'], 1);
    });

    test('sourcePriority falls back to lastWriteWins when sources unknown', () {
      final a = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21, 8),
        source: 'unknown-a',
      );
      final b = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21, 9),
        source: 'unknown-b',
      );

      final winner = SyncMerge.resolve(
        a,
        b,
        strategy: SyncMergeStrategy.sourcePriority,
        sourcePriority: const ['primary'],
      );

      expect(winner.source, 'unknown-b');
    });

    test('manual strategy throws StateError', () {
      final a = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21),
        source: 'a',
      );
      final b = _env(
        id: 'x',
        op: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21),
        source: 'b',
      );

      expect(
        () => SyncMerge.resolve(a, b, strategy: SyncMergeStrategy.manual),
        throwsStateError,
      );
    });
  });

  group('SyncMerge.resolveBatch', () {
    test('groups by id and resolves pair-wise with lastWriteWins', () {
      final local = [
        _env(
          id: 'a',
          op: SyncOperation.update,
          updatedAt: DateTime.utc(2026, 5, 21, 10),
          source: 'l',
          payload: {'v': 1},
        ),
        _env(
          id: 'b',
          op: SyncOperation.update,
          updatedAt: DateTime.utc(2026, 5, 21, 10),
          source: 'l',
          payload: {'v': 'local-only'},
        ),
      ];
      final remote = [
        _env(
          id: 'a',
          op: SyncOperation.update,
          updatedAt: DateTime.utc(2026, 5, 21, 11),
          source: 'r',
          payload: {'v': 2},
        ),
        _env(
          id: 'c',
          op: SyncOperation.create,
          updatedAt: DateTime.utc(2026, 5, 21, 11),
          source: 'r',
          payload: {'v': 'remote-only'},
        ),
      ];

      final result = SyncMerge.resolveBatch(local, remote);
      expect(result.conflicts, isEmpty);
      expect(result.resolved.length, 3);

      final byId = {for (final e in result.resolved) e.id: e};
      expect(byId['a']!.source, 'r');
      expect(byId['b']!.source, 'l');
      expect(byId['c']!.source, 'r');
    });

    test('manual strategy collects conflicts and passes through singletons',
        () {
      final local = [
        _env(
          id: 'a',
          op: SyncOperation.update,
          updatedAt: DateTime.utc(2026, 5, 21, 10),
          source: 'l',
        ),
        _env(
          id: 'b',
          op: SyncOperation.update,
          updatedAt: DateTime.utc(2026, 5, 21, 10),
          source: 'l',
        ),
      ];
      final remote = [
        _env(
          id: 'a',
          op: SyncOperation.update,
          updatedAt: DateTime.utc(2026, 5, 21, 12),
          source: 'r',
        ),
        _env(
          id: 'c',
          op: SyncOperation.create,
          updatedAt: DateTime.utc(2026, 5, 21, 12),
          source: 'r',
        ),
      ];

      final result = SyncMerge.resolveBatch(
        local,
        remote,
        strategy: SyncMergeStrategy.manual,
      );

      expect(result.conflicts.length, 1);
      expect(result.conflicts.first.local.id, 'a');
      expect(result.conflicts.first.remote.id, 'a');

      final resolvedIds = result.resolved.map((e) => e.id).toSet();
      expect(resolvedIds, {'b', 'c'});
    });
  });
}