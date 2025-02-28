import 'package:flutter/material.dart';

import '../widgets/recent_performance_widget.dart';

class JoinWorkoutPage extends StatefulWidget {
  @override
  _JoinWorkoutPageState createState() => _JoinWorkoutPageState();
}

class _JoinWorkoutPageState extends State<JoinWorkoutPage> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _joinWorkout() {
    final url = _urlController.text;
    if (url.isNotEmpty) {
      // Handle the URL (You could validate and join the workout with the URL here)
      print('Joining workout with URL: $url');
      // You could navigate to a new page or show a success message
    } else {
      // Show a message if the URL is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a URL to join the workout')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Workout'),
        centerTitle: true,
        backgroundColor: Colors.teal, // Changed app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the URL to join a workout:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[800]), // Enhanced text style
            ),
            SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Workout URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners for input
                  borderSide: BorderSide(color: Colors.teal), // Border color
                ),
                focusedBorder: OutlineInputBorder( // Focused border style
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Increased padding
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Make button full width
              child: ElevatedButton(
                onPressed: _joinWorkout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Join Workout',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), // Enhanced text style
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Button color
                  foregroundColor: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners for button
                  ),
                  elevation: 5, // Add elevation for a raised effect
                  shadowColor: Colors.teal, // Shadow color
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)), // Add a subtle top border
          ),
          child: RecentPerformanceWidget(),
        ),
      ),
    );
  }
}