import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'exercise_helper.dart'; // Import the helper function

class RecentPerformanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = Provider.of<WorkoutProvider>(context).workouts;

    // Get the date 7 days ago and today
    DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    DateTime today = DateTime.now();

    // Initialize counters for the overall last 7 days performance
    int totalExercisesLast7Days = 0,
        exercisesMeetingTargetLast7Days = 0,
        totalExercisesToday = 0,
        exercisesMeetingTargetToday = 0;

    // Calculate performance for the last 7 days and today's performance
    for (var workout in workouts) {
      DateTime workoutDate = DateTime.parse(workout.date);

      // Only consider workouts from the last 7 days
      if (workoutDate.isAfter(sevenDaysAgo)) {
        for (var exerciseResult in workout.exercises) {
          int target =
              getTargetForExercise(exerciseResult.name, exerciseResult.type);

          // If it's within the last 7 days
          totalExercisesLast7Days++;

          // Check if the exercise meets the target for last 7 days
          if (exerciseResult.output >= target) {
            exercisesMeetingTargetLast7Days++;
          }

          // If it's today
          if (isSameDay(workoutDate, today)) {
            totalExercisesToday++;

            // Check if the exercise meets the target for today
            if (exerciseResult.output >= target) {
              exercisesMeetingTargetToday++;
            }
          }
        }
      }
    }

    // Calculate the performance score for the past 7 days
    double performanceScore =
        (totalExercisesLast7Days > 0 && exercisesMeetingTargetLast7Days > 0)
            ? (exercisesMeetingTargetLast7Days / totalExercisesLast7Days)
            : 0;

    // Calculate today's performance score
    double todaysPerformanceScore =
        (totalExercisesToday > 0 && exercisesMeetingTargetToday > 0)
            ? (exercisesMeetingTargetToday / totalExercisesToday)
            : 0;

    // Format the scores to be more user-friendly
    String displayPerformanceScore =
        performanceScore > 0 ? performanceScore.toStringAsFixed(2) : '0';
    String displayTodaysPerformanceScore = todaysPerformanceScore > 0
        ? todaysPerformanceScore.toStringAsFixed(2)
        : '0';

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Overall Score: $displayPerformanceScore'),
            Divider(), // Add a divider to separate the two scores
            Text('Today\'s Score: $displayTodaysPerformanceScore'),
          ],
        ),
      ),
    );
  }

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
