import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

String fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  } else {
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class RunnerScreen extends StatelessWidget {
  final WorkoutPlan plan;
  final OnRunnerFinished? onFinished;
  const RunnerScreen({super.key, required this.plan, this.onFinished});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RunnerStatusAppBar(controller: runner),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: RunnerPanel(
          controller: runner,
          plan: plan,
          onFinished: (res) {
            debugPrint('Workout finished: ${res.toJson()}');
            Navigator.pop(context);
          },

          // CurrentExercise Styles
          exerciseTitleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
          exerciseSubtitleStyle: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          exerciseActiveBorderColor: Colors.deepPurple,
          exerciseInactiveBorderColor: Colors.grey,
          exerciseActiveCardColor: Colors.deepPurple.withOpacity(0.1),
          exerciseInactiveCardColor: Theme.of(context).colorScheme.surface,
          exerciseActiveIconColor: Colors.deepPurple,
          exerciseInactiveIconColor: Colors.grey,

          // SetView Styles
          setTitleStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.teal),
          setInputStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 14),
          setActiveCardColor: Colors.teal.withOpacity(0.1),
          setInactiveCardColor: Theme.of(context).colorScheme.surface,
          setDoneCardColor: Colors.teal.withOpacity(0.3),
        ),
      ),
    );
  }
}
