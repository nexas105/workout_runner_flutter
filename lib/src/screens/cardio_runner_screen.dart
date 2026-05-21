import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/cardio_runner.dart';
import '../models/cardio/cardio_plan.dart';
import '../models/cardio/cardio_result.dart';
import '../theme/workout_runner_theme.dart';
import '../widgets/cardio_results_view.dart';
import '../widgets/cardio_runner_panel.dart';
import '../widgets/cardio_runner_scope.dart';
import '../widgets/internals/runner_pill_button.dart';

/// Drop-in cardio screen: AppBar, panel and automatic transition to
/// [CardioResultsView] on finish.
class CardioRunnerScreen extends StatefulWidget {
  final CardioPlan plan;
  final CardioRunner runner;
  final bool autoStart;
  final void Function(BuildContext context, CardioResult result)? onFinished;

  const CardioRunnerScreen({
    super.key,
    required this.plan,
    required this.runner,
    this.autoStart = true,
    this.onFinished,
  });

  @override
  State<CardioRunnerScreen> createState() => _CardioRunnerScreenState();
}

class _CardioRunnerScreenState extends State<CardioRunnerScreen> {
  StreamSubscription<CardioResult>? _sub;

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

  void _handleFinished(CardioResult result) {
    if (!mounted) return;
    final handler = widget.onFinished ?? _defaultOnFinished;
    handler(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return CardioRunnerScope(
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
        body: const CardioRunnerPanel(),
      ),
    );
  }

  Future<void> _confirmAbandon(BuildContext context) async {
    final runner = widget.runner;
    if (runner.plan == null) {
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
                  Text('Leave cardio session?', style: t.titleLarge),
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

  void _defaultOnFinished(BuildContext context, CardioResult result) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: WorkoutRunnerTheme.of(context).background,
              body: CardioResultsView(
                result: result,
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
      ),
    );
  }
}

enum _ExitChoice { stay, leave }
