class Workout {
  final String date; // Date when the workout was recorded
  final List<ExerciseResult> exercises;

  Workout({
    required this.date,
    required this.exercises,
  });
}

class Exercise {
  final String name;
  final String type; // 'seconds', 'reps', 'meters'

  Exercise(this.name, this.type);
}

class ExerciseResult {
  final String name;
  final String type;
  final int
      output; // The value entered by the user (e.g., seconds, reps, meters)

  ExerciseResult(this.name, this.type, this.output);
}
