import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helpers ----------------------------------------------------------------

  PerformedSet mkSet({
    required int setIndex,
    required int reps,
    double? weight,
    required DateTime at,
    int exerciseIndex = 0,
  }) => PerformedSet(
    exerciseIndex: exerciseIndex,
    setIndex: setIndex,
    actualReps: reps,
    actualWeight: weight,
    completedAt: at,
  );

  WorkoutResult mkResult({
    required String planId,
    required DateTime finishedAt,
    Duration sessionLength = const Duration(minutes: 45),
    required List<PerformedExerciseDetails> exercises,
  }) => WorkoutResult(
    planId: planId,
    startedAt: finishedAt.subtract(sessionLength),
    finishedAt: finishedAt,
    duration: sessionLength,
    exercises: exercises,
  );

  CardioResult mkCardio({
    required String planId,
    required DateTime finishedAt,
    Duration sessionLength = const Duration(minutes: 30),
    required List<CardioLap> laps,
  }) => CardioResult(
    planId: planId,
    planName: planId,
    discipline: CardioDiscipline.running,
    startedAt: finishedAt.subtract(sessionLength),
    finishedAt: finishedAt,
    duration: sessionLength,
    laps: laps,
  );

  // -- Strength PRs --------------------------------------------------------

  group('PersonalRecords.forExercise', () {
    test('maxWeight tracks the heaviest set across history', () {
      final day1 = DateTime.utc(2026, 1, 1, 10);
      final day2 = DateTime.utc(2026, 1, 8, 10);
      final day3 = DateTime.utc(2026, 1, 15, 10);

      final history = [
        mkResult(
          planId: 'p1',
          finishedAt: day1,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              sets: [
                mkSet(setIndex: 0, reps: 5, weight: 80, at: day1),
                mkSet(setIndex: 1, reps: 5, weight: 80, at: day1),
              ],
            ),
          ],
        ),
        mkResult(
          planId: 'p1',
          finishedAt: day2,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              sets: [mkSet(setIndex: 0, reps: 3, weight: 95, at: day2)],
            ),
          ],
        ),
        mkResult(
          planId: 'p1',
          finishedAt: day3,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              sets: [
                mkSet(setIndex: 0, reps: 5, weight: 90, at: day3),
                // Tie of the 95 max — must not become a new PR.
                mkSet(setIndex: 1, reps: 1, weight: 95, at: day3),
              ],
            ),
          ],
        ),
      ];

      final prs = PersonalRecords.forExercise('bench', history);
      final byType = {for (final p in prs) p.type: p};

      expect(byType[PrType.maxWeight]!.value, 95);
      expect(byType[PrType.maxWeight]!.unit, 'kg');
      // First occurrence wins on ties — day2, not day3.
      expect(byType[PrType.maxWeight]!.achievedAt, day2);
      expect(byType[PrType.maxWeight]!.exerciseId, 'bench');
      expect(byType[PrType.maxWeight]!.sourceResultId, contains('p1|'));
    });

    test('estimated1RM uses Epley over eligible rep ranges only', () {
      final day1 = DateTime.utc(2026, 2, 1, 10);
      final day2 = DateTime.utc(2026, 2, 8, 10);

      final history = [
        mkResult(
          planId: 'plan',
          finishedAt: day1,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'squat',
              exerciseName: 'Squat',
              sets: [
                // 100 × 5 -> Epley 100 * (1 + 5/30) ≈ 116.667
                mkSet(setIndex: 0, reps: 5, weight: 100, at: day1),
              ],
            ),
          ],
        ),
        mkResult(
          planId: 'plan',
          finishedAt: day2,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'squat',
              exerciseName: 'Squat',
              sets: [
                // 80 × 10 -> Epley 80 * (1 + 10/30) ≈ 106.667 (lower)
                mkSet(setIndex: 0, reps: 10, weight: 80, at: day2),
                // 60 × 20 -> ineligible (reps > 15), would otherwise be 100.0.
                mkSet(setIndex: 1, reps: 20, weight: 60, at: day2),
              ],
            ),
          ],
        ),
      ];

      final prs = PersonalRecords.forExercise('squat', history);
      final e1rm = prs.firstWhere((p) => p.type == PrType.estimated1RM);
      expect(e1rm.value, closeTo(100 * (1 + 5 / 30), 1e-9));
      expect(e1rm.unit, 'kg');
      expect(e1rm.achievedAt, day1);

      final bestVol = prs.firstWhere((p) => p.type == PrType.bestVolumeSet);
      // 80*10 = 800, 60*20 = 1200, 100*5 = 500 → best is 1200.
      expect(bestVol.value, 1200);
      expect(bestVol.unit, 'kg·reps');
    });

    test('bodyweight-only exercise returns no PRs (weight-gated)', () {
      final day = DateTime.utc(2026, 3, 1, 10);
      final history = [
        mkResult(
          planId: 'plan',
          finishedAt: day,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'pullups',
              exerciseName: 'Pull-ups',
              sets: [
                mkSet(setIndex: 0, reps: 10, at: day),
                mkSet(setIndex: 1, reps: 8, at: day),
              ],
            ),
          ],
        ),
      ];
      expect(PersonalRecords.forExercise('pullups', history), isEmpty);
    });

    test('maxReps targets the heaviest weight ever lifted', () {
      final day1 = DateTime.utc(2026, 4, 1, 10);
      final day2 = DateTime.utc(2026, 4, 8, 10);
      final history = [
        mkResult(
          planId: 'plan',
          finishedAt: day1,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'dl',
              exerciseName: 'Deadlift',
              sets: [
                // 120 — top weight.
                mkSet(setIndex: 0, reps: 3, weight: 120, at: day1),
              ],
            ),
          ],
        ),
        mkResult(
          planId: 'plan',
          finishedAt: day2,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'dl',
              exerciseName: 'Deadlift',
              sets: [
                // Same top weight, higher reps → maxReps PR.
                mkSet(setIndex: 0, reps: 5, weight: 120, at: day2),
                // Lighter weight, even more reps — must NOT win maxReps.
                mkSet(setIndex: 1, reps: 12, weight: 80, at: day2),
              ],
            ),
          ],
        ),
      ];

      final prs = PersonalRecords.forExercise('dl', history);
      final maxReps = prs.firstWhere((p) => p.type == PrType.maxReps);
      expect(maxReps.value, 5);
      expect(maxReps.unit, 'reps');
      expect(maxReps.achievedAt, day2);
    });
  });

  // -- Cardio PRs ----------------------------------------------------------

  group('PersonalRecords.forCardio', () {
    test('detects longest distance, fastest pace and longest work time', () {
      final day1 = DateTime.utc(2026, 5, 1, 8);
      final day2 = DateTime.utc(2026, 5, 8, 8);
      final day3 = DateTime.utc(2026, 5, 15, 8);

      final history = [
        // Slow 5 km in 30 min → pace 360 s/km.
        mkCardio(
          planId: 'easy',
          finishedAt: day1,
          laps: [
            CardioLap.computed(
              intervalIndex: 0,
              duration: const Duration(minutes: 30),
              distanceMeters: 5000,
              completedAt: day1,
            ),
          ],
        ),
        // Fast 4 km in 18 min → pace 270 s/km. Shorter than 5 km though.
        mkCardio(
          planId: 'tempo',
          finishedAt: day2,
          laps: [
            CardioLap.computed(
              intervalIndex: 0,
              duration: const Duration(minutes: 18),
              distanceMeters: 4000,
              completedAt: day2,
            ),
          ],
        ),
        // Long 8 km in 50 min → pace 375 s/km; longest distance + work time.
        mkCardio(
          planId: 'long',
          finishedAt: day3,
          laps: [
            CardioLap.computed(
              intervalIndex: 0,
              duration: const Duration(minutes: 50),
              distanceMeters: 8000,
              completedAt: day3,
            ),
          ],
        ),
      ];

      final prs = PersonalRecords.forCardio(history);
      final byType = {for (final p in prs) p.type: p};

      expect(byType[PrType.longestDistance]!.value, 8000);
      expect(byType[PrType.longestDistance]!.unit, 'm');
      expect(byType[PrType.longestDistance]!.achievedAt, day3);

      expect(byType[PrType.fastestPace]!.value, 270);
      expect(byType[PrType.fastestPace]!.unit, 's/km');
      expect(byType[PrType.fastestPace]!.achievedAt, day2);

      expect(byType[PrType.longestWorkTime]!.value, 50 * 60);
      expect(byType[PrType.longestWorkTime]!.unit, 's');
      expect(byType[PrType.longestWorkTime]!.achievedAt, day3);

      // All cardio PRs are session-wide.
      for (final pr in prs) {
        expect(pr.exerciseId, isNull);
        expect(pr.sourceResultId, contains('|'));
      }
    });

    test('empty history yields no PRs', () {
      expect(PersonalRecords.forCardio(const []), isEmpty);
    });

    test('skips sessions with no recorded distance for pace PR', () {
      final day = DateTime.utc(2026, 6, 1, 8);
      final history = [
        mkCardio(
          planId: 'untimed',
          finishedAt: day,
          laps: [
            CardioLap(
              intervalIndex: 0,
              duration: const Duration(minutes: 30),
              completedAt: day,
            ),
          ],
        ),
      ];
      final prs = PersonalRecords.forCardio(history);
      // longestWorkTime is fine without distance, but pace must be skipped.
      expect(prs.any((p) => p.type == PrType.fastestPace), isFalse);
      expect(prs.any((p) => p.type == PrType.longestDistance), isFalse);
      expect(prs.any((p) => p.type == PrType.longestWorkTime), isTrue);
    });
  });

  // -- newRecordsIn --------------------------------------------------------

  group('PersonalRecords.newRecordsIn', () {
    test('flags only PRs first achieved inside the session window', () {
      final priorDay = DateTime.utc(2026, 7, 1, 10);
      final priorHistory = [
        mkResult(
          planId: 'plan',
          finishedAt: priorDay,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              sets: [mkSet(setIndex: 0, reps: 5, weight: 80, at: priorDay)],
            ),
          ],
        ),
      ];

      // Today's session: tie of 80 (no new PR) and a new top of 90 (PR).
      final start = DateTime.utc(2026, 7, 8, 10);
      final inWindow = start.add(const Duration(minutes: 20));
      final end = start.add(const Duration(minutes: 45));
      final today = WorkoutResult(
        planId: 'plan',
        startedAt: start,
        finishedAt: end,
        duration: const Duration(minutes: 45),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            sets: [
              // Tie of last week's 80 — must NOT show up as new.
              mkSet(setIndex: 0, reps: 5, weight: 80, at: inWindow),
              // Fresh max — should show up.
              mkSet(setIndex: 1, reps: 3, weight: 90, at: inWindow),
            ],
          ),
        ],
      );

      final fresh = PersonalRecords.newRecordsIn(today, priorHistory);
      final types = fresh.map((p) => p.type).toSet();

      // All fresh PRs should be from today's session.
      for (final pr in fresh) {
        expect(pr.achievedAt.isBefore(start), isFalse);
        expect(pr.achievedAt.isAfter(end), isFalse);
        expect(pr.exerciseId, 'bench');
      }

      // New max + new e1rm — both peaked today. bestVolumeSet does NOT
      // appear: prior week's 80×5 (=400) ties today's 80×5 (earlier wins),
      // and 90×3 (=270) is smaller.
      expect(types, contains(PrType.maxWeight));
      expect(types, contains(PrType.estimated1RM));
      expect(types, isNot(contains(PrType.bestVolumeSet)));

      final maxWeight = fresh.firstWhere((p) => p.type == PrType.maxWeight);
      expect(maxWeight.value, 90);
      expect(maxWeight.achievedAt, inWindow);
    });

    test('returns empty when current session does not break any PR', () {
      final priorDay = DateTime.utc(2026, 8, 1, 10);
      final priorHistory = [
        mkResult(
          planId: 'plan',
          finishedAt: priorDay,
          exercises: [
            PerformedExerciseDetails(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              sets: [
                mkSet(setIndex: 0, reps: 5, weight: 100, at: priorDay),
                mkSet(setIndex: 1, reps: 8, weight: 100, at: priorDay),
              ],
            ),
          ],
        ),
      ];

      final start = DateTime.utc(2026, 8, 8, 10);
      final today = WorkoutResult(
        planId: 'plan',
        startedAt: start,
        finishedAt: start.add(const Duration(minutes: 30)),
        duration: const Duration(minutes: 30),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            sets: [
              // All ties / weaker than last week — no fresh PR expected.
              mkSet(
                setIndex: 0,
                reps: 5,
                weight: 100,
                at: start.add(const Duration(minutes: 5)),
              ),
              mkSet(
                setIndex: 1,
                reps: 4,
                weight: 100,
                at: start.add(const Duration(minutes: 15)),
              ),
            ],
          ),
        ],
      );

      expect(PersonalRecords.newRecordsIn(today, priorHistory), isEmpty);
    });
  });

  // -- JSON round-trip -----------------------------------------------------

  group('PersonalRecord JSON', () {
    test('round-trips through toJson/fromJson', () {
      final pr = PersonalRecord(
        exerciseId: 'bench',
        type: PrType.maxWeight,
        value: 95,
        unit: 'kg',
        achievedAt: DateTime.utc(2026, 9, 1, 10),
        sourceResultId: 'p1|2026-09-01T10:00:00.000Z',
      );
      final round = PersonalRecord.fromJson(pr.toJson());
      expect(round, pr);

      // Cardio PR with null exerciseId must also round-trip.
      final cardio = PersonalRecord(
        exerciseId: null,
        type: PrType.fastestPace,
        value: 270,
        unit: 's/km',
        achievedAt: DateTime.utc(2026, 9, 8, 8),
        sourceResultId: 'run|2026-09-08T08:30:00.000Z',
      );
      expect(PersonalRecord.fromJson(cardio.toJson()), cardio);
    });
  });
}
