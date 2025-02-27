import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/recent_performance_widget.dart';
import 'workout_details_page.dart';
import 'workout_selection_page.dart';
import 'join_workout_page.dart'; // Add this import

class WorkoutHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = Provider.of<WorkoutProvider>(context).workouts;

    // Sort workouts in descending order (newest first)
    workouts.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Daily Progress Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: workouts.isEmpty
                ? Center(child: Text('No workouts recorded yet.'))
                : ListView.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                final completedExercises = workout.exerciseResults
                    .where((result) =>
                result.achievedOutput >=
                    workout.exercises[index].targetOutput)
                    .length;
                final incompleteExercises =
                    workout.exerciseResults.length - completedExercises;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                      DateFormat('yyyy-MM-dd h:mm a')
                          .format(DateTime.parse(workout.date)),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed: $completedExercises'),
                        Text('Incomplete: $incompleteExercises'),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_rounded, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutDetailsPage(workout),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Add a Column for the buttons aligned to the right
          Align(
            alignment: Alignment.centerRight, // Align the buttons to the right
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0), // Add some right padding for spacing
              child: Column(
                children: [
                  // Existing button for selecting workout plan
                  Tooltip(
                    message: 'Select Workout Plan',  // Hover text
                    child: AnimatedOpacity(
                      opacity: 1.0,  // Add transition opacity effect if needed
                      duration: Duration(milliseconds: 300),
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkoutPlanSelectionPage(),
                            ),
                          );
                        },
                        child: Icon(Icons.add),
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ),
                  SizedBox(height: 10), // Space between buttons
                  // New button for joining workout
                  Tooltip(
                    message: 'Join Workout',  // Hover text
                    child: AnimatedOpacity(
                      opacity: 1.0,  // Add transition opacity effect if needed
                      duration: Duration(milliseconds: 300),
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinWorkoutPage(),
                            ),
                          );
                        },
                        child: Icon(Icons.link),
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add RecentPerformanceWidget below the buttons
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
}
