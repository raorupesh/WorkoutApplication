import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/workout_details/workout_details_page.dart';
import '../main.dart';
import '../widgets/recent_performance_widget.dart'; // Import recent performance widget
import 'workout_recording_page.dart'; // Import the WorkoutRecordingPage

class WorkoutHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = Provider.of<WorkoutProvider>(context).workouts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
        centerTitle: true, // Center the title as in your example
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
          SizedBox(height: 10), // Space between text and the list
          Expanded(
            child: Stack(
              children: [
                // Display workout history or empty state
                workouts.isEmpty
                    ? Center(child: Text('No workouts recorded yet.'))
                    : ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        title: Text(
                          DateFormat('yyyy-MM-dd h:mm a')
                              .format(DateTime.parse(workout.date)),
                        ),
                        subtitle: Text(
                          'Total Exercises: ${workout.exercises.length}',
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_rounded, // Arrow icon for navigation
                          size: 18,
                        ),
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

                // Recent Performance Widget in bottom-left corner
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: 150, // Set the width to make it smaller
                      height: 90, // Set the height to make it smaller
                      decoration: BoxDecoration(
                        color: Colors.teal.shade200,
                        borderRadius: BorderRadius.circular(12), // Optional: Rounded corners
                      ),
                      child: RecentPerformanceWidget(), // Your custom widget here
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Button to add new workout
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutRecordingPage(),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal, // Set button color
      ),
    );
  }
}
