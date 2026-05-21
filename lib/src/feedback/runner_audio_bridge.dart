import '../controller/cardio_runner.dart';
import '../controller/workout_runner.dart';
import 'runner_audio.dart';
import 'runner_voice.dart';

class RunnerAudioBridge {
  RunnerAudioBridge._();

  static void wire(
    WorkoutRunner runner, {
    RunnerAudio? audio,
    RunnerVoiceCues? voice,
    Duration tickAt = const Duration(seconds: 3),
  }) {
    runner.onSetCompleted = (performed) {
      audio?.play(SoundCue.setComplete);
      voice?.announceSetEnd(
        actualReps: performed.actualReps,
        actualWeight: performed.actualWeight,
      );
    };

    runner.onRestStarted = (duration) {
      voice?.announceRestStart(duration);
      if (duration > Duration.zero && duration <= tickAt) {
        audio?.play(SoundCue.countdownTick);
      }
    };

    runner.onRestTick = (remaining) {
      if (remaining > Duration.zero && remaining <= tickAt) {
        audio?.play(SoundCue.countdownTick);
      }
    };

    runner.onRestCompleted = () {
      audio?.play(SoundCue.restComplete);
      voice?.announceRestEnd();
    };

    runner.onTimedSetTargetReached = (_) {
      audio?.play(SoundCue.targetReached);
    };

    runner.onFinished = (_) {
      audio?.play(SoundCue.workoutComplete);
      voice?.announceWorkoutFinished();
    };
  }

  static void wireCardio(
    CardioRunner runner, {
    RunnerAudio? audio,
    RunnerVoiceCues? voice,
  }) {
    runner.onIntervalCompleted = (_) {
      audio?.play(SoundCue.setComplete);
    };
    runner.onFinished = (_) {
      audio?.play(SoundCue.workoutComplete);
      voice?.announceWorkoutFinished();
    };
  }
}
