import 'group_workout_models.dart';

class Workout {
  final String workoutName;
  final String date;
  final List<Exercise> exercises;
  final List<ExerciseResult> exerciseResults;
  final String type; // 'solo', 'collaborative', or 'competitive'

  Workout({
    required this.workoutName,
    required this.date,
    required this.exercises,
    this.exerciseResults = const [],
    this.type = 'solo',
  });

  Map<String, dynamic> toJson() {
    return {
      'workoutName': workoutName,
      'date': date,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'exerciseResults': exerciseResults.map((r) => r.toJson()).toList(),
      'type': type,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      workoutName: json['workoutName'] ?? json['name'] ?? "Unnamed Workout",
      date: json['date'] ?? DateTime.now().toIso8601String(),
      exercises: (json['exercises'] as List?)
          ?.map((e) => Exercise.fromJson(e))
          .toList() ??
          [],
      exerciseResults: (json['exerciseResults'] as List?)
          ?.map((r) => ExerciseResult.fromJson(r))
          .toList() ??
          [],
      type: json['type'] ?? 'solo',
    );
  }

  ExerciseResult? getExerciseResult(String exerciseName) {
    return exerciseResults.firstWhere(
          (result) => result.name == exerciseName,
      orElse: () => ExerciseResult(name: exerciseName, achievedOutput: 0, type: ''),
    );
  }

  factory Workout.fromGroupWorkout(GroupWorkout groupWorkout) {
    return Workout(
      workoutName: groupWorkout.workoutName,
      date: DateTime.now().toIso8601String(),
      exercises: groupWorkout.exercises
          .map((e) => Exercise(
        name: e.name,
        targetOutput: e.targetOutput,
        type: e.type,
      ))
          .toList(),
      type: groupWorkout.isCompetitive ? 'competitive' : 'collaborative',
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target': targetOutput,
      'unit': type,
    };
  }

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

  ExerciseResult({
    required this.name,
    required this.achievedOutput,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'output': achievedOutput,
      'unit': type,
    };
  }

  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      name: json['name'] ?? "Unknown",
      achievedOutput: json['output'] ?? 0,
      type: json['unit'] ?? "",
    );
  }
}
