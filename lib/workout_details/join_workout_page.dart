import 'package:flutter/material.dart';

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the URL to join a workout:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Workout URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinWorkout,
              child: Text('Join Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Button color
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
