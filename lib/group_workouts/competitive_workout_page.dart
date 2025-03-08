import 'package:flutter/material.dart';

import 'group_workout_base_page.dart';

class CompetitiveWorkoutDetailsPage extends StatelessWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;

  const CompetitiveWorkoutDetailsPage({
    Key? key,
    required this.workoutCode,
    required this.workoutData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WorkoutDetailsBasePage(
      workoutCode: workoutCode,
      workoutData: workoutData,
      isCompetitive: true, // Competitive Mode
    );
  }
}
