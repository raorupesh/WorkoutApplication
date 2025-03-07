import 'package:flutter/material.dart';
import 'group_workout_base_page.dart';

class CollaborativeWorkoutDetailsPage extends StatelessWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;

  const CollaborativeWorkoutDetailsPage({
    Key? key,
    required this.workoutCode,
    required this.workoutData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WorkoutDetailsBasePage(
      workoutCode: workoutCode,
      workoutData: workoutData,
      isCompetitive: false, // Collaborative Mode
    );
  }
}
