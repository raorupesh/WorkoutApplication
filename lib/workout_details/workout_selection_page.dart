import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../firebase_validations/workout_code_validation.dart';
import '../main.dart';
import '../models/workout_model.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutPlanSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final downloadedPlans =
        Provider.of<WorkoutProvider>(context).downloadedPlans;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/workoutHistory'),
        ),
        title: Text("Workout Selection"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose Your Workout",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            SizedBox(height: 20),

            // Standard Workout Selection
            GestureDetector(
              onTap: () => context.go('/standardWorkoutRecording'),
              child:
                  _buildWorkoutCard(Icons.fitness_center, "Standard Workout"),
            ),
            SizedBox(height: 20),

            // Download Workout Button
            ElevatedButton.icon(
              onPressed: () => context.go('/downloadWorkout'),
              icon: Icon(Icons.download, size: 24),
              label:
                  Text("Download Workout Plan", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),

            // Downloaded Workouts List
            Text(
              "Downloaded Workouts",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            SizedBox(height: 10),

            Expanded(
              child: downloadedPlans.isEmpty
                  ? Center(
                      child: Text("No downloaded plans yet.",
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      itemCount: downloadedPlans.length,
                      itemBuilder: (context, index) {
                        final plan = downloadedPlans[index];
                        return _buildDownloadedWorkoutCard(context, plan);
                      },
                    ),
            ),

            SizedBox(height: 10),
            RecentPerformanceWidget(),
          ],
        ),
      ),
    );
  }

  /// Build Standard Workout Card
  Widget _buildWorkoutCard(IconData icon, String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: Colors.teal),
                SizedBox(width: 16),
                Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900)),
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.teal),
          ],
        ),
      ),
    );
  }

  /// Build Downloaded Workout Card
  Widget _buildDownloadedWorkoutCard(BuildContext context, Workout plan) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.teal.shade50,
      child: ListTile(
        title: Text(plan.workoutName,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
        subtitle: Text("${plan.exercises.length} exercises"),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.teal),
        onTap: () => _showWorkoutModeDialog(context, plan),
      ),
    );
  }

  /// Show Workout Mode Selection Dialog
  void _showWorkoutModeDialog(BuildContext context, Workout plan) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Choose Workout Mode"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(context, Icons.person, "Solo Workout", () {
                Navigator.pop(context);
                context.go('/downloadedWorkoutInput', extra: plan);
              }),
              _buildDialogOption(context, Icons.group, "Collaborative Workout",
                  () async {
                Navigator.pop(context);
                await _startCollaborativeWorkout(context, plan);
              }),
              _buildDialogOption(
                  context, Icons.sports_score, "Competitive Workout", () async {
                Navigator.pop(context);
                await _startCompetitiveWorkout(context, plan);
              }),
            ],
          ),
        );
      },
    );
  }

  /// Build Workout Mode Option for Dialog
  Widget _buildDialogOption(
      BuildContext context, IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(text),
      onTap: onTap,
    );
  }

  /// Start Collaborative Workout with Code Generation
  Future<void> _startCollaborativeWorkout(
      BuildContext context, Workout plan) async {
    try {
      String workoutCode = await _generateWorkoutCode("collaborative");
      context.go('/collaborativeWorkoutDetails', extra: {
        'code': workoutCode,
        'workoutData': plan.toJson(),
      });
    } catch (e) {
      _showErrorDialog(context, "Error starting collaborative workout: $e");
    }
  }

  /// Start Competitive Workout with Code Generation
  Future<void> _startCompetitiveWorkout(
      BuildContext context, Workout plan) async {
    try {
      String workoutCode = await _generateWorkoutCode("competitive");
      context.go('/competitiveWorkoutDetails', extra: {
        'code': workoutCode,
        'workoutData': plan.toJson(),
      });
    } catch (e) {
      _showErrorDialog(context, "Error starting competitive workout: $e");
    }
  }

  /// Generate a 6-digit workout code for Collaborative/Competitive workouts
  Future<String> _generateWorkoutCode(String type) async {
    final workoutCodeService = WorkoutCodeService();
    return await workoutCodeService.createWorkoutCode(
      workoutType: type,
      maxParticipants: (type == "collaborative") ? 5 : 10,
    );
  }

  /// Show Error Dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}
