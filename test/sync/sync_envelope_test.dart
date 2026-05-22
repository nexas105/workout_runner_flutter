import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

class _Payload {
  const _Payload(this.name, this.reps);
  final String name;
  final int reps;

  Map<String, dynamic> toJson() => {'name': name, 'reps': reps};

  static _Payload fromJson(Map<String, dynamic> json) =>
      _Payload(json['name'] as String, (json['reps'] as num).toInt());
}

void main() {
  group('SyncEnvelope', () {
    test('round-trips a custom payload through toJson/fromJson', () {
      final envelope = SyncEnvelope<_Payload>(
        id: 'plan-1',
        operation: SyncOperation.update,
        updatedAt: DateTime.utc(2026, 5, 21, 10, 30),
        source: 'device-a',
        schemaVersion: 3,
        payload: const _Payload('squat', 5),
      );

      final json = envelope.toJson((p) => p.toJson());
      final restored = SyncEnvelope.fromJson<_Payload>(json, _Payload.fromJson);

      expect(restored.id, 'plan-1');
      expect(restored.operation, SyncOperation.update);
      expect(restored.updatedAt, DateTime.utc(2026, 5, 21, 10, 30));
      expect(restored.source, 'device-a');
      expect(restored.schemaVersion, 3);
      expect(restored.deletedAt, isNull);
      expect(restored.payload?.name, 'squat');
      expect(restored.payload?.reps, 5);
    });

    test('round-trips a delete envelope without payload', () {
      final envelope = SyncEnvelope<_Payload>(
        id: 'plan-2',
        operation: SyncOperation.delete,
        updatedAt: DateTime.utc(2026, 5, 21, 12),
        deletedAt: DateTime.utc(2026, 5, 21, 12),
        source: 'device-b',
        schemaVersion: 3,
      );

      final json = envelope.toJson((p) => p.toJson());
      expect(json.containsKey('payload'), isFalse);

      final restored = SyncEnvelope.fromJson<_Payload>(json, _Payload.fromJson);

      expect(restored.operation, SyncOperation.delete);
      expect(restored.deletedAt, DateTime.utc(2026, 5, 21, 12));
      expect(restored.payload, isNull);
    });
  });
}
