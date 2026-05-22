import '../controller/cardio_runner.dart';
import '../controller/workout_runner.dart';
import 'runner_haptics.dart';

/// Convenience wiring helper. Apps call once after constructing the
/// runner to attach a [RunnerHaptics] implementation to the runner's
/// existing callback slots.
///
/// The bridge does NOT modify the runner — it only assigns the
/// `onSetCompleted`/`onRest*`/`onPaused`/`onResumed`/`onFinished`/
/// `onTimedSetTargetReached` slots. Apps that need their own logic in
/// those callbacks can either subclass the [RunnerHaptics] interface
/// and call through, or skip the bridge and wire the methods manually.
class RunnerHapticsBridge {
  RunnerHapticsBridge._();

  /// Attaches [haptics] to [runner]'s callback slots.
  ///
  /// [tickAt] controls when [RunnerHaptics.restTickCountdown] fires —
  /// once per rest period, the first time `restRemaining <= tickAt`.
  ///
  /// Calling [wire] a second time on the same [runner] simply
  /// reassigns the callback slots, so the previous wiring is replaced
  /// (the runner only holds one callback per event).
  static void wire(
    WorkoutRunner runner,
    RunnerHaptics haptics, {
    Duration tickAt = const Duration(seconds: 3),
  }) {
    var countdownFired = false;

    runner.onSetCompleted = (_) => haptics.setCompleted();
    runner.onRestStarted = (duration) {
      countdownFired = false;
      if (duration <= tickAt && duration > Duration.zero) {
        countdownFired = true;
        haptics.restTickCountdown();
      }
    };
    runner.onRestTick = (remaining) {
      if (!countdownFired && remaining <= tickAt && remaining > Duration.zero) {
        countdownFired = true;
        haptics.restTickCountdown();
      }
    };
    runner.onRestCompleted = haptics.restCompleted;
    runner.onRestSkipped = haptics.restSkipped;
    runner.onTimedSetTargetReached = (_) => haptics.timedTargetReached();
    runner.onPaused = haptics.pause;
    runner.onResumed = (_) => haptics.resume();
    runner.onFinished = (_) => haptics.workoutFinished();
  }

  /// Cardio analog of [wire]. Maps the cardio runner's coarser event
  /// surface (interval complete / pause / resume / finished) onto the
  /// matching [RunnerHaptics] methods.
  ///
  /// Calling [wireCardio] a second time replaces the previous wiring.
  static void wireCardio(CardioRunner runner, RunnerHaptics haptics) {
    runner.onIntervalCompleted = (_) => haptics.setCompleted();
    runner.onPaused = haptics.pause;
    runner.onResumed = haptics.resume;
    runner.onFinished = (_) => haptics.workoutFinished();
  }
}
