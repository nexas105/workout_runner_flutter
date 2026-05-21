import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduledWorkout JSON', () {
    test('round-trip preserves all timestamps and fields', () {
      final s = ScheduledWorkout(
        id: 'evt-1',
        planId: 'plan-42',
        planName: 'Push Day',
        isCardio: false,
        scheduledAt: DateTime.utc(2026, 5, 21, 18, 30),
        startedAt: DateTime.utc(2026, 5, 21, 18, 32),
        completedAt: DateTime.utc(2026, 5, 21, 19, 15),
        skippedAt: DateTime.utc(2026, 5, 21, 19, 20),
        notes: 'felt strong',
        meta: const {'mood': 'great', 'rpe': 7},
      );

      final json = s.toJson();
      final back = ScheduledWorkout.fromJson(json);

      expect(back.id, s.id);
      expect(back.planId, s.planId);
      expect(back.planName, s.planName);
      expect(back.isCardio, s.isCardio);
      expect(back.scheduledAt, s.scheduledAt);
      expect(back.startedAt, s.startedAt);
      expect(back.completedAt, s.completedAt);
      expect(back.skippedAt, s.skippedAt);
      expect(back.notes, s.notes);
      expect(back.meta, s.meta);
    });

    test('round-trip with only required fields', () {
      final s = ScheduledWorkout(
        id: 'evt-2',
        planId: 'plan-1',
        scheduledAt: DateTime.utc(2026, 6, 1, 8, 0),
      );

      final back = ScheduledWorkout.fromJson(s.toJson());
      expect(back.id, s.id);
      expect(back.planId, s.planId);
      expect(back.scheduledAt, s.scheduledAt);
      expect(back.planName, isNull);
      expect(back.isCardio, isFalse);
      expect(back.startedAt, isNull);
      expect(back.completedAt, isNull);
      expect(back.skippedAt, isNull);
      expect(back.notes, isNull);
      expect(back.meta, isNull);
    });

    test('isCardio flag round-trips true', () {
      final s = ScheduledWorkout(
        id: 'c1',
        planId: 'cardio-1',
        isCardio: true,
        scheduledAt: DateTime.utc(2026, 5, 22, 7, 0),
      );
      expect(ScheduledWorkout.fromJson(s.toJson()).isCardio, isTrue);
    });
  });

  group('derivedStatus', () {
    test('completedAt wins over skippedAt', () {
      final now = DateTime.now();
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
        skippedAt: now.subtract(const Duration(minutes: 30)),
      );
      expect(s.derivedStatus, ScheduledStatus.completed);
    });

    test('skippedAt without completion → skipped', () {
      final now = DateTime.now();
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: now.subtract(const Duration(hours: 5)),
        skippedAt: now.subtract(const Duration(hours: 1)),
      );
      expect(s.derivedStatus, ScheduledStatus.skipped);
    });

    test('skipped beats staleness for very old entries', () {
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: DateTime.now().subtract(const Duration(days: 30)),
        skippedAt: DateTime.now().subtract(const Duration(days: 29)),
      );
      expect(s.derivedStatus, ScheduledStatus.skipped);
    });

    test('far past + no start → cancelled', () {
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(s.derivedStatus, ScheduledStatus.cancelled);
    });

    test('past by under 1 day → still upcoming', () {
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(s.derivedStatus, ScheduledStatus.upcoming);
    });

    test('future entry → upcoming', () {
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: DateTime.now().add(const Duration(days: 2)),
      );
      expect(s.derivedStatus, ScheduledStatus.upcoming);
    });

    test('started but not completed → upcoming (not stale)', () {
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: DateTime.now().subtract(const Duration(days: 5)),
        startedAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(s.derivedStatus, ScheduledStatus.upcoming);
    });
  });

  group('copyWith', () {
    test('updates target field and preserves the rest', () {
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: DateTime.utc(2026, 1, 1),
        notes: 'old',
      );
      final updated = s.copyWith(notes: 'new');
      expect(updated.notes, 'new');
      expect(updated.id, s.id);
      expect(updated.planId, s.planId);
      expect(updated.scheduledAt, s.scheduledAt);
    });

    test('can clear optional timestamps explicitly', () {
      final s = ScheduledWorkout(
        id: 'a',
        planId: 'p',
        scheduledAt: DateTime.utc(2026, 1, 1),
        completedAt: DateTime.utc(2026, 1, 2),
      );
      final cleared = s.copyWith(completedAt: null);
      expect(cleared.completedAt, isNull);
      expect(s.completedAt, isNotNull);
    });
  });

  group('ScheduledWorkoutQuery.upcoming', () {
    test('filters by horizon and sorts ascending', () {
      final now = DateTime.utc(2026, 5, 21, 12);
      final entries = <ScheduledWorkout>[
        ScheduledWorkout(
          id: 'in-3d',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 3)),
        ),
        ScheduledWorkout(
          id: 'in-1d',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 1)),
        ),
        ScheduledWorkout(
          id: 'in-20d',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 20)),
        ),
        ScheduledWorkout(
          id: 'past',
          planId: 'p',
          scheduledAt: now.subtract(const Duration(hours: 5)),
        ),
      ];

      final result = ScheduledWorkoutQuery.upcoming(entries, now: now);
      expect(result.map((e) => e.id), ['in-1d', 'in-3d']);
    });

    test('horizon parameter respected', () {
      final now = DateTime.utc(2026, 5, 21, 12);
      final entries = <ScheduledWorkout>[
        ScheduledWorkout(
          id: 'in-2d',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 2)),
        ),
        ScheduledWorkout(
          id: 'in-5d',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 5)),
        ),
      ];
      final result = ScheduledWorkoutQuery.upcoming(
        entries,
        now: now,
        horizon: const Duration(days: 3),
      );
      expect(result.map((e) => e.id), ['in-2d']);
    });

    test('skips entries that are completed/skipped even if in range', () {
      final now = DateTime.utc(2026, 5, 21, 12);
      final entries = <ScheduledWorkout>[
        ScheduledWorkout(
          id: 'done',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 1)),
          completedAt: now,
        ),
        ScheduledWorkout(
          id: 'skip',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 2)),
          skippedAt: now,
        ),
        ScheduledWorkout(
          id: 'live',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 3)),
        ),
      ];
      final result = ScheduledWorkoutQuery.upcoming(entries, now: now);
      expect(result.map((e) => e.id), ['live']);
    });

    test('exact horizon boundary is exclusive', () {
      final now = DateTime.utc(2026, 5, 21, 12);
      final entries = <ScheduledWorkout>[
        ScheduledWorkout(
          id: 'edge',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 14)),
        ),
        ScheduledWorkout(
          id: 'inside',
          planId: 'p',
          scheduledAt: now.add(const Duration(days: 13, hours: 23)),
        ),
      ];
      final result = ScheduledWorkoutQuery.upcoming(entries, now: now);
      expect(result.map((e) => e.id), ['inside']);
    });
  });

  group('ScheduledWorkoutQuery.today', () {
    test('matches local calendar date', () {
      final now = DateTime(2026, 5, 21, 14, 0);
      final entries = <ScheduledWorkout>[
        ScheduledWorkout(
          id: 'today-am',
          planId: 'p',
          scheduledAt: DateTime(2026, 5, 21, 7, 30),
        ),
        ScheduledWorkout(
          id: 'today-pm',
          planId: 'p',
          scheduledAt: DateTime(2026, 5, 21, 19, 0),
        ),
        ScheduledWorkout(
          id: 'tomorrow',
          planId: 'p',
          scheduledAt: DateTime(2026, 5, 22, 7, 30),
        ),
        ScheduledWorkout(
          id: 'yesterday',
          planId: 'p',
          scheduledAt: DateTime(2026, 5, 20, 19, 0),
        ),
      ];

      final result = ScheduledWorkoutQuery.today(entries, now: now);
      expect(result.map((e) => e.id), ['today-am', 'today-pm']);
    });

    test('empty when nothing today', () {
      final now = DateTime(2026, 5, 21, 14, 0);
      final entries = <ScheduledWorkout>[
        ScheduledWorkout(
          id: 'x',
          planId: 'p',
          scheduledAt: DateTime(2026, 5, 22, 7, 30),
        ),
      ];
      expect(ScheduledWorkoutQuery.today(entries, now: now), isEmpty);
    });
  });
}