import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardioTemplates.all', () {
    test('exposes the documented plan count with non-empty intervals', () {
      final all = CardioTemplates.all;
      expect(all, hasLength(6));
      for (final plan in all) {
        expect(
          plan.intervals,
          isNotEmpty,
          reason: '${plan.id} has no intervals',
        );
      }
    });

    test('plan ids are unique and prefixed with cardio_tmpl_', () {
      final ids = CardioTemplates.all.map((p) => p.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'duplicate plan ids: $ids',
      );
      for (final id in ids) {
        expect(id, startsWith('cardio_tmpl_'));
      }
    });

    test('interval ids inside a single plan are unique', () {
      for (final plan in CardioTemplates.all) {
        final ids = plan.intervals.map((i) => i.id).toList();
        expect(
          ids.toSet().length,
          ids.length,
          reason: 'plan ${plan.id} has duplicate interval ids: $ids',
        );
      }
    });
  });

  group('tabataClassic', () {
    test('has 8 work + 8 rest intervals plus warmup and cooldown', () {
      final plan = CardioTemplates.tabataClassic;
      final work = plan.intervals.where((i) => i.phase == CardioPhase.work);
      final rest = plan.intervals.where((i) => i.phase == CardioPhase.rest);
      final warmup = plan.intervals.where((i) => i.phase == CardioPhase.warmup);
      final cooldown = plan.intervals.where(
        (i) => i.phase == CardioPhase.cooldown,
      );

      expect(work, hasLength(8));
      expect(rest, hasLength(8));
      expect(warmup, hasLength(1));
      expect(cooldown, hasLength(1));
      expect(plan.intervals, hasLength(18));
    });
  });

  group('pyramid', () {
    test('interval durations sum to the expected 32 minutes', () {
      final plan = CardioTemplates.pyramid;
      // warmup 5 + work (1+2+3+4+3+2+1)=16 + rests (6 x 1)=6 + cooldown 5
      expect(plan.plannedDuration, const Duration(minutes: 32));
    });

    test('work intervals follow the 1/2/3/4/3/2/1 pyramid pattern', () {
      final plan = CardioTemplates.pyramid;
      final workMinutes =
          plan.intervals
              .where((i) => i.phase == CardioPhase.work)
              .map((i) => i.targetDuration!.inMinutes)
              .toList();
      expect(workMinutes, [1, 2, 3, 4, 3, 2, 1]);
    });
  });
}
