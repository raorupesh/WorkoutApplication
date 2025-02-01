import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'exercise_helper.dart';

class RecentPerformanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = Provider.of<WorkoutProvider>(context).workouts;

    // If no workouts are available, display the updated message "No workout done"
    if (workouts.isEmpty) {
      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Center( // Center the Column in the middle of the Card
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically in Column
              children: [
                Text(
                  'No workout done.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );

    }

    // Get the date for today and 7 days ago
    DateTime today = DateTime.now();
    DateTime sevenDaysAgo = today.subtract(Duration(days: 7));

    // Initialize counters for overall (last 7 days) and today’s performance
    int totalExercisesLast7Days = 0, exercisesMeetingTargetLast7Days = 0;
    int totalExercisesToday = 0, exercisesMeetingTargetToday = 0;

    // Loop through all workouts and calculate both overall and daily performance
    for (var workout in workouts) {
      DateTime workoutDate = DateTime.parse(workout.date);

      // Calculate for the last 7 days
      if (workoutDate.isAfter(sevenDaysAgo)) {
        for (var exerciseResult in workout.exerciseResults) {
          int target = getTargetForExercise(exerciseResult.name, exerciseResult.type);

          // Count for the last 7 days
          totalExercisesLast7Days++;

          // Check if the exercise meets the target in the last 7 days
          if (exerciseResult.achievedOutput >= target) {
            exercisesMeetingTargetLast7Days++;
          }

          // If the workout is today, count for today’s performance
          if (isSameDay(workoutDate, today)) {
            totalExercisesToday++;

            // Check if the exercise meets the target today
            if (exerciseResult.achievedOutput >= target) {
              exercisesMeetingTargetToday++;
            }
          }
        }
      }
    }

    // Calculate the overall performance score for the past 7 days
    double overallPerformanceScore = 0;
    if (totalExercisesLast7Days > 0) {
      overallPerformanceScore = exercisesMeetingTargetLast7Days / totalExercisesLast7Days;
    }

    // Calculate the daily performance score for today
    double dailyPerformanceScore = 0;
    if (totalExercisesToday > 0) {
      dailyPerformanceScore = exercisesMeetingTargetToday / totalExercisesToday;
    }

    // Format the scores to be more user-friendly
    String displayOverallPerformanceScore = overallPerformanceScore == 0
        ? '0'
        : overallPerformanceScore.toStringAsFixed(2);
    String displayDailyPerformanceScore = dailyPerformanceScore == 0
        ? '0'
        : dailyPerformanceScore.toStringAsFixed(2);

    return SingleChildScrollView( // Wrap the content in SingleChildScrollView
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Overall Score: $displayOverallPerformanceScore'),
              Divider(), // Add a divider to separate the two scores
              Text('Today\'s Score: $displayDailyPerformanceScore'),
            ],
          ),
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
