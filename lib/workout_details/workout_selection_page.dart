import 'package:flutter/material.dart';
import 'workout_recording_page.dart';
import 'download_workout_page.dart';
import '../widgets/recent_performance_widget.dart'; // Import the RecentPerformanceWidget

class WorkoutPlanSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Workout Plan"),
        centerTitle: true,
      ),
      body: Stack( // Use Stack to position the widget at the bottom
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Standard Plan Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutRecordingPage(),
                      ),
                    );
                  },
                  child: Text("Standard Plan"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.teal,
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                // Download Workout Plan Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DownloadWorkoutPage(),
                      ),
                    );
                  },
                  child: Text("Download Workout Plan"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.teal,
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
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
                child: RecentPerformanceWidget(), // The widget you want to add
              ),
            ),
          ),
        ],
      ),
    );
  }
}
