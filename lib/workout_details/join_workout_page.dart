import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/recent_performance_widget.dart';

class JoinWorkoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Workout'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Workout Mode',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            // Collaborative Workout Button
            _buildModeButton(
              context,
              title: 'Collaborative Workout',
              description: 'Work together with a team',
              icon: Icons.group,
              onPressed: () {
                // Navigate to collaborative workout code entry
                context.push('/collaborativeWorkoutCode');
              },
            ),

            SizedBox(height: 20),

            // Competitive Workout Button
            _buildModeButton(
              context,
              title: 'Competitive Workout',
              description: 'Challenge others in real-time',
              icon: Icons.sports_score,
              onPressed: () {
                // Navigate to competitive workout code entry
                context.push('/competitiveWorkoutCode');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          height: 80,
          child: RecentPerformanceWidget(),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        side: BorderSide(color: Colors.teal, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        elevation: 5,
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.teal),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.teal),
        ],
      ),
    );
  }
}
