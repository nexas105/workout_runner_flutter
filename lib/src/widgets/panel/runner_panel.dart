import 'package:fitness_workout/fitness_workout.dart';
import 'package:fitness_workout/src/widgets/panel/current_exercise.dart';
import 'package:fitness_workout/src/widgets/panel/current_workout.dart';
import 'package:fitness_workout/src/widgets/panel/results.dart';
import 'package:fitness_workout/src/widgets/panel/set_view.dart';
import 'package:flutter/material.dart';

class RunnerPanel extends StatefulWidget {
  final WorkoutPlan plan;
  final WorkoutRunnerController controller;
  final bool resume;
  final OnRunnerFinished? onFinished;

  // Style overrides for CurrentExercise
  final TextStyle? exerciseTitleStyle;
  final TextStyle? exerciseSubtitleStyle;
  final Color? exerciseActiveBorderColor;
  final Color? exerciseInactiveBorderColor;
  final Color? exerciseActiveCardColor;
  final Color? exerciseInactiveCardColor;
  final Color? exerciseActiveIconColor;
  final Color? exerciseInactiveIconColor;

  // Style overrides for SetView
  final TextStyle? setTitleStyle;
  final TextStyle? setInputStyle;
  final Color? setActiveCardColor;
  final Color? setInactiveCardColor;
  final Color? setDoneCardColor;

  const RunnerPanel({
    super.key,
    required this.plan,
    required this.controller,
    this.resume = true,
    this.onFinished,
    // CurrentExercise styles
    this.exerciseTitleStyle,
    this.exerciseSubtitleStyle,
    this.exerciseActiveBorderColor,
    this.exerciseInactiveBorderColor,
    this.exerciseActiveCardColor,
    this.exerciseInactiveCardColor,
    this.exerciseActiveIconColor,
    this.exerciseInactiveIconColor,
    // SetView styles
    this.setTitleStyle,
    this.setInputStyle,
    this.setActiveCardColor,
    this.setInactiveCardColor,
    this.setDoneCardColor,
  });

  @override
  State<RunnerPanel> createState() => _RunnerPanelState();
}

class _RunnerPanelState extends State<RunnerPanel> {
  @override
  Widget build(BuildContext context) {
    return RunnerConsumer(
      plan: widget.plan,
      resume: widget.resume,
      builder: (context, p, st, ctrl) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CurrentWorkout(controller: widget.controller),
              CurrentExercise(
                controller: widget.controller,
                titleStyle: widget.exerciseTitleStyle,
                subtitleStyle: widget.exerciseSubtitleStyle,
                activeBorderColor: widget.exerciseActiveBorderColor,
                inactiveBorderColor: widget.exerciseInactiveBorderColor,
                activeCardColor: widget.exerciseActiveCardColor,
                inactiveCardColor: widget.exerciseInactiveCardColor,
                activeIconColor: widget.exerciseActiveIconColor,
                inactiveIconColor: widget.exerciseInactiveIconColor,
              ),
              SetView(
                controller: widget.controller,
                titleStyle: widget.setTitleStyle,
                inputStyle: widget.setInputStyle,
                activeCardColor: widget.setActiveCardColor,
                inactiveCardColor: widget.setInactiveCardColor,
                doneCardColor: widget.setDoneCardColor,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => Results(
                            onFinish: () async {
                              final r = await ctrl.finish();
                              if (r != null) {
                                widget.onFinished?.call(r);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Workout noch nicht abgeschlossen',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                    ),
                  );
                },
                child: const Text('Beenden'),
              ),
            ],
          ),
        );
      },
    );
  }
}
