import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      print('Joining workout with URL: $url');

      // Navigate back to the workout selection page
      context.go('/workout-selection');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a URL to join the workout')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Workout'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the URL to join a workout:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                backgroundColor: Colors.teal,
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
