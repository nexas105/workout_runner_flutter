import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

ExportAuditEntry _entry(String id, DateTime at, {String kind = 'workoutResult'}) {
  return ExportAuditEntry(
    id: id,
    kind: kind,
    target: 'clipboard',
    itemCount: 1,
    at: at,
  );
}

void main() {
  group('ExportAuditEntry', () {
    test('toJson / fromJson round trips', () {
      final at = DateTime.utc(2026, 5, 21, 9, 30);
      final entry = ExportAuditEntry(
        id: 'export-1',
        kind: 'bundle',
        target: 'healthkit',
        itemCount: 42,
        at: at,
        meta: const {'reason': 'manual'},
      );

      final restored = ExportAuditEntry.fromJson(entry.toJson());

      expect(restored.id, entry.id);
      expect(restored.kind, entry.kind);
      expect(restored.target, entry.target);
      expect(restored.itemCount, entry.itemCount);
      expect(restored.at, entry.at);
      expect(restored.meta, entry.meta);
    });

    test('toJson omits null target and meta', () {
      final entry = ExportAuditEntry(
        id: 'x',
        kind: 'plan',
        itemCount: 0,
        at: DateTime.utc(2026, 1, 1),
      );
      final json = entry.toJson();
      expect(json.containsKey('target'), isFalse);
      expect(json.containsKey('meta'), isFalse);
    });
  });

  group('InMemoryExportAuditSink', () {
    test('record + recent returns newest first', () async {
      final sink = InMemoryExportAuditSink();
      final older = _entry('a', DateTime.utc(2026, 5, 20, 10));
      final newest = _entry('b', DateTime.utc(2026, 5, 21, 10));
      final middle = _entry('c', DateTime.utc(2026, 5, 20, 18));

      await sink.record(older);
      await sink.record(newest);
      await sink.record(middle);

      final recent = await sink.recent();
      expect(recent.map((e) => e.id).toList(), ['b', 'c', 'a']);
    });

    test('recent honors limit', () async {
      final sink = InMemoryExportAuditSink();
      for (var i = 0; i < 5; i++) {
        await sink.record(
          _entry('e$i', DateTime.utc(2026, 5, 21, i + 1)),
        );
      }
      final recent = await sink.recent(limit: 2);
      expect(recent.length, 2);
      expect(recent.first.id, 'e4');
      expect(recent.last.id, 'e3');
    });

    test('recent honors since', () async {
      final sink = InMemoryExportAuditSink();
      await sink.record(_entry('old', DateTime.utc(2026, 5, 1)));
      await sink.record(_entry('new', DateTime.utc(2026, 5, 20)));

      final recent = await sink.recent(since: DateTime.utc(2026, 5, 10));
      expect(recent.map((e) => e.id).toList(), ['new']);
    });

    test('recent result is unmodifiable', () async {
      final sink = InMemoryExportAuditSink();
      await sink.record(_entry('a', DateTime.utc(2026, 5, 21)));
      final recent = await sink.recent();
      expect(
        () => recent.add(_entry('b', DateTime.utc(2026, 5, 22))),
        throwsUnsupportedError,
      );
    });
  });
}