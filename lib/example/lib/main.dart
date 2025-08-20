import 'package:fitness_workout/example/lib/runner_screen.dart';
import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runner.configure();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  List<WorkoutPlan> _plans() => [
    WorkoutPlan(
      id: 'p1',
      name: 'Pull',
      exercises: [
        WorkoutExercise(
          id: 'bp',
          name: 'Bankdrücken',
          sets: [
            WorkoutSet(targetReps: 10, targetWeight: 80),
            WorkoutSet(targetReps: 8, targetWeight: 85),
          ],
        ),
        WorkoutExercise(
          id: 'ohp',
          name: 'OHP',
          sets: [WorkoutSet(targetReps: 10, targetWeight: 50)],
        ),
      ],
    ),
    WorkoutPlan(
      id: 'p2',
      name: 'Push',
      exercises: [
        WorkoutExercise(
          id: 'sqt',
          name: 'Squat',
          sets: [
            WorkoutSet(targetReps: 10, targetWeight: 100),
            WorkoutSet(targetReps: 8, targetWeight: 110),
          ],
        ),
      ],
    ),
    WorkoutPlan(
      id: 'p2',
      name: 'Push',
      exercises: [
        WorkoutExercise(
          id: 'sqt',
          name: 'Squat',
          sets: [
            WorkoutSet(targetReps: 10, targetWeight: 100),
            WorkoutSet(targetReps: 8, targetWeight: 110),
          ],
        ),
      ],
    ),
    WorkoutPlan(
      id: 'p2',
      name: 'Push',
      exercises: [
        WorkoutExercise(
          id: 'sqt',
          name: 'Squat',
          sets: [
            WorkoutSet(targetReps: 10, targetWeight: 100),
            WorkoutSet(targetReps: 8, targetWeight: 110),
          ],
        ),
      ],
    ),
    WorkoutPlan(
      id: 'p2',
      name: 'Push',
      exercises: [
        WorkoutExercise(
          id: 'sqt',
          name: 'Squat',
          sets: [
            WorkoutSet(targetReps: 10, targetWeight: 100),
            WorkoutSet(targetReps: 8, targetWeight: 110),
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final plans = _plans();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: RunnerStatusChip(controller: runner),
          ),
        ],
      ),
      body: Column(
        children: [
          QuickRunner(controller: runner, plans: _plans()),
          RunnerStatusBanner(controller: runner),

          Expanded(
            child: ListView.builder(
              itemCount: plans.length,
              itemBuilder: (context, i) {
                final plan = plans[i];
                return ListTile(
                  title: Text(plan.name),
                  subtitle: Text('${plan.exercises.length} Übungen'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RunnerScreen(plan: plan),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: RunnerStatusBottomBar(controller: runner),
    );
  }
}
