enum SoundCue {
  countdownTick,
  restComplete,
  setComplete,
  workoutComplete,
  prAchieved,
  targetReached,
}

abstract class RunnerAudio {
  const RunnerAudio();

  void play(SoundCue cue) {}
}

class NoOpRunnerAudio extends RunnerAudio {
  const NoOpRunnerAudio();

  @override
  void play(SoundCue cue) {}
}
