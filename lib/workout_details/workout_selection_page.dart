import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/workout_details/standard_workout_recording_page.dart';
import 'download_workout_page.dart';
import '../widgets/recent_performance_widget.dart';
import '../main.dart';
import '../models/workout_model.dart';

class WorkoutPlanSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final downloadedPlans = Provider.of<WorkoutProvider>(context).downloadedPlans;

    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Workout Plan"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // The main column with the existing two buttons + a list of downloaded plans
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Existing Standard Plan
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StandardWorkoutRecordingPage()),
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
                // Existing Download Plan button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DownloadWorkoutPage()),
                    );
                  },
                  child: Text("Download Workout Plan"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.teal,
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                // List of previously downloaded plans
                Expanded(
                  child: downloadedPlans.isEmpty
                      ? Center(
                    child: Text(
                      "No downloaded plans yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    itemCount: downloadedPlans.length,
                    itemBuilder: (context, index) {
                      final plan = downloadedPlans[index];
                      return Card(
                        child: ListTile(
                          title: Text(plan.workoutName),
                          subtitle: Text(
                              "${plan.exercises.length} exercises in this plan"),
                          onTap: () {
                            // Navigate to the same recording page, but pass in the plan
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StandardWorkoutRecordingPage(
                                  workoutPlan: plan, // pass the plan
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // The performance widget in the bottom-left corner
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 150,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.teal.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RecentPerformanceWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
