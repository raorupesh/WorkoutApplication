import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WorkoutDetailsBasePage extends StatefulWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;
  final bool isCompetitive; // True = Competitive, False = Collaborative

  const WorkoutDetailsBasePage({
    Key? key,
    required this.workoutCode,
    required this.workoutData,
    required this.isCompetitive,
  }) : super(key: key);

  @override
  _WorkoutDetailsBasePageState createState() => _WorkoutDetailsBasePageState();
}

class _WorkoutDetailsBasePageState extends State<WorkoutDetailsBasePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _exerciseProgress = [];

  @override
  void initState() {
    super.initState();
    _initializeExerciseProgress();
  }

  void _initializeExerciseProgress() {
    final exercises = widget.workoutData['exercises'] as List<dynamic>;
    _exerciseProgress = exercises.map((exercise) => {
      'name': exercise['name'],
      'targetOutput': exercise['targetOutput'],
      'type': exercise['type'],
      'completed': false,
      'userProgress': [], // Stores individual user inputs
    }).toList();
  }

  Future<void> _updateExerciseProgress(int index, int output) async {
    String userId = _auth.currentUser!.uid;

    setState(() {
      _exerciseProgress[index]['userProgress'].add({
        'userId': userId,
        'output': output,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (widget.isCompetitive) {
        // In Competitive mode, check only the individual completion
        int totalUserOutput = _exerciseProgress[index]['userProgress']
            .where((entry) => entry['userId'] == userId)
            .fold(0, (sum, entry) => sum + entry['output']);

        _exerciseProgress[index]['completed'] = totalUserOutput >= _exerciseProgress[index]['targetOutput'];
      } else {
        // In Collaborative mode, sum all users' outputs
        int totalGroupOutput = _exerciseProgress[index]['userProgress']
            .fold(0, (sum, entry) => sum + entry['output']);

        _exerciseProgress[index]['completed'] = totalGroupOutput >= _exerciseProgress[index]['targetOutput'];
      }
    });

    // Save to Firestore
    await _firestore
        .collection('workout_sessions')
        .doc(widget.workoutCode)
        .collection('participant_progress')
        .add({
      'userId': userId,
      'exerciseName': _exerciseProgress[index]['name'],
      'output': output,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCompetitive ? 'Competitive Workout' : 'Collaborative Workout'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/workoutPlanSelection'),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text(
            "Workout Code: ${widget.workoutCode}",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          QrImageView(
            data: widget.workoutCode,
            size: 200,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _exerciseProgress.length,
              itemBuilder: (context, index) {
                final exercise = _exerciseProgress[index];
                return Card(
                  child: ListTile(
                    title: Text(exercise['name']),
                    subtitle: Text(
                        "Target: ${exercise['targetOutput']} ${exercise['type']}"),
                    trailing: exercise['completed']
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                      onPressed: () async {
                        int output = await _showInputDialog(context, exercise['type']);
                        if (output > 0) {
                          await _updateExerciseProgress(index, output);
                        }
                      },
                      child: Text('Submit'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _showInputDialog(BuildContext context, String type) async {
    int input = 0;
    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter your $type output"),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) => input = int.tryParse(value) ?? 0,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, input),
              child: Text("Submit"),
            ),
          ],
        );
      },
    ) ?? 0;
  }
}
