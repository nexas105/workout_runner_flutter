import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutNotes session note', () {
    test('writes and reads a session note via plan meta', () {
      const plan = WorkoutPlan(id: 'p1', name: 'Push', exercises: []);
      expect(WorkoutNotes.readSessionNote(plan), isNull);

      final updated = WorkoutNotes.writeSessionNote(plan, 'felt strong');
      expect(updated.meta?['sessionNote'], 'felt strong');
      expect(WorkoutNotes.readSessionNote(updated), 'felt strong');
    });

    test('writing null removes the session note key', () {
      const plan = WorkoutPlan(
        id: 'p1',
        name: 'Push',
        exercises: [],
        meta: {'sessionNote': 'old', 'other': 1},
      );
      final cleared = WorkoutNotes.writeSessionNote(plan, null);
      expect(cleared.meta?['sessionNote'], isNull);
      expect(cleared.meta?['other'], 1);
    });

    test('tolerates non-string meta values', () {
      const plan = WorkoutPlan(
        id: 'p1',
        name: 'Push',
        exercises: [],
        meta: {'sessionNote': 42},
      );
      expect(WorkoutNotes.readSessionNote(plan), isNull);
    });
  });

  group('WorkoutNotes exercise note', () {
    test('round-trips through meta without touching the notes field', () {
      const ex = WorkoutExercise(
        id: 'ex1',
        name: 'Bench press',
        notes: 'keep shoulders packed',
      );
      expect(WorkoutNotes.readExerciseNote(ex), isNull);
      expect(ex.notes, 'keep shoulders packed');

      final updated = WorkoutNotes.writeExerciseNote(ex, 'left elbow tight');
      expect(WorkoutNotes.readExerciseNote(updated), 'left elbow tight');
      expect(updated.notes, 'keep shoulders packed');
      expect(updated.meta?['note'], 'left elbow tight');
    });

    test('writing null removes the note key from meta', () {
      const ex = WorkoutExercise(
        id: 'ex1',
        name: 'Bench press',
        meta: {'note': 'foo', 'other': 'keep'},
      );
      final cleared = WorkoutNotes.writeExerciseNote(ex, null);
      expect(cleared.meta?['note'], isNull);
      expect(cleared.meta?['other'], 'keep');
    });
  });

  group('WorkoutNotes.setNoteKey', () {
    test('composes exercise/set indices into "ex.set"', () {
      expect(WorkoutNotes.setNoteKey(2, 0), '2.0');
      expect(WorkoutNotes.setNoteKey(0, 5), '0.5');
    });
  });

  group('WorkoutNotes.readResultSessionNote', () {
    test('returns null for empty results', () {
      final result = WorkoutResult(
        planId: 'p1',
        startedAt: DateTime.utc(2026, 5, 21, 10),
        finishedAt: DateTime.utc(2026, 5, 21, 11),
        duration: const Duration(hours: 1),
        exercises: const [],
      );
      expect(WorkoutNotes.readResultSessionNote(result), isNull);
    });
  });

  group('NotesTimeline.buildFor', () {
    test('empty result yields empty timeline', () {
      final result = WorkoutResult(
        planId: 'p1',
        startedAt: DateTime.utc(2026, 5, 21, 10),
        finishedAt: DateTime.utc(2026, 5, 21, 11),
        duration: const Duration(hours: 1),
        exercises: const [],
      );
      expect(NotesTimeline.buildFor(result), isEmpty);
    });

    test('orders set notes by completedAt', () {
      final t0 = DateTime.utc(2026, 5, 21, 10, 0, 0);
      final t1 = DateTime.utc(2026, 5, 21, 10, 5, 0);
      final t2 = DateTime.utc(2026, 5, 21, 10, 10, 0);

      final result = WorkoutResult(
        planId: 'p1',
        startedAt: t0,
        finishedAt: t2.add(const Duration(minutes: 1)),
        duration: const Duration(minutes: 11),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'ex1',
            exerciseName: 'Bench',
            sets: [
              PerformedSet(
                exerciseIndex: 0,
                setIndex: 0,
                actualReps: 8,
                completedAt: t0,
              ),
              PerformedSet(
                exerciseIndex: 0,
                setIndex: 1,
                actualReps: 8,
                completedAt: t2,
              ),
            ],
          ),
          PerformedExerciseDetails(
            exerciseId: 'ex2',
            exerciseName: 'Row',
            sets: [
              PerformedSet(
                exerciseIndex: 1,
                setIndex: 0,
                actualReps: 10,
                completedAt: t1,
              ),
            ],
          ),
        ],
      );

      final timeline = NotesTimeline.buildFor(
        result,
        setNotes: {
          WorkoutNotes.setNoteKey(0, 0): 'warmup felt easy',
          WorkoutNotes.setNoteKey(0, 1): 'top set, grindy',
          WorkoutNotes.setNoteKey(1, 0): 'pulled clean',
        },
      );

      expect(timeline, hasLength(3));
      expect(timeline[0].note, 'warmup felt easy');
      expect(timeline[0].label, 'Bench · Set 1');
      expect(timeline[0].at, t0);
      expect(timeline[1].note, 'pulled clean');
      expect(timeline[1].label, 'Row · Set 1');
      expect(timeline[1].at, t1);
      expect(timeline[2].note, 'top set, grindy');
      expect(timeline[2].label, 'Bench · Set 2');
      expect(timeline[2].at, t2);
    });

    test('skips sets without notes and tolerates missing setNotes map', () {
      final t0 = DateTime.utc(2026, 5, 21, 10, 0, 0);
      final result = WorkoutResult(
        planId: 'p1',
        startedAt: t0,
        finishedAt: t0.add(const Duration(minutes: 1)),
        duration: const Duration(minutes: 1),
        exercises: [
          PerformedExerciseDetails(
            exerciseId: 'ex1',
            exerciseName: 'Bench',
            sets: [
              PerformedSet(
                exerciseIndex: 0,
                setIndex: 0,
                actualReps: 8,
                completedAt: t0,
              ),
            ],
          ),
        ],
      );
      expect(NotesTimeline.buildFor(result), isEmpty);
      expect(NotesTimeline.buildFor(result, setNotes: const {}), isEmpty);
    });
  });
}
