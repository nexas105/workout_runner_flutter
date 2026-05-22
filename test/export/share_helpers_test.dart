import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutResult _emptyWorkout() => WorkoutResult(
  planId: 'plan-empty',
  startedAt: DateTime.utc(2026, 5, 21, 9, 0),
  finishedAt: DateTime.utc(2026, 5, 21, 9, 0),
  duration: Duration.zero,
  exercises: const [],
);

WorkoutResult _populatedWorkout() {
  final finished = DateTime.utc(2026, 5, 21, 10, 0);
  return WorkoutResult(
    planId: 'push-day',
    startedAt: DateTime.utc(2026, 5, 21, 9, 15),
    finishedAt: finished,
    duration: const Duration(minutes: 45, seconds: 12),
    exercises: [
      PerformedExerciseDetails(
        exerciseId: 'bench',
        exerciseName: 'Bench press',
        sets: [
          PerformedSet(
            exerciseIndex: 0,
            setIndex: 0,
            actualReps: 8,
            actualWeight: 60,
            completedAt: finished,
          ),
          PerformedSet(
            exerciseIndex: 0,
            setIndex: 1,
            actualReps: 8,
            actualWeight: 60,
            completedAt: finished,
          ),
          PerformedSet(
            exerciseIndex: 0,
            setIndex: 2,
            actualReps: 6,
            actualWeight: 65,
            completedAt: finished,
          ),
        ],
      ),
      PerformedExerciseDetails(
        exerciseId: 'pushup',
        exerciseName: 'Push up',
        sets: [
          PerformedSet(
            exerciseIndex: 1,
            setIndex: 0,
            actualReps: 15,
            completedAt: finished,
          ),
        ],
      ),
    ],
  );
}

CardioResult _emptyCardio() => CardioResult(
  planId: 'plan-cardio-empty',
  planName: '',
  discipline: CardioDiscipline.running,
  startedAt: DateTime.utc(2026, 5, 21, 9, 0),
  finishedAt: DateTime.utc(2026, 5, 21, 9, 0),
  duration: Duration.zero,
  laps: const [],
);

CardioResult _populatedCardio() {
  final completed = DateTime.utc(2026, 5, 21, 10, 0);
  return CardioResult(
    planId: 'easy-5k',
    planName: 'Easy 5k',
    discipline: CardioDiscipline.running,
    startedAt: DateTime.utc(2026, 5, 21, 9, 30),
    finishedAt: completed,
    duration: const Duration(minutes: 27, seconds: 30),
    laps: [
      CardioLap.computed(
        intervalIndex: 0,
        duration: const Duration(minutes: 5, seconds: 30),
        distanceMeters: 1000,
        avgHeartRate: 145,
        rpe: 5,
        completedAt: completed,
      ),
      CardioLap.computed(
        intervalIndex: 1,
        duration: const Duration(minutes: 5, seconds: 30),
        distanceMeters: 1000,
        avgHeartRate: 150,
        completedAt: completed,
      ),
      CardioLap.computed(
        intervalIndex: 2,
        duration: const Duration(minutes: 5, seconds: 30),
        distanceMeters: 1000,
        completedAt: completed,
      ),
    ],
  );
}

void main() {
  group('ShareHelpers.toShareText', () {
    test('returns a non-empty multi-line summary for populated workout', () {
      final text = ShareHelpers.toShareText(_populatedWorkout());
      expect(text, isNotEmpty);
      expect(text.contains('push-day'), isTrue);
      expect(text.contains('45:12'), isTrue);
      expect('\n'.allMatches(text).length, greaterThanOrEqualTo(2));
    });

    test('still produces a header for empty workout', () {
      final text = ShareHelpers.toShareText(_emptyWorkout());
      expect(text, isNotEmpty);
      expect(text.startsWith('Workout: plan-empty'), isTrue);
      expect(text.contains('00:00'), isTrue);
    });
  });

  group('ShareHelpers.toMarkdown', () {
    test('contains plan id, totals, and one row per exercise', () {
      final md = ShareHelpers.toMarkdown(_populatedWorkout());
      expect(md, startsWith('# Workout - push-day'));
      expect(md.contains('**Duration:** 45:12'), isTrue);
      expect(md.contains('**Sets:** 4'), isTrue);
      expect(md.contains('**Reps:** 37'), isTrue);
      expect(md.contains('## Exercises'), isTrue);
      expect(md.contains('- Bench press - 3 sets, 22 reps total'), isTrue);
      expect(md.contains('8 x 60 kg'), isTrue);
      expect(md.contains('6 x 65 kg'), isTrue);
      expect(md.contains('- Push up - 1 sets, 15 reps total'), isTrue);
    });

    test('empty workout still emits the header', () {
      final md = ShareHelpers.toMarkdown(_emptyWorkout());
      expect(md, startsWith('# Workout - plan-empty'));
      expect(md.contains('## Exercises'), isFalse);
    });

    test('no emojis in output', () {
      final md = ShareHelpers.toMarkdown(_populatedWorkout());
      final emojiPattern = RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true);
      expect(emojiPattern.hasMatch(md), isFalse);
    });
  });

  group('ShareHelpers.toShareTextCardio', () {
    test('returns multi-line summary with discipline and distance', () {
      final text = ShareHelpers.toShareTextCardio(_populatedCardio());
      expect(text, isNotEmpty);
      expect(text.contains('Easy 5k'), isTrue);
      expect(text.contains('Running'), isTrue);
      expect(text.contains('3.00 km'), isTrue);
      expect(text.contains('27:30'), isTrue);
      expect('\n'.allMatches(text).length, greaterThanOrEqualTo(2));
    });

    test('empty cardio result still produces a header', () {
      final text = ShareHelpers.toShareTextCardio(_emptyCardio());
      expect(text, isNotEmpty);
      expect(text.contains('plan-cardio-empty'), isTrue);
      expect(text.contains('Running'), isTrue);
    });
  });

  group('ShareHelpers.toMarkdownCardio', () {
    test('lists every lap when populated', () {
      final md = ShareHelpers.toMarkdownCardio(_populatedCardio());
      expect(md, startsWith('# Cardio - Easy 5k'));
      expect(md.contains('**Discipline:** Running'), isTrue);
      expect(md.contains('**Distance:** 3.00 km'), isTrue);
      expect(md.contains('## Laps'), isTrue);
      expect(md.contains('- Lap 1:'), isTrue);
      expect(md.contains('- Lap 2:'), isTrue);
      expect(md.contains('- Lap 3:'), isTrue);
      expect(md.contains('145 bpm'), isTrue);
      expect(md.contains('RPE 5'), isTrue);
    });

    test('empty cardio result still emits the header', () {
      final md = ShareHelpers.toMarkdownCardio(_emptyCardio());
      expect(md, startsWith('# Cardio - plan-cardio-empty'));
      expect(md.contains('## Laps'), isFalse);
    });
  });
}
