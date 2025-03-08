import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';

class GroupWorkout {
  final String workoutCode;
  final String workoutName;
  final List<GroupExercise> exercises;
  final bool isCompetitive;
  final List<String> participants;
  final Timestamp? createdAt;

  GroupWorkout({
    required this.workoutCode,
    required this.workoutName,
    required this.exercises,
    required this.isCompetitive,
    required this.participants,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'workoutCode': workoutCode,
      'workoutName': workoutName,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'isCompetitive': isCompetitive,
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static GroupWorkout fromMap(Map<String, dynamic> map) {
    return GroupWorkout(
      workoutCode: map['workoutCode'],
      workoutName: map['workoutName'],
      isCompetitive: map['isCompetitive'],
      participants: List<String>.from(map['participants']),
      exercises: (map['exercises'] as List)
          .map((e) => GroupExercise.fromMap(e))
          .toList(),
      createdAt: map['createdAt'],
    );
  }

  // Convert to Workout model for display in history
  Workout toWorkout() {
    return Workout(
      workoutName: workoutName,
      date: createdAt?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      exercises: exercises.map((groupExercise) =>
          Exercise(
              name: groupExercise.name,
              targetOutput: groupExercise.targetOutput,
              type: groupExercise.type
          )
      ).toList(),
      type: isCompetitive ? 'competitive' : 'collaborative',
    );
  }
}

class GroupExercise {
  final String name;
  final int targetOutput;
  final String type;

  GroupExercise({
    required this.name,
    required this.targetOutput,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetOutput': targetOutput,
      'type': type,
    };
  }

  static GroupExercise fromMap(Map<String, dynamic> map) {
    return GroupExercise(
      name: map['name'] ?? '',
      targetOutput: map['targetOutput'] ?? 0,
      type: map['type'] ?? '',
    );
  }
}