import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../firebase_validations/workout_code_validation.dart';
import '../widgets/recent_performance_widget.dart';

class JoinCollaborativeWorkoutCodePage extends StatefulWidget {
  @override
  _JoinCollaborativeWorkoutCodePageState createState() =>
      _JoinCollaborativeWorkoutCodePageState();
}

class _JoinCollaborativeWorkoutCodePageState
    extends State<JoinCollaborativeWorkoutCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final WorkoutCodeService _codeService = WorkoutCodeService();
  bool _isLoading = false;

  Future<void> _validateAndProceed() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final workoutData = await _codeService.validateWorkoutCode(
          _codeController.text, 'collaborative');

      if (workoutData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid or expired workout code')),
        );
      } else {
        // Navigate to collaborative workout details
        context.push('/collaborativeWorkoutDetails',
            extra: {'code': _codeController.text, 'workoutData': workoutData});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error validating code: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Collaborative Workout'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: '6-Digit Workout Code',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, letterSpacing: 10),
            ),
            SizedBox(height: 30),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _validateAndProceed,
                    child: Text('Join Workout'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
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
          child: RecentPerformanceWidget(),
        ),
      ),
    );
  }
}
