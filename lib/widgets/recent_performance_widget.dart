import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'exercise_helper.dart';

class RecentPerformanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        final workouts =
            provider.workouts + provider.downloadedPlans; // Merge both lists

        // If no workouts are available, display the updated message "No workout done"
        if (workouts.isEmpty) {
          return _buildCard('No workout done.');
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
          bool isWorkoutToday = isSameDay(workoutDate, today);

          if (workoutDate.isAfter(sevenDaysAgo)) {
            for (var exerciseResult in workout.exerciseResults) {
              int? target = getTargetForExercise(
                      exerciseResult.name, exerciseResult.type) ??
                  0;

              totalExercisesLast7Days++;

              if (exerciseResult.achievedOutput >= target) {
                exercisesMeetingTargetLast7Days++;
              }

              if (isWorkoutToday) {
                totalExercisesToday++;

                if (exerciseResult.achievedOutput >= target) {
                  exercisesMeetingTargetToday++;
                }
              }
            }
          }
        }

        // Calculate and format performance scores
        String displayOverallPerformanceScore = _formatScore(
            exercisesMeetingTargetLast7Days, totalExercisesLast7Days);
        String displayDailyPerformanceScore =
            _formatScore(exercisesMeetingTargetToday, totalExercisesToday);

        return _buildPerformanceCard(
          overallScore: displayOverallPerformanceScore,
          dailyScore: displayDailyPerformanceScore,
        );
      },
    );
  }

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Format the performance score to be user-friendly
  String _formatScore(int achieved, int total) {
    if (total == 0) return '0';
    return (achieved / total).toStringAsFixed(2);
  }

  // Widget for displaying the performance card
  Widget _buildPerformanceCard(
      {required String overallScore, required String dailyScore}) {
    return SingleChildScrollView(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Overall Score: $overallScore'),
              Divider(),
              Text('Today\'s Score: $dailyScore'),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for displaying a message when no workouts are available
  Widget _buildCard(String message) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
