import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingProgram', () {
    TrainingProgram makeProgram() => const TrainingProgram(
      id: 'prog_test',
      name: 'Test Program',
      description: 'Demo',
      weeks: [
        ProgramWeek(
          index: 1,
          days: [
            ProgramDay(
              id: 'prog_test_w1d1',
              label: 'Day 1 – Push',
              kind: ProgramDayKind.strength,
              planId: 'tmpl_push_day',
              notes: 'go hard',
            ),
            ProgramDay(
              id: 'prog_test_w1d2',
              label: 'Day 2 – Rest',
              kind: ProgramDayKind.rest,
            ),
            ProgramDay(
              id: 'prog_test_w1d3',
              label: 'Day 3 – Easy Run',
              kind: ProgramDayKind.cardio,
              planId: 'cardio_tmpl_liss_run',
            ),
          ],
          notes: 'intro week',
        ),
        ProgramWeek(
          index: 2,
          days: [
            ProgramDay(
              id: 'prog_test_w2d1',
              label: 'Day 1 – Pull',
              kind: ProgramDayKind.strength,
              planId: 'tmpl_pull_day',
            ),
            ProgramDay(
              id: 'prog_test_w2d2',
              label: 'Day 2 – Mobility',
              kind: ProgramDayKind.mobility,
            ),
          ],
        ),
      ],
    );

    test('totalDays counts every day across all weeks', () {
      final p = makeProgram();
      expect(p.totalDays, 5);
      expect(p.totalStrengthDays, 2);
      expect(p.totalCardioDays, 1);
    });

    test('dayAt returns the expected day', () {
      final p = makeProgram();
      expect(p.dayAt(1, 0)?.id, 'prog_test_w1d1');
      expect(p.dayAt(1, 2)?.kind, ProgramDayKind.cardio);
      expect(p.dayAt(2, 1)?.kind, ProgramDayKind.mobility);
    });

    test('dayAt returns null for out-of-range coordinates', () {
      final p = makeProgram();
      expect(p.dayAt(99, 0), isNull);
      expect(p.dayAt(1, -1), isNull);
      expect(p.dayAt(1, 99), isNull);
      expect(p.dayAt(2, 5), isNull);
    });

    test('JSON round-trip preserves week/day structure', () {
      final original = makeProgram();
      final json = original.toJson();
      final restored = TrainingProgram.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.weeks.length, original.weeks.length);

      for (var i = 0; i < restored.weeks.length; i++) {
        final ow = original.weeks[i];
        final rw = restored.weeks[i];
        expect(rw.index, ow.index);
        expect(rw.notes, ow.notes);
        expect(rw.days.length, ow.days.length);
        for (var j = 0; j < rw.days.length; j++) {
          final od = ow.days[j];
          final rd = rw.days[j];
          expect(rd.id, od.id);
          expect(rd.label, od.label);
          expect(rd.kind, od.kind);
          expect(rd.planId, od.planId);
          expect(rd.notes, od.notes);
        }
      }
    });

    test('copyWith updates only the requested fields', () {
      final p = makeProgram();
      final updated = p.copyWith(name: 'Renamed');
      expect(updated.name, 'Renamed');
      expect(updated.id, p.id);
      expect(updated.weeks, p.weeks);
    });

    test('ProgramDay json omits unset optionals', () {
      const d = ProgramDay(id: 'd1', label: 'Day 1', kind: ProgramDayKind.rest);
      final j = d.toJson();
      expect(j.containsKey('planId'), isFalse);
      expect(j.containsKey('notes'), isFalse);
      expect(j.containsKey('meta'), isFalse);
      expect(j['kind'], 'rest');
    });
  });

  group('ProgramTemplates', () {
    test('beginnerStrength5x5 has 12 weeks', () {
      final p = ProgramTemplates.beginnerStrength5x5();
      expect(p.weeks.length, 12);
      expect(p.weeks.first.index, 1);
      expect(p.weeks.last.index, 12);
    });

    test('beginnerStrength5x5 day ids follow prog_5x5_wXdY format', () {
      final p = ProgramTemplates.beginnerStrength5x5();
      expect(p.weeks.first.days.first.id, 'prog_5x5_w1d1');
      expect(p.weeks.last.days.last.id, 'prog_5x5_w12d7');
    });

    test('pushPullLegs4Week has 4 weeks and 7 days each', () {
      final p = ProgramTemplates.pushPullLegs4Week();
      expect(p.weeks.length, 4);
      for (final w in p.weeks) {
        expect(w.days.length, 7);
      }
    });

    test('run10kBase mixes strength and cardio days', () {
      final p = ProgramTemplates.run10kBase();
      expect(p.weeks.length, 8);
      expect(p.totalCardioDays, greaterThan(0));
      expect(p.totalStrengthDays, greaterThan(0));
    });

    test('all returns every template', () {
      final list = ProgramTemplates.all;
      expect(list.length, 3);
      expect(list.map((p) => p.id).toSet(), {
        'prog_5x5',
        'prog_ppl_4w',
        'prog_run_10k_base',
      });
    });

    test('templates round-trip through JSON', () {
      for (final p in ProgramTemplates.all) {
        final restored = TrainingProgram.fromJson(p.toJson());
        expect(restored.id, p.id);
        expect(restored.totalDays, p.totalDays);
      }
    });
  });
}
