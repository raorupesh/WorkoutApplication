import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout_model.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  WorkoutDetailsPage(this.workout);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Workout Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Workout Summary Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  workout.workoutName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  DateFormat('MMM dd, yyyy - h:mm a')
                      .format(DateTime.parse(workout.date)),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Exercises List
          Expanded(
            child: workout.exercises.isEmpty
                ? _buildEmptyState()
                : _buildExerciseList(),
          ),

          // Recent Performance Widget
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              height: 80,
              child: RecentPerformanceWidget(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Empty State when there are no exercises
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 100, color: Colors.teal.shade200),
          SizedBox(height: 16),
          Text(
            'No exercises completed',
            style: TextStyle(fontSize: 18, color: Colors.teal.shade400),
          ),
        ],
      ),
    );
  }

  /// Build the Exercise List
  Widget _buildExerciseList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: workout.exercises.length,
      itemBuilder: (context, index) {
        final exercise = workout.exercises[index];
        final exerciseResult =
            workout.getExerciseResult(exercise.name); // Fetch correct result

        bool isCompleted = exerciseResult != null &&
            exerciseResult.achievedOutput >= exercise.targetOutput;

        return _buildExerciseCard(exercise, exerciseResult, isCompleted);
      },
    );
  }

  /// Build Individual Exercise Card
  Widget _buildExerciseCard(
      Exercise exercise, ExerciseResult? result, bool isCompleted) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          exercise.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(Icons.flag,
                'Target: ${exercise.targetOutput} ${exercise.type}'),
            _buildRow(
                Icons.check_circle_outline,
                result != null
                    ? 'Achieved: ${result.achievedOutput} ${result.type}'
                    : 'No result available'),
            SizedBox(height: 8),
            _buildStatusIndicator(isCompleted),
          ],
        ),
      ),
    );
  }

  /// Build Row with an Icon and Text
  Widget _buildRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  /// Build Status Indicator (Completed or Incomplete)
  Widget _buildStatusIndicator(bool isCompleted) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isCompleted ? 'Completed' : 'Incomplete',
        style: TextStyle(
          color: isCompleted ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
