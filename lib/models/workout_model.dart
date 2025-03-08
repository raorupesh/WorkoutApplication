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
    print("Parsing Workout JSON: $json"); // Debugging

    return Workout(
      workoutName: json['workoutName'] ?? json['name'] ?? "Unnamed Workout",
      // FIX: Ensure correct key mapping
      date: json['date'] ?? DateTime.now().toIso8601String(),
      exercises: (json['exercises'] as List?)
              ?.map((e) => Exercise.fromJson(e))
              .toList() ??
          [],
      exerciseResults: (json['exerciseResults'] as List?)
              ?.map((r) => ExerciseResult.fromJson(r))
              .toList() ??
          [],
    );
  }

  /// Get Exercise Result by Name (Ensures results match exercises correctly)
  ExerciseResult? getExerciseResult(String exerciseName) {
    return exerciseResults.firstWhere(
      (result) => result.name == exerciseName,
      orElse: () =>
          ExerciseResult(name: exerciseName, achievedOutput: 0, type: ''),
    );
  }
}

class Exercise {
  final String name;
  final int targetOutput;
  final String type;

  Exercise({
    required this.name,
    required this.targetOutput,
    required this.type,
  });

  /// Convert Exercise instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target': targetOutput, // Ensure correct key matching API
      'unit': type, // Ensure correct key matching API
    };
  }

  /// Create Exercise from JSON
  factory Exercise.fromJson(Map<String, dynamic> json) {
    print("Parsing Exercise JSON: $json"); // Debugging

    return Exercise(
      name: json['name'] ?? "Unknown",
      targetOutput: json['target'] ?? 0, // Fix key mismatch
      type: json['unit'] ?? "", // Fix key mismatch
    );
  }
}

class ExerciseResult {
  final String name;
  final int achievedOutput;
  final String type;

  ExerciseResult({
    required this.name,
    required this.achievedOutput,
    required this.type,
  });

  /// Convert ExerciseResult instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'output': achievedOutput, // Fix to match API key
      'unit': type, // Fix to match API key
    };
  }

  /// Create ExerciseResult from JSON
  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    print("Parsing ExerciseResult JSON: $json"); // Debugging

    return ExerciseResult(
      name: json['name'] ?? "Unknown",
      achievedOutput: json['output'] ?? 0, // Fix key mismatch
      type: json['unit'] ?? "", // Fix key mismatch
    );
  }
}
