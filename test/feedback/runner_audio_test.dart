import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAudio extends RunnerAudio {
  final List<SoundCue> cues = [];

  @override
  void play(SoundCue cue) {
    cues.add(cue);
  }
}

WorkoutPlan _plan() => const WorkoutPlan(
  id: 'plan_audio',
  name: 'Audio plan',
  exercises: [
    WorkoutExercise(
      id: 'ex_bench',
      name: 'Bench',
      sets: [WorkoutSet(targetReps: 8, rest: Duration(seconds: 3))],
    ),
  ],
);

void main() {
  group('NoOpRunnerAudio', () {
    test('play does not throw for any SoundCue', () {
      const audio = NoOpRunnerAudio();
      for (final cue in SoundCue.values) {
        expect(() => audio.play(cue), returnsNormally);
      }
    });
  });

  group('RunnerAudioBridge.wire', () {
    test('records setComplete, three countdownTicks, and restComplete '
        'across a 3s rest', () async {
      final storage = InMemoryRunnerStorage();
      final runner = WorkoutRunner(storage: storage);
      addTearDown(runner.dispose);

      final audio = _RecordingAudio();
      // Wiring twice exercises idempotency: the second call must
      // overwrite the first so cues are only recorded once.
      RunnerAudioBridge.wire(runner);
      RunnerAudioBridge.wire(runner, audio: audio);

      await runner.start(_plan());
      runner.setActiveExercise(0);
      runner.startSet(0, 0);

      await runner.finishCurrentSet(reps: 8, rest: const Duration(seconds: 3));

      expect(audio.cues, [SoundCue.setComplete, SoundCue.countdownTick]);

      // Wait for the runner's per-second rest ticker to fire three times,
      // ending with onRestCompleted. A small buffer keeps the test stable
      // against scheduler jitter.
      await Future<void>.delayed(const Duration(milliseconds: 3300));

      expect(audio.cues, [
        SoundCue.setComplete,
        SoundCue.countdownTick,
        SoundCue.countdownTick,
        SoundCue.countdownTick,
        SoundCue.restComplete,
      ]);
    });
  });
}
