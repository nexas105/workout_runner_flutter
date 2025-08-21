import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class CurrentWorkout extends StatelessWidget {
  final TextStyle? textStyle;
  final Color? cardColor;
  final WorkoutRunnerController controller;
  const CurrentWorkout({
    super.key,
    this.textStyle,
    this.cardColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final currentWorkout = controller.plan;
    final currentState = controller.state;
    if (currentWorkout == null || currentState == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      color: cardColor ?? theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentWorkout.name,
              style:
                  textStyle ??
                  theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  "${currentWorkout.exercises.length} Übungen",
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Text(
                  _fmt(controller.elapsed),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    } else {
      return '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
  }
}
