import 'package:flutter/material.dart';

import '../models/workout_model.dart';
import '../widgets/recent_performance_widget.dart'; // Import the workout model to get the Workout and ExerciseResult classes

class WorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  // Constructor to receive the workout from the previous page
  WorkoutDetailsPage(this.workout);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Details'),
      ),
      body: ListView.builder(
        itemCount: workout.exercises.length,
        itemBuilder: (context, index) {
          final exercise = workout.exercises[index];
          return ListTile(
            title: Text(exercise.name),
            subtitle: Text('Output: ${exercise.output} ${exercise.type}'),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          height: 80,
          child: RecentPerformanceWidget(),
        ),
      ),
    );
  }
}
