import 'package:fitness_workout/fitness_workout.dart';

final List<WorkoutExercise> defaultExercises = [
  WorkoutExercise(
    id: '1',
    name: 'Bankdrücken',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Brust'),
          Muscle.findByName('Trizeps'),
          Muscle.findByName('Schultern'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '2',
    name: 'Kniebeugen',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Quadrizeps'),
          Muscle.findByName('Gluteus'),
          Muscle.findByName('Hamstrings'),
          Muscle.findByName('Waden'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '3',
    name: 'Kreuzheben',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Rücken'),
          Muscle.findByName('Hamstrings'),
          Muscle.findByName('Gluteus'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '4',
    name: 'Overhead Press (OHP)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Schultern'),
          Muscle.findByName('Trizeps'),
          Muscle.findByName('Oberkörper'), // This will be safely ignored
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '5',
    name: 'Klimmzüge',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Rücken'),
          Muscle.findByName('Bizeps'),
          Muscle.findByName('Schultern'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '6',
    name: 'Langhantelrudern',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Rücken'),
          Muscle.findByName('Bizeps'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '7',
    name: 'Dips',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Trizeps'),
          Muscle.findByName('Brust'),
          Muscle.findByName('Schultern'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '8',
    name: 'Bizepscurls (Langhantel)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles: [Muscle.findByName('Bizeps')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '9',
    name: 'Seitheben',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles: [Muscle.findByName('Schultern')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '10',
    name: 'Beinpresse',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Quadrizeps'),
          Muscle.findByName('Gluteus'),
          Muscle.findByName('Hamstrings'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '11',
    name: 'Ausfallschritte',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Quadrizeps'),
          Muscle.findByName('Gluteus'),
          Muscle.findByName('Hamstrings'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '12',
    name: 'Beincurls (Maschine)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles: [Muscle.findByName('Hamstrings')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '13',
    name: 'Wadenheben',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles: [Muscle.findByName('Waden')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '14',
    name: 'Crunches',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Core'),
    muscles: [Muscle.findByName('Bauch')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '15',
    name: 'Plank',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Core'),
    muscles:
        [
          Muscle.findByName('Bauch'),
          Muscle.findByName('Rücken'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '16',
    name: 'Russian Twists',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Core'),
    muscles: [Muscle.findByName('Bauch')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '17',
    name: 'Burpees',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('HIIT'),
    muscles:
        [
          Muscle.findByName('Quadrizeps'),
          Muscle.findByName('Brust'),
          Muscle.findByName('Schultern'),
          Muscle.findByName('Bauch'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '18',
    name: 'Seilspringen',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Cardio'),
    muscles:
        [
          Muscle.findByName('Waden'),
          Muscle.findByName('Quadrizeps'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '19',
    name: 'Laufen',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Cardio'),
    muscles:
        [
          Muscle.findByName('Beine'), // This will be safely ignored
          Muscle.findByName('Quadrizeps'),
          Muscle.findByName('Hamstrings'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '20',
    name: 'Yoga – Sonnengruß',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Beweglichkeit'),
    muscles:
        [
          Muscle.findByName('Bauch'),
          Muscle.findByName('Rücken'),
          Muscle.findByName('Schultern'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '21',
    name: 'Schrägbankdrücken (Kurzhantel)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Brust'),
          Muscle.findByName('Schultern'),
          Muscle.findByName('Trizeps'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '22',
    name: 'Rudern am Kabelzug',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Rücken'),
          Muscle.findByName('Bizeps'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '23',
    name: 'Beinstrecker (Maschine)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles: [Muscle.findByName('Quadrizeps')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '24',
    name: 'Hip Thrusts',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Gluteus'),
          Muscle.findByName('Hamstrings'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '25',
    name: 'Trizepsdrücken am Kabelzug',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles: [Muscle.findByName('Trizeps')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '26',
    name: 'Hammercurls',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles: [Muscle.findByName('Bizeps')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '27',
    name: 'Butterfly (Maschine)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles: [Muscle.findByName('Brust')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '28',
    name: 'Latzug',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Rücken'),
          Muscle.findByName('Bizeps'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '29',
    name: 'Beinheben (hängend)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Core'),
    muscles: [Muscle.findByName('Bauch')].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '30',
    name: 'Fahrradfahren (Ergometer)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Cardio'),
    muscles:
        [
          Muscle.findByName('Quadrizeps'),
          Muscle.findByName('Waden'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '31',
    name: 'Good Mornings',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Hamstrings'),
          Muscle.findByName('Rücken'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '32',
    name: 'Face Pulls',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Schultern'),
          Muscle.findByName('Rücken'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '33',
    name: 'Liegestütze',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Brust'),
          Muscle.findByName('Trizeps'),
          Muscle.findByName('Bauch'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '34',
    name: 'Kettlebell Swings',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('HIIT'),
    muscles:
        [
          Muscle.findByName('Gluteus'),
          Muscle.findByName('Hamstrings'),
          Muscle.findByName('Rücken'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '35',
    name: 'Statisches Dehnen',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Beweglichkeit'),
    muscles: [], // Intentionally empty
  ),
  WorkoutExercise(
    id: '36',
    name: 'Box Jumps',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('HIIT'),
    muscles:
        [
          Muscle.findByName('Quadrizeps'),
          Muscle.findByName('Gluteus'),
          Muscle.findByName('Waden'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '37',
    name: 'Frontkniebeugen',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Quadrizeps'),
          Muscle.findByName('Gluteus'),
          Muscle.findByName('Bauch'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '38',
    name: 'Hyperextensions',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Krafttraining'),
    muscles:
        [
          Muscle.findByName('Rücken'),
          Muscle.findByName('Gluteus'),
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '39',
    name: 'Battle Ropes',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('HIIT'),
    muscles:
        [
          Muscle.findByName('Schultern'),
          Muscle.findByName('Arme'), // This will be safely ignored
        ].whereType<Muscle>().toList(),
  ),
  WorkoutExercise(
    id: '40',
    name: 'Rudern (Maschine)',
    sets: WorkoutExercise.generateRandomSets(),
    category: ExerciseCategorie.findByName('Cardio'),
    muscles:
        [
          Muscle.findByName('Rücken'),
          Muscle.findByName('Beine'), // This will be safely ignored
          Muscle.findByName('Arme'), // This will be safely ignored
        ].whereType<Muscle>().toList(),
  ),
];
