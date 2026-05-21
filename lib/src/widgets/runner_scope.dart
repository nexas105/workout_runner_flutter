import 'package:flutter/widgets.dart';

import '../controller/workout_runner.dart';

/// Provides a [WorkoutRunner] to descendants so they don't have to pass it
/// through every constructor.
///
/// ```dart
/// RunnerScope(
///   runner: myRunner,
///   child: const RunnerPanel(),
/// );
/// ```
///
/// Internal widgets read the runner with [RunnerScope.of] and rebuild
/// on every notification.
class RunnerScope extends InheritedNotifier<WorkoutRunner> {
  const RunnerScope({
    super.key,
    required WorkoutRunner runner,
    required super.child,
  }) : super(notifier: runner);

  /// Returns the nearest [WorkoutRunner]. Throws if none was provided.
  static WorkoutRunner of(BuildContext context) {
    final runner = maybeOf(context);
    assert(runner != null, 'No RunnerScope found in widget tree.');
    return runner!;
  }

  /// Returns the nearest [WorkoutRunner], or `null` when missing.
  static WorkoutRunner? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RunnerScope>()?.notifier;
}
