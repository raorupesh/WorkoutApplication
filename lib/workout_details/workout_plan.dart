class WorkoutPlan {
  String name;
  List<Exercise> exercises;

  WorkoutPlan(this.name, this.exercises);
}

class Exercise {
  String name;
  String type; // Can be 'seconds', 'reps', or 'meters'

  Exercise(this.name, this.type);
}
