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

  /// Convert Workout instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'workoutName': workoutName,
      'date': date,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'exerciseResults': exerciseResults.map((r) => r.toJson()).toList(),
    };
  }

  /// Factory method to create a Workout from JSON
  factory Workout.fromJson(Map<String, dynamic> json) {
    print("Workout JSON: $json"); // Debugging

    return Workout(
      workoutName: json['name'] ?? "Unnamed Workout",
      date: DateTime.now().toIso8601String(),
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((exercise) => Exercise.fromJson(exercise))
          .toList() ??
          [],
    );
  }

}

class Exercise {
  final String name;
  final int targetOutput;
  final String type;

  Exercise(
      {required this.name, required this.targetOutput, required this.type});

  /// Convert Exercise instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'targetOutput': targetOutput,
      'type': type,
    };
  }

  /// Create Exercise from JSON
  factory Exercise.fromJson(Map<String, dynamic> json) {
    print("Parsing Exercise JSON: $json"); // Debugging

    return Exercise(
      name: json['name'] ?? "Unknown",
      targetOutput: json['target'] ?? 0,
      type: json['unit'] ?? "", // This should match the API response
    );
  }

}

class ExerciseResult {
  final String name;
  final int achievedOutput;
  final String type;

  ExerciseResult(
      {required this.name, required this.achievedOutput, required this.type});

  /// Convert ExerciseResult instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'achievedOutput': achievedOutput,
      'type': type,
    };
  }

  /// Create ExerciseResult from JSON
  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      name: json['name'] ?? "Unknown",
      achievedOutput: json['achievedOutput'] ?? 0,
      type: json['type'] ?? "",
    );
  }
}
