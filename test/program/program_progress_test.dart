import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutResult _workout(String planId, DateTime finishedAt) => WorkoutResult(
  planId: planId,
  startedAt: finishedAt.subtract(const Duration(hours: 1)),
  finishedAt: finishedAt,
  duration: const Duration(hours: 1),
  exercises: const [],
);

CardioResult _cardio(String planId, DateTime finishedAt) => CardioResult(
  planId: planId,
  planName: 'test',
  discipline: CardioDiscipline.running,
  startedAt: finishedAt.subtract(const Duration(minutes: 30)),
  finishedAt: finishedAt,
  duration: const Duration(minutes: 30),
  laps: const [],
);

TrainingProgram _twoDayProgram() => const TrainingProgram(
  id: 'prog_t',
  name: 't',
  weeks: [
    ProgramWeek(
      index: 1,
      days: [
        ProgramDay(
          id: 'prog_t_w1d1',
          label: 'Day 1 – Strength',
          kind: ProgramDayKind.strength,
          planId: 'plan_s',
        ),
        ProgramDay(
          id: 'prog_t_w1d2',
          label: 'Day 2 – Cardio',
          kind: ProgramDayKind.cardio,
          planId: 'plan_c',
        ),
      ],
    ),
    ProgramWeek(
      index: 2,
      days: [
        ProgramDay(
          id: 'prog_t_w2d1',
          label: 'Day 1 – Strength',
          kind: ProgramDayKind.strength,
          planId: 'plan_s',
        ),
      ],
    ),
  ],
);

void main() {
  group('ProgramProgress JSON', () {
    test('round-trips all fields', () {
      const p = ProgramProgress(
        programId: 'prog_t',
        currentWeekIndex: 2,
        currentDayIndex: 1,
        completedDayIds: {'prog_t_w1d1', 'prog_t_w1d2'},
        skippedDayIds: {'prog_t_w2d1'},
        allDayIds: {'prog_t_w1d1', 'prog_t_w1d2', 'prog_t_w2d1'},
      );
      final restored = ProgramProgress.fromJson(p.toJson());
      expect(restored.programId, p.programId);
      expect(restored.currentWeekIndex, 2);
      expect(restored.currentDayIndex, 1);
      expect(restored.completedDayIds, p.completedDayIds);
      expect(restored.skippedDayIds, p.skippedDayIds);
      expect(restored.allDayIds, p.allDayIds);
    });
  });

  group('ProgramProgressTracker.compute', () {
    test('marks first strength day completed when matching result exists', () {
      final program = _twoDayProgram();
      final start = DateTime.utc(2026, 1, 1);
      final progress = ProgramProgressTracker.compute(
        program,
        [_workout('plan_s', start.add(const Duration(days: 1)))],
        const [],
        startedAt: start,
      );
      expect(progress.completedDayIds, contains('prog_t_w1d1'));
      expect(progress.completedDayIds.contains('prog_t_w1d2'), isFalse);
      expect(progress.currentWeekIndex, 1);
      expect(progress.currentDayIndex, 1);
    });

    test('cardio results mark cardio days completed', () {
      final program = _twoDayProgram();
      final start = DateTime.utc(2026, 1, 1);
      final progress = ProgramProgressTracker.compute(program, const [], [
        _cardio('plan_c', start.add(const Duration(days: 2))),
      ], startedAt: start);
      expect(progress.completedDayIds, {'prog_t_w1d2'});
      expect(progress.currentWeekIndex, 1);
      expect(progress.currentDayIndex, 0);
    });

    test('results before program start are ignored', () {
      final program = _twoDayProgram();
      final start = DateTime.utc(2026, 1, 10);
      final progress = ProgramProgressTracker.compute(
        program,
        [_workout('plan_s', DateTime.utc(2026, 1, 1))],
        const [],
        startedAt: start,
      );
      expect(progress.completedDayIds, isEmpty);
      expect(progress.currentWeekIndex, 1);
      expect(progress.currentDayIndex, 0);
    });

    test('each result consumes exactly one matching day', () {
      final program = _twoDayProgram();
      final start = DateTime.utc(2026, 1, 1);
      final progress = ProgramProgressTracker.compute(
        program,
        [
          _workout('plan_s', start.add(const Duration(days: 1))),
          _workout('plan_s', start.add(const Duration(days: 8))),
        ],
        const [],
        startedAt: start,
      );
      expect(
        progress.completedDayIds,
        containsAll(<String>['prog_t_w1d1', 'prog_t_w2d1']),
      );
    });

    test('isCompleted true when all days completed or skipped', () {
      final program = _twoDayProgram();
      final start = DateTime.utc(2026, 1, 1);
      final progress = ProgramProgressTracker.compute(
        program,
        [
          _workout('plan_s', start.add(const Duration(days: 1))),
          _workout('plan_s', start.add(const Duration(days: 8))),
        ],
        [_cardio('plan_c', start.add(const Duration(days: 2)))],
        startedAt: start,
      );
      expect(progress.isCompleted, isTrue);
    });

    test('isCompleted false when at least one day still pending', () {
      final program = _twoDayProgram();
      final progress = ProgramProgressTracker.compute(
        program,
        const [],
        const [],
      );
      expect(progress.isCompleted, isFalse);
    });

    test(
      'compute against beginnerStrength5x5 template yields valid result',
      () {
        final program = ProgramTemplates.beginnerStrength5x5();
        final progress = ProgramProgressTracker.compute(
          program,
          const [],
          const [],
        );
        expect(progress.programId, program.id);
        expect(progress.currentWeekIndex, 1);
        expect(progress.currentDayIndex, 0);
        expect(progress.allDayIds.length, program.totalDays);
      },
    );
  });
}
