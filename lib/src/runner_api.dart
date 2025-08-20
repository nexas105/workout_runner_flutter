import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/widgets.dart';

final WorkoutRunnerController runner = WorkoutRunnerController();

typedef RunnerWidgetBuilder =
    Widget Function(BuildContext context, WorkoutRunnerController ctrl);
typedef OnRunnerFinished = void Function(WorkoutResult result);
