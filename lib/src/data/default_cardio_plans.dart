import '../models/cardio/cardio_interval.dart';
import '../models/cardio/cardio_plan.dart';
import 'default_categories.dart';

/// Built-in [CardioPlan] presets. Use these straight from the package or copy
/// them as a template for app-specific plans.
class DefaultCardioPlans {
  DefaultCardioPlans._();

  static CardioInterval _warmup({
    Duration duration = const Duration(minutes: 5),
    String name = 'Warm-up',
    String? notes,
  }) => CardioInterval(
    id: 'iv_warmup_${duration.inSeconds}',
    name: name,
    phase: CardioPhase.warmup,
    targetDuration: duration,
    intensity: 'Z1',
    notes: notes,
  );

  static CardioInterval _cooldown({
    Duration duration = const Duration(minutes: 5),
    String name = 'Cool-down',
  }) => CardioInterval(
    id: 'iv_cooldown_${duration.inSeconds}',
    name: name,
    phase: CardioPhase.cooldown,
    targetDuration: duration,
    intensity: 'Z1',
  );

  static CardioInterval _work({
    required String id,
    required String name,
    Duration? duration,
    double? distanceMeters,
    String intensity = 'Z3',
    Duration? pace,
    String? notes,
  }) => CardioInterval(
    id: id,
    name: name,
    phase: CardioPhase.work,
    targetDuration: duration,
    targetDistanceMeters: distanceMeters,
    intensity: intensity,
    targetPacePerKm: pace,
    notes: notes,
  );

  static CardioInterval _rest({
    required String id,
    Duration duration = const Duration(seconds: 60),
    String name = 'Easy',
    String intensity = 'Z1',
  }) => CardioInterval(
    id: id,
    name: name,
    phase: CardioPhase.rest,
    targetDuration: duration,
    intensity: intensity,
  );

  /// Steady continuous 5-kilometre run.
  static final CardioPlan easy5k = CardioPlan(
    id: 'plan_easy_5k',
    name: 'Easy 5K',
    description: 'Continuous easy-pace run over 5 km.',
    discipline: CardioDiscipline.running,
    category: DefaultCategories.cardio,
    intervals: [
      _warmup(),
      _work(
        id: 'iv_easy_5k_main',
        name: 'Easy 5 km',
        distanceMeters: 5000,
        intensity: 'Z2',
        pace: const Duration(minutes: 5, seconds: 30),
      ),
      _cooldown(),
    ],
    meta: const {'level': 'beginner'},
  );

  /// Classic Tabata — 8 × (20 s work / 10 s rest).
  static final CardioPlan tabata = CardioPlan(
    id: 'plan_tabata',
    name: 'Tabata',
    description: '8 rounds of 20 s all-out, 10 s rest. Pick any modality.',
    discipline: CardioDiscipline.mixed,
    category: DefaultCategories.hiit,
    intervals: [
      _warmup(duration: const Duration(minutes: 3)),
      for (var i = 1; i <= 8; i++) ...[
        _work(
          id: 'iv_tabata_work_$i',
          name: 'All-out $i',
          duration: const Duration(seconds: 20),
          intensity: 'RPE 10',
        ),
        if (i < 8)
          _rest(
            id: 'iv_tabata_rest_$i',
            duration: const Duration(seconds: 10),
            intensity: 'RPE 1',
          ),
      ],
      _cooldown(duration: const Duration(minutes: 3)),
    ],
    meta: const {'rounds': 8},
  );

  /// Beginner walk-run intervals — 30 minutes total.
  static final CardioPlan walkRun = CardioPlan(
    id: 'plan_walk_run',
    name: 'Walk / Run intervals',
    description: '6 × (3 min easy run, 2 min walk).',
    discipline: CardioDiscipline.running,
    category: DefaultCategories.cardio,
    intervals: [
      _warmup(name: 'Brisk walk', duration: const Duration(minutes: 5)),
      for (var i = 1; i <= 6; i++) ...[
        _work(
          id: 'iv_wr_run_$i',
          name: 'Run $i',
          duration: const Duration(minutes: 3),
          intensity: 'Z2',
        ),
        _rest(
          id: 'iv_wr_walk_$i',
          duration: const Duration(minutes: 2),
          name: 'Walk',
        ),
      ],
      _cooldown(duration: const Duration(minutes: 3)),
    ],
    meta: const {'level': 'beginner'},
  );

  /// Indoor rowing — 4 × 500 m hard with 1 min rest.
  static final CardioPlan row500s = CardioPlan(
    id: 'plan_row_500s',
    name: 'Rower — 4 × 500 m',
    description: 'Four hard 500 m rowing intervals.',
    discipline: CardioDiscipline.rowing,
    category: DefaultCategories.cardio,
    intervals: [
      _warmup(duration: const Duration(minutes: 5)),
      for (var i = 1; i <= 4; i++) ...[
        _work(
          id: 'iv_row_hard_$i',
          name: '500 m hard $i',
          distanceMeters: 500,
          intensity: 'Z4',
        ),
        if (i < 4)
          _rest(
            id: 'iv_row_rest_$i',
            duration: const Duration(minutes: 1),
            name: 'Paddle',
          ),
      ],
      _cooldown(duration: const Duration(minutes: 5)),
    ],
  );

  /// Spin-bike pyramid — 60 / 90 / 120 / 90 / 60 s hard with 60 s recovery.
  static final CardioPlan bikePyramid = CardioPlan(
    id: 'plan_bike_pyramid',
    name: 'Bike pyramid',
    description: 'Hard pyramid intervals with equal-time recovery.',
    discipline: CardioDiscipline.cycling,
    category: DefaultCategories.cardio,
    intervals: () {
      final efforts = [60, 90, 120, 90, 60];
      return [
        _warmup(duration: const Duration(minutes: 5)),
        for (var i = 0; i < efforts.length; i++) ...[
          _work(
            id: 'iv_bike_work_$i',
            name: '${efforts[i]} s hard',
            duration: Duration(seconds: efforts[i]),
            intensity: 'Z4',
          ),
          if (i < efforts.length - 1)
            _rest(id: 'iv_bike_rest_$i', duration: const Duration(minutes: 1)),
        ],
        _cooldown(duration: const Duration(minutes: 5)),
      ];
    }(),
  );

  /// Jump-rope EMOM — every-minute-on-the-minute jumps for 10 minutes.
  static final CardioPlan jumpRopeEmom = CardioPlan(
    id: 'plan_jump_rope_emom',
    name: 'Jump rope EMOM',
    description: '10 rounds: 40 s jump rope, 20 s rest.',
    discipline: CardioDiscipline.jumpRope,
    category: DefaultCategories.hiit,
    intervals: [
      _warmup(duration: const Duration(minutes: 2)),
      for (var i = 1; i <= 10; i++) ...[
        _work(
          id: 'iv_jr_work_$i',
          name: 'Jump $i',
          duration: const Duration(seconds: 40),
          intensity: 'Z4',
        ),
        _rest(id: 'iv_jr_rest_$i', duration: const Duration(seconds: 20)),
      ],
      _cooldown(duration: const Duration(minutes: 2)),
    ],
  );

  static final List<CardioPlan> all = [
    easy5k,
    tabata,
    walkRun,
    row500s,
    bikePyramid,
    jumpRopeEmom,
  ];

  static CardioPlan? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<CardioPlan> byDiscipline(CardioDiscipline d) =>
      all.where((p) => p.discipline == d).toList();
}
