import 'package:flutter/material.dart';
import 'package:fitness_workout/fitness_workout.dart';

class Results extends StatelessWidget {
  final Future<void> Function()? onFinish;
  const Results({super.key, this.onFinish});

  @override
  Widget build(BuildContext context) {
    final performedExercises = runner.state?.performed ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Ergebnisse")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: performedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = performedExercises[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseIndex.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...exercise.sets.map((set) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              'Weight: ${set.actualWeight} kg, Reps: ${set.actualReps}, RIR: ${set.rir}',
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: onFinish,
              child: const Text('Finish Workout'),
            ),
          ],
        ),
      ),
    );
  }
}
