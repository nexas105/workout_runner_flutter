abstract class RunnerVoiceCues {
  const RunnerVoiceCues();

  Future<void> announceSetStart({
    required int setIndex,
    int? targetReps,
    double? targetWeight,
  }) => Future.value();

  Future<void> announceSetEnd({
    required int actualReps,
    double? actualWeight,
  }) => Future.value();

  Future<void> announceRestStart(Duration duration) => Future.value();

  Future<void> announceRestEnd() => Future.value();

  Future<void> announceWorkoutFinished() => Future.value();
}

class NoOpRunnerVoiceCues extends RunnerVoiceCues {
  const NoOpRunnerVoiceCues();
}
