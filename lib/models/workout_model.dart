class Workout {
  final String workoutName;
  final String date;
  final List<Exercise> exercises;
  final List<ExerciseResult> exerciseResults;

  Workout({
    required this.workoutName,
    required this.date,
    required this.exercises,
    this.exerciseResults = const [],
  });
  /// Factory method to create a Workout from JSON
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      workoutName: json['name'] ?? "Unnamed Workout",
      date: DateTime.now().toIso8601String(),
      exercises: (json['exercises'] as List?)?.map((exercise) => Exercise.fromJson(exercise)).toList() ?? [],
      exerciseResults: (json['exerciseResults'] as List?)?.map((result) => ExerciseResult.fromJson(result)).toList() ?? [], // Parse exerciseResults if available
    );
  }
}

class Exercise {
  final String name;
  final int targetOutput;
  final String type;

  Exercise({required this.name, required this.targetOutput, required this.type});
  /// Factory method to create Exercise from JSON
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? "Unknown",
      targetOutput: json['target'] ?? 0,
      type: json['unit'] ?? "",
    );
  }
}

class ExerciseResult {
  final String name;
  final int achievedOutput;
  final String type;
  ExerciseResult({required this.name, required this.achievedOutput, this.type = ""});

  /// Factory method to create ExerciseResult from JSON
  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      name: json['name'] ?? "Unknown",
      achievedOutput: json['output'] ?? 0,
      type: json.containsKey('type') ? json['type'] : json['unit'],
    );
  }
}