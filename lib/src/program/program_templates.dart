import '../data/cardio_templates.dart';
import '../data/strength_templates.dart';
import 'training_program.dart';

abstract class ProgramTemplates {
  static TrainingProgram beginnerStrength5x5() {
    const programId = 'prog_5x5';
    final fiveByFiveId = StrengthTemplates.fiveByFive.id;
    final weeks = <ProgramWeek>[];
    for (var w = 1; w <= 12; w++) {
      final days = <ProgramDay>[
        ProgramDay(
          id: '${programId}_w${w}d1',
          label: 'Day 1 – Workout A (5x5)',
          kind: ProgramDayKind.strength,
          planId: fiveByFiveId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d2',
          label: 'Day 2 – Rest',
          kind: ProgramDayKind.rest,
        ),
        ProgramDay(
          id: '${programId}_w${w}d3',
          label: 'Day 3 – Workout B (5x5)',
          kind: ProgramDayKind.strength,
          planId: fiveByFiveId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d4',
          label: 'Day 4 – Rest',
          kind: ProgramDayKind.rest,
        ),
        ProgramDay(
          id: '${programId}_w${w}d5',
          label: 'Day 5 – Workout A (5x5)',
          kind: ProgramDayKind.strength,
          planId: fiveByFiveId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d6',
          label: 'Day 6 – Mobility',
          kind: ProgramDayKind.mobility,
        ),
        ProgramDay(
          id: '${programId}_w${w}d7',
          label: 'Day 7 – Rest',
          kind: ProgramDayKind.rest,
        ),
      ];
      weeks.add(ProgramWeek(index: w, days: days));
    }
    return TrainingProgram(
      id: programId,
      name: 'Beginner Strength 5x5 (12 weeks)',
      description:
          'Classic linear-progression 5x5 squat/bench/row, three lifting days per week.',
      weeks: weeks,
    );
  }

  static TrainingProgram pushPullLegs4Week() {
    const programId = 'prog_ppl_4w';
    final pushId = StrengthTemplates.pushDay.id;
    final pullId = StrengthTemplates.pullDay.id;
    final legId = StrengthTemplates.legDay.id;
    final weeks = <ProgramWeek>[];
    for (var w = 1; w <= 4; w++) {
      final days = <ProgramDay>[
        ProgramDay(
          id: '${programId}_w${w}d1',
          label: 'Day 1 – Push',
          kind: ProgramDayKind.strength,
          planId: pushId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d2',
          label: 'Day 2 – Pull',
          kind: ProgramDayKind.strength,
          planId: pullId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d3',
          label: 'Day 3 – Legs',
          kind: ProgramDayKind.strength,
          planId: legId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d4',
          label: 'Day 4 – Rest',
          kind: ProgramDayKind.rest,
        ),
        ProgramDay(
          id: '${programId}_w${w}d5',
          label: 'Day 5 – Push',
          kind: ProgramDayKind.strength,
          planId: pushId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d6',
          label: 'Day 6 – Pull',
          kind: ProgramDayKind.strength,
          planId: pullId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d7',
          label: 'Day 7 – Legs',
          kind: ProgramDayKind.strength,
          planId: legId,
        ),
      ];
      weeks.add(ProgramWeek(index: w, days: days));
    }
    return TrainingProgram(
      id: programId,
      name: 'Push / Pull / Legs (4 weeks)',
      description: 'Six lifting days per week split across push, pull, legs.',
      weeks: weeks,
    );
  }

  static TrainingProgram run10kBase() {
    const programId = 'prog_run_10k_base';
    final runId = CardioTemplates.lissRun.id;
    final fiveByFiveId = StrengthTemplates.fiveByFive.id;
    final weeks = <ProgramWeek>[];
    for (var w = 1; w <= 8; w++) {
      final days = <ProgramDay>[
        ProgramDay(
          id: '${programId}_w${w}d1',
          label: 'Day 1 – Easy Run',
          kind: ProgramDayKind.cardio,
          planId: runId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d2',
          label: 'Day 2 – Strength',
          kind: ProgramDayKind.strength,
          planId: fiveByFiveId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d3',
          label: 'Day 3 – Tempo Run',
          kind: ProgramDayKind.cardio,
          planId: runId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d4',
          label: 'Day 4 – Rest',
          kind: ProgramDayKind.rest,
        ),
        ProgramDay(
          id: '${programId}_w${w}d5',
          label: 'Day 5 – Strength',
          kind: ProgramDayKind.strength,
          planId: fiveByFiveId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d6',
          label: 'Day 6 – Long Run',
          kind: ProgramDayKind.cardio,
          planId: runId,
        ),
        ProgramDay(
          id: '${programId}_w${w}d7',
          label: 'Day 7 – Mobility',
          kind: ProgramDayKind.mobility,
        ),
      ];
      weeks.add(ProgramWeek(index: w, days: days));
    }
    return TrainingProgram(
      id: programId,
      name: '5K to 10K Base (8 weeks)',
      description:
          'Mixed program: three LISS runs and two strength sessions per week.',
      weeks: weeks,
    );
  }

  static List<TrainingProgram> get all => [
    beginnerStrength5x5(),
    pushPullLegs4Week(),
    run10kBase(),
  ];
}
