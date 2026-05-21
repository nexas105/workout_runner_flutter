import 'package:flutter/widgets.dart';

import '../controller/cardio_runner.dart';

/// Provides a [CardioRunner] to descendants. Analogous to
/// `RunnerScope` but for cardio sessions.
class CardioRunnerScope extends InheritedNotifier<CardioRunner> {
  const CardioRunnerScope({
    super.key,
    required CardioRunner runner,
    required super.child,
  }) : super(notifier: runner);

  /// Nearest [CardioRunner]. Throws if missing.
  static CardioRunner of(BuildContext context) {
    final runner = maybeOf(context);
    assert(runner != null, 'No CardioRunnerScope found in widget tree.');
    return runner!;
  }

  /// Nearest [CardioRunner] or `null`.
  static CardioRunner? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardioRunnerScope>()?.notifier;
}
