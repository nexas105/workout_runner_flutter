import 'runner_action_result.dart';

abstract class RunnerErrorMessages {
  static String defaultMessage(RunnerActionError error) {
    switch (error) {
      case RunnerActionError.noActivePlan:
        return 'No workout is currently active.';
      case RunnerActionError.indexOutOfRange:
        return 'The requested index is out of range.';
      case RunnerActionError.alreadyRunning:
        return 'A workout is already running.';
      case RunnerActionError.invalidPlan:
        return 'The workout plan is invalid.';
      case RunnerActionError.performedSetLocked:
        return 'This set has already been performed and cannot be modified.';
      case RunnerActionError.idCollision:
        return 'An item with the same identifier already exists.';
      case RunnerActionError.notRunning:
        return 'No workout is currently running.';
      case RunnerActionError.storageFailed:
        return 'Storage operation failed.';
      case RunnerActionError.unknown:
        return 'An unknown error occurred.';
    }
  }
}
