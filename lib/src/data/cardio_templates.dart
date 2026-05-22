import '../models/cardio/cardio_interval.dart';
import '../models/cardio/cardio_plan.dart';
import '../models/cardio/cardio_plan_builder.dart';

abstract class CardioTemplates {
  CardioTemplates._();

  static final CardioPlan tabataClassic = () {
    final b = CardioPlanBuilder(
      'Tabata Classic',
      id: 'cardio_tmpl_tabata_classic',
      description: '8 rounds of 20 s all-out / 10 s rest.',
      discipline: CardioDiscipline.mixed,
      meta: const {'rounds': 8, 'protocol': 'tabata'},
    ).warmup(duration: const Duration(minutes: 5));
    for (var i = 1; i <= 8; i++) {
      b
          .interval(
            name: 'All-out $i',
            id: 'work_$i',
            duration: const Duration(seconds: 20),
            intensity: 'RPE 10',
            met: 12,
          )
          .rest(name: 'Rest', duration: const Duration(seconds: 10));
    }
    return b.cooldown(duration: const Duration(minutes: 3)).build();
  }();

  static final CardioPlan hiit_30_30 = () {
    final b = CardioPlanBuilder(
      'HIIT 30/30',
      id: 'cardio_tmpl_hiit_30_30',
      description: '10 rounds of 30 s work / 30 s rest.',
      discipline: CardioDiscipline.mixed,
      meta: const {'rounds': 10, 'protocol': 'hiit'},
    ).warmup(duration: const Duration(minutes: 5));
    for (var i = 1; i <= 10; i++) {
      b
          .interval(
            name: 'Push $i',
            id: 'work_$i',
            duration: const Duration(seconds: 30),
            intensity: 'Z4',
            met: 12,
          )
          .rest(name: 'Rest', duration: const Duration(seconds: 30));
    }
    return b.cooldown(duration: const Duration(minutes: 3)).build();
  }();

  static final CardioPlan lissRun =
      CardioPlanBuilder(
            'LISS Run',
            id: 'cardio_tmpl_liss_run',
            description: '30 minutes of steady-state Zone 2 running.',
            discipline: CardioDiscipline.running,
            meta: const {'protocol': 'liss'},
          )
          .warmup(duration: const Duration(minutes: 5))
          .interval(
            name: 'Steady Z2',
            id: 'steady',
            phase: CardioPhase.steady,
            duration: const Duration(minutes: 30),
            intensity: 'Z2',
            met: 9,
          )
          .cooldown(duration: const Duration(minutes: 5))
          .build();

  static final CardioPlan pyramid = () {
    const efforts = [1, 2, 3, 4, 3, 2, 1];
    final b = CardioPlanBuilder(
      'Pyramid Intervals',
      id: 'cardio_tmpl_pyramid',
      description:
          'Work intervals climb 1-2-3-4 minutes and back down, 1 min rest.',
      discipline: CardioDiscipline.mixed,
      meta: const {'protocol': 'pyramid'},
    ).warmup(duration: const Duration(minutes: 5));
    for (var i = 0; i < efforts.length; i++) {
      final mins = efforts[i];
      b.interval(
        name: '$mins min hard',
        id: 'work_${i + 1}_${mins}m',
        duration: Duration(minutes: mins),
        intensity: 'Z4',
        met: 10,
      );
      if (i < efforts.length - 1) {
        b.rest(name: 'Recover', duration: const Duration(minutes: 1));
      }
    }
    return b.cooldown(duration: const Duration(minutes: 5)).build();
  }();

  static final CardioPlan easyBike =
      CardioPlanBuilder(
            'Easy Bike',
            id: 'cardio_tmpl_easy_bike',
            description: '45 minutes of steady Zone 2 cycling.',
            discipline: CardioDiscipline.cycling,
            meta: const {'protocol': 'liss'},
          )
          .warmup(duration: const Duration(minutes: 5))
          .interval(
            name: 'Steady Z2',
            id: 'steady',
            phase: CardioPhase.steady,
            duration: const Duration(minutes: 45),
            intensity: 'Z2',
            met: 7.5,
          )
          .cooldown(duration: const Duration(minutes: 5))
          .build();

  static final CardioPlan runWalk = () {
    final b = CardioPlanBuilder(
      'Run / Walk',
      id: 'cardio_tmpl_run_walk',
      description: 'Beginner intervals: 1 min walk / 1 min jog x 10.',
      discipline: CardioDiscipline.running,
      meta: const {'level': 'beginner', 'rounds': 10},
    ).warmup(duration: const Duration(minutes: 5));
    for (var i = 1; i <= 10; i++) {
      b
          .interval(
            name: 'Walk $i',
            id: 'walk_$i',
            phase: CardioPhase.rest,
            duration: const Duration(minutes: 1),
            intensity: 'Z1',
            met: 3.5,
          )
          .interval(
            name: 'Jog $i',
            id: 'jog_$i',
            duration: const Duration(minutes: 1),
            intensity: 'Z2',
            met: 7,
          );
    }
    return b.cooldown(duration: const Duration(minutes: 5)).build();
  }();

  static List<CardioPlan> get all => [
    tabataClassic,
    hiit_30_30,
    lissRun,
    pyramid,
    easyBike,
    runWalk,
  ];
}
