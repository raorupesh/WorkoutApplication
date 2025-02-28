import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/workout_model.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  // Constructor to receive the workout from the previous page
  const WorkoutDetailsPage({required this.workout, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // Replaces Navigator.pop()
        ),
      ),
      body: workout.exercises.isEmpty
          ? Center(child: Text('No exercises completed'))
          : ListView.builder(
              itemCount: workout.exercises.length,
              itemBuilder: (context, index) {
                final exercise = workout.exercises[index];
                final exerciseResult = workout.exerciseResults.length > index
                    ? workout.exerciseResults[index]
                    : null; // Safe check in case exerciseResults is shorter than exercises

                bool isCompleted = exerciseResult != null &&
                    exerciseResult.achievedOutput >= exercise.targetOutput;

                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target: ${exercise.targetOutput} ${exercise.type}'),
                      exerciseResult != null
                          ? Text(
                              'Achieved: ${exerciseResult.achievedOutput} ${exercise.type}')
                          : Text('No result available'),
                      Text(
                        isCompleted
                            ? 'Status: Completed'
                            : 'Status: Incomplete',
                        style: TextStyle(
                          color: isCompleted ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
