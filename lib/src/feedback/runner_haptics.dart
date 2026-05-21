import 'dart:async';

import 'package:flutter/services.dart';

/// Plug-in hook interface the runner invokes at semantic moments
/// (set start/complete, rest tick, rest complete, etc.).
///
/// All methods have empty default bodies so subclasses can opt into
/// only the events they care about.
abstract class RunnerHaptics {
  const RunnerHaptics();

  void setStarted() {}

  void setCompleted() {}

  /// Fires once per rest period, when the remaining time drops to/under
  /// the configured countdown threshold (default last 3 s of rest).
  void restTickCountdown() {}

  void restCompleted() {}

  void restSkipped() {}

  void timedTargetReached() {}

  void workoutFinished() {}

  void prAchieved() {}

  void pause() {}

  void resume() {}
}

/// Default `flutter/services.dart` `HapticFeedback`-based implementation.
///
/// Picks reasonable patterns out of the box — apps can subclass and
/// override individual methods, or supply a fully custom implementation.
class DefaultRunnerHaptics extends RunnerHaptics {
  const DefaultRunnerHaptics();

  @override
  void setStarted() {
    HapticFeedback.lightImpact();
  }

  @override
  void setCompleted() {
    HapticFeedback.mediumImpact();
  }

  @override
  void restTickCountdown() {
    HapticFeedback.selectionClick();
  }

  @override
  void restCompleted() {
    HapticFeedback.heavyImpact();
  }

  @override
  void restSkipped() {
    HapticFeedback.selectionClick();
  }

  @override
  void timedTargetReached() {
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 80), HapticFeedback.lightImpact);
  }

  @override
  void workoutFinished() {
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
  }

  @override
  void prAchieved() {
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 60), HapticFeedback.lightImpact);
    Timer(const Duration(milliseconds: 120), HapticFeedback.lightImpact);
  }

  @override
  void pause() {
    HapticFeedback.selectionClick();
  }

  @override
  void resume() {
    HapticFeedback.selectionClick();
  }
}

/// Explicit do-nothing implementation. Useful for tests and for web
/// builds where `HapticFeedback` is a no-op anyway but you want to
/// make the intent visible at the call site.
class NoOpRunnerHaptics extends RunnerHaptics {
  const NoOpRunnerHaptics();
}
