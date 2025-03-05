import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompetitiveWorkoutDetailsPage extends StatefulWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;

  const CompetitiveWorkoutDetailsPage({
    Key? key,
    required this.workoutCode,
    required this.workoutData
  }) : super(key: key);

  @override
  _CompetitiveWorkoutDetailsPageState createState() => _CompetitiveWorkoutDetailsPageState();
}

class _CompetitiveWorkoutDetailsPageState extends State<CompetitiveWorkoutDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track competitive workout progress
  List<Map<String, dynamic>> _exercises = [];
  Map<String, dynamic> _userStats = {
    'totalPoints': 0,
    'completedExercises': 0,
    'rank': 0,
  };
  List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  Future<void> _initializeWorkout() async {
    try {
      // Initialize exercises from workout data
      setState(() {
        _exercises = (widget.workoutData['exercises'] as List<dynamic>)
            .map((exercise) => {
          'name': exercise['name'],
          'sets': exercise['sets'],
          'reps': exercise['reps'],
          'points': exercise['points'] ?? 10, // Default points per exercise
          'completed': false,
          'userProgress': [],
        }).toList();
      });

      // Set up real-time leaderboard listener
      _setupLeaderboardListener();
    } catch (e) {
      print('Error initializing workout: $e');
    }
  }

  void _setupLeaderboardListener() {
    _firestore
        .collection('competitive_workouts')
        .doc(widget.workoutCode)
        .collection('participants')
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _leaderboard = snapshot.docs.map((doc) => {
          'userId': doc.id,
          'username': doc.data()['username'],
          'totalPoints': doc.data()['totalPoints'],
          'rank': snapshot.docs.indexWhere((d) => d.id == doc.id) + 1
        }).toList();

        // Update user's rank
        final userDoc = _leaderboard.firstWhere(
                (participant) => participant['userId'] == _auth.currentUser!.uid,
            orElse: () => {'rank': _leaderboard.length + 1}
        );
        _userStats['rank'] = userDoc['rank'];
      });
    });
  }

  Future<void> _completeExercise(int exerciseIndex) async {
    final exercise = _exercises[exerciseIndex];

    // Prevent multiple completions
    if (exercise['completed']) return;

    try {
      // Update local state
      setState(() {
        exercise['completed'] = true;
        _userStats['completedExercises']++;
        _userStats['totalPoints'] += exercise['points'];
      });

      // Update Firestore
      await _firestore
          .collection('competitive_workouts')
          .doc(widget.workoutCode)
          .collection('participants')
          .doc(_auth.currentUser!.uid)
          .set({
        'username': _auth.currentUser?.displayName ?? 'Anonymous',
        'totalPoints': _userStats['totalPoints'],
        'completedExercises': _userStats['completedExercises'],
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log exercise completion
      await _firestore
          .collection('competitive_workouts')
          .doc(widget.workoutCode)
          .collection('exercise_log')
          .add({
        'userId': _auth.currentUser!.uid,
        'exerciseName': exercise['name'],
        'points': exercise['points'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error completing exercise: $e');
      // Revert local state on error
      setState(() {
        exercise['completed'] = false;
        _userStats['completedExercises']--;
        _userStats['totalPoints'] -= exercise['points'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Competitive Workout'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // User Stats Card
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Total Points', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_userStats['totalPoints']}'),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_userStats['rank']}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Exercises List
          Expanded(
            child: ListView.builder(
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(exercise['name']),
                    subtitle: Text('${exercise['sets']} sets, ${exercise['reps']} reps'),
                    trailing: exercise['completed']
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                      onPressed: () => _completeExercise(index),
                      child: Text('Complete (${exercise['points']} pts)'),
                    ),
                  ),
                );
              },
            ),
          ),

          // Leaderboard
          Card(
            margin: EdgeInsets.all(16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Leaderboard',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, index) {
                    final participant = _leaderboard[index];
                    return ListTile(
                      leading: Text('${participant['rank']}'),
                      title: Text(participant['username'] ?? 'Anonymous'),
                      trailing: Text('${participant['totalPoints']} pts'),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}