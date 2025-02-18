import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/recent_performance_widget.dart';
import '../workout_details/standard_workout_recording_page.dart';
import 'download_workout_page.dart';

class WorkoutPlanSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final downloadedPlans =
        Provider.of<WorkoutProvider>(context).downloadedPlans;

    return Scaffold(
      appBar: AppBar(
        title: Text("Workout Selection"),
        centerTitle: true,
        backgroundColor: Colors.teal, // Teal-colored AppBar
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Text(
                    "Choose Your Workout",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  SizedBox(height: 20),

                  // Standard Workout Card (FULLY CLICKABLE)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StandardWorkoutRecordingPage(),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.teal.shade50, // Light Teal Background
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.fitness_center,
                                    size: 40, color: Colors.teal),
                                SizedBox(width: 16),
                                Text(
                                  "Standard Workout",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade900),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 18, color: Colors.teal),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Download Workout Plan Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DownloadWorkoutPage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.download, size: 24),
                    label: Text(
                      "Download Workout Plan",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.teal,
                      // Changed to Teal for Consistency
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Section Title
                  Text(
                    "Downloaded Workouts",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),

                  SizedBox(height: 10),

                  // List of downloaded plans
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
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors
                                    .teal.shade50, // Light Teal Background
                                child: ListTile(
                                  title: Text(plan.workoutName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade900)),
                                  subtitle: Text(
                                      "${plan.exercises.length} exercises"),
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      size: 18, color: Colors.teal),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StandardWorkoutRecordingPage(
                                                workoutPlan: plan),
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
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: RecentPerformanceWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
