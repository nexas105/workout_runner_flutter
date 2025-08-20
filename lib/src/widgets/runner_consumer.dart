import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

typedef RunnerViewBuilder =
    Widget Function(
      BuildContext context,
      WorkoutPlan plan,
      WorkoutRunnerState state,
      WorkoutRunnerController ctrl,
    );

class RunnerConsumer extends StatefulWidget {
  final WorkoutPlan plan;
  final bool resume;
  final RunnerViewBuilder builder;

  const RunnerConsumer({
    super.key,
    required this.plan,
    required this.builder,
    this.resume = true,
  });

  @override
  State<RunnerConsumer> createState() => _RunnerConsumerState();
}

class _RunnerConsumerState extends State<RunnerConsumer> {
  bool _ranEnsure = false;

  @override
  void initState() {
    super.initState();
    runner.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureStarted());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ranEnsure) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureStarted());
    }
  }

  Future<void> _ensureStarted() async {
    if (!mounted || _ranEnsure) return;
    _ranEnsure = true;

    final currentPlan = runner.plan;
    final currentState = runner.state;

    if (currentPlan != null &&
        currentPlan.id != widget.plan.id &&
        currentState?.isActive == true) {
      final proceed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Anderer Plan aktiv'),
              content: Text(
                'Es läuft gerade „${currentPlan.name}“. Zu „${widget.plan.name}“ wechseln?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Ja, wechseln'),
                ),
              ],
            ),
      );

      if (proceed == true) {
        await runner.start(widget.plan, resumeIfPossible: false);
      }
    } else if (runner.plan?.id != widget.plan.id) {
      await runner.start(widget.plan, resumeIfPossible: false);
    } else if (widget.resume && runner.state == null) {
      await runner.start(widget.plan, resumeIfPossible: true);
    }

    if (mounted) setState(() {});
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    runner.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = runner.plan;
    final s = runner.state;
    if (p == null || s == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Workout wird geladen...',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return widget.builder(context, p, s, runner);
  }
}
