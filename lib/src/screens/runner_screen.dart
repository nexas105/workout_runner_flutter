import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/workout_runner.dart';
import '../models/workout_plan.dart';
import '../models/workout_result.dart';
import '../theme/workout_runner_theme.dart';
import '../widgets/internals/runner_pill_button.dart';
import '../widgets/results_view.dart';
import '../widgets/runner_panel.dart';
import '../widgets/runner_scope.dart';

/// Drop-in workout screen: AppBar, panel, and an automatic transition to a
/// results view when the workout finishes.
///
/// Push this on your `Navigator`, pass the plan and your [WorkoutRunner]
/// instance. If [autoStart] is `true` (default) the runner is started in
/// `initState` (resumes if the same plan is already active).
class RunnerScreen extends StatefulWidget {
  final WorkoutPlan plan;
  final WorkoutRunner runner;
  final bool autoStart;

  /// Called when the workout finishes (via the finish button). Defaults to
  /// pushing [ResultsView] as a replacement route.
  final void Function(BuildContext context, WorkoutResult result)? onFinished;

  const RunnerScreen({
    super.key,
    required this.plan,
    required this.runner,
    this.autoStart = true,
    this.onFinished,
  });

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen> {
  StreamSubscription<WorkoutResult>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.runner.finished.listen(_handleFinished);
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.runner.start(widget.plan);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handleFinished(WorkoutResult result) {
    if (!mounted) return;
    final handler = widget.onFinished ?? _defaultOnFinished;
    handler(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerScope(
      runner: widget.runner,
      child: Scaffold(
        backgroundColor: t.background,
        appBar: AppBar(
          backgroundColor: t.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: t.textPrimary),
            onPressed: () => _confirmAbandon(context),
          ),
          title: ListenableBuilder(
            listenable: widget.runner,
            builder:
                (context, _) => Text(
                  widget.runner.plan?.name ?? widget.plan.name,
                  style: t.title.copyWith(color: t.textPrimary),
                ),
          ),
        ),
        body: const RunnerPanel(),
      ),
    );
  }

  Future<void> _confirmAbandon(BuildContext context) async {
    final runner = widget.runner;
    if (!runner.isRunning) {
      Navigator.of(context).pop();
      return;
    }
    final t = WorkoutRunnerTheme.of(context);
    final result = await showDialog<_ExitChoice>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: t.surface,
            shape: RoundedRectangleBorder(borderRadius: t.radiusLarge),
            child: Padding(
              padding: EdgeInsets.all(t.space5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leave workout?', style: t.titleLarge),
                  SizedBox(height: t.space2),
                  Text(
                    'Your progress stays saved — you can resume from here.',
                    style: t.bodyMuted,
                  ),
                  SizedBox(height: t.space5),
                  Row(
                    children: [
                      Expanded(
                        child: RunnerPillButton(
                          label: 'Stay',
                          style: RunnerButtonStyle.outline,
                          onPressed:
                              () => Navigator.of(ctx).pop(_ExitChoice.stay),
                          expand: true,
                        ),
                      ),
                      SizedBox(width: t.space2),
                      Expanded(
                        child: RunnerPillButton(
                          label: 'Leave',
                          style: RunnerButtonStyle.danger,
                          onPressed:
                              () => Navigator.of(ctx).pop(_ExitChoice.leave),
                          expand: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (result == _ExitChoice.leave && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _defaultOnFinished(BuildContext context, WorkoutResult result) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          // Use the *new* route's context — the outer `context` belongs to
          // the route we just replaced; reading inherited widgets off it
          // after pushReplacement deactivates the element throws.
          backgroundColor: WorkoutRunnerTheme.of(routeContext).background,
          body: ResultsView(
            result: result,
            onClose: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
  }
}

enum _ExitChoice { stay, leave }
