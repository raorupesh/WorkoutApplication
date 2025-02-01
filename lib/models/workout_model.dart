class Workout {
  final String date; // Date when the workout was recorded
  final List<Exercise> exercises;
  final List<ExerciseResult> exerciseResults;

  Workout({required this.date,
    required this.exercises, required this.exerciseResults,});
}

class Exercise {
  final String name;
  final String type;
  final int targetOutput; // 'seconds', 'reps', 'meters'

  Exercise(this.name, this.type, this.targetOutput);
}

class ExerciseResult {
  final String name;
  final String type;
  final int achievedOutput; // The value entered by the user (e.g., seconds, reps, meters)

  ExerciseResult(this.name, this.type, this.achievedOutput);
}
