import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CollaborativeWorkoutDetailsPage extends StatefulWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;

  const CollaborativeWorkoutDetailsPage({
    Key? key,
    required this.workoutCode,
    required this.workoutData
  }) : super(key: key);

  @override
  _CollaborativeWorkoutDetailsPageState createState() => _CollaborativeWorkoutDetailsPageState();
}

class _CollaborativeWorkoutDetailsPageState extends State<CollaborativeWorkoutDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track individual exercise progress
  List<Map<String, dynamic>> _exerciseProgress = [];

  @override
  void initState() {
    super.initState();
    _initializeExerciseProgress();
  }

  void _initializeExerciseProgress() {
    // Assume exercises are in the workout data
    final exercises = widget.workoutData['exercises'] as List<dynamic>;
    _exerciseProgress = exercises.map((exercise) => {
      'name': exercise['name'],
      'sets': exercise['sets'],
      'reps': exercise['reps'],
      'completed': false,
      'userProgress': []
    }).toList();
  }

  Future<void> _updateExerciseProgress(int index, int setNumber) async {
    setState(() {
      _exerciseProgress[index]['userProgress'].add({
        'userId': _auth.currentUser!.uid,
        'setNumber': setNumber,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Mark exercise as complete if all sets are done
      if (_exerciseProgress[index]['userProgress'].length >=
          _exerciseProgress[index]['sets']) {
        _exerciseProgress[index]['completed'] = true;
      }
    });

    // Save progress to Firestore
    await _firestore
        .collection('workout_sessions')
        .doc(widget.workoutCode)
        .collection('participant_progress')
        .add({
      'userId': _auth.currentUser!.uid,
      'exerciseName': _exerciseProgress[index]['name'],
      'setNumber': setNumber,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collaborative Workout'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _exerciseProgress.length,
        itemBuilder: (context, index) {
          final exercise = _exerciseProgress[index];
          return Card(
            child: ListTile(
              title: Text(exercise['name']),
              subtitle: Text('${exercise['sets']} sets, ${exercise['reps']} reps'),
              trailing: exercise['completed']
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                onPressed: () => _updateExerciseProgress(index, 1),
                child: Text('Complete Set'),
              ),
            ),
          );
        },
      ),
    );
  }
}