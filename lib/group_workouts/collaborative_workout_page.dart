import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CollaborativeWorkoutDetailsPage extends StatefulWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;

  const CollaborativeWorkoutDetailsPage({
    Key? key,
    required this.workoutCode,
    required this.workoutData,
  }) : super(key: key);

  @override
  _CollaborativeWorkoutDetailsPageState createState() =>
      _CollaborativeWorkoutDetailsPageState();
}

class _CollaborativeWorkoutDetailsPageState
    extends State<CollaborativeWorkoutDetailsPage> {
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
    _exerciseProgress = exercises
        .map((exercise) => {
              'name': exercise['name'],
              'targetOutput': exercise['targetOutput'],
              'type': exercise['type'],
              'completed': false,
              'userProgress': [],
            })
        .toList();
  }

  Future<void> _updateExerciseProgress(int index) async {
    setState(() {
      _exerciseProgress[index]['userProgress'].add({
        'userId': _auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (_exerciseProgress[index]['userProgress'].length >= 1) {
        _exerciseProgress[index]['completed'] = true;
      }
    });

    await _firestore
        .collection('workout_sessions')
        .doc(widget.workoutCode)
        .collection('participant_progress')
        .add({
      'userId': _auth.currentUser!.uid,
      'exerciseName': _exerciseProgress[index]['name'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Collaborative Workout'),
          leading: IconButton(
          icon: Icon(Icons.arrow_back),
      onPressed: () => context.go('/workoutPlanSelection'),
    ),),
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
                            onPressed: () => _updateExerciseProgress(index),
                            child: Text('Complete'),
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
}
