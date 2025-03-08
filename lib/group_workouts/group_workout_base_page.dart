import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WorkoutDetailsBasePage extends StatefulWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;
  final bool isCompetitive;

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
  bool _isLoading = true;
  List<String> _participants = [];
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _joinWorkout();
    _initializeExerciseProgress();
    _startListeningToParticipants();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _joinWorkout() async {
    final userId = _auth.currentUser!.uid;

    // Add current user to participants array
    await _firestore
        .collection('group_workouts')
        .doc(widget.workoutCode)
        .update({
      'participants': FieldValue.arrayUnion([userId]),
    });
  }

  void _startListeningToParticipants() {
    _firestore
        .collection('group_workouts')
        .doc(widget.workoutCode)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _participants = List<String>.from(doc.data()?['participants'] ?? []);
        });
      }
    });
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

    // Start listening to exercise progress updates
    _startListeningToExerciseProgress();
  }

  void _startListeningToExerciseProgress() {
    for (int i = 0; i < _exerciseProgress.length; i++) {
      final exerciseName = _exerciseProgress[i]['name'];

      _firestore
          .collection('group_workouts')
          .doc(widget.workoutCode)
          .collection('exercise_progress')
          .doc(exerciseName)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          setState(() {
            // Mark as completed for this user
            final userId = _auth.currentUser!.uid;
            if (doc.data()?['userId'] == userId) {
              _exerciseProgress[i]['completed'] = true;
            }

            // Check if all exercises are completed
            _checkWorkoutCompletion();
          });
        }
      });
    }
  }

  void _checkWorkoutCompletion() {
    // For the current user only
    final allCompleted = _exerciseProgress.every((exercise) => exercise['completed'] == true);
    if (allCompleted && !_isFinished) {
      setState(() {
        _isFinished = true;
      });

      // Show completion dialog
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Workout Completed'),
        content: Text('You have completed all exercises. Would you like to view the results?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToResults();
            },
            child: Text('View Results'),
          ),
        ],
      ),
    );
  }

  void _navigateToResults() {
    final router = GoRouter.of(context);

    if (widget.isCompetitive) {
      router.go('/competitiveWorkoutResults', extra: {
        'code': widget.workoutCode,
        'workoutData': widget.workoutData,
      });
    } else {
      router.go('/collaborativeWorkoutResults', extra: {
        'code': widget.workoutCode,
        'workoutData': widget.workoutData,
      });
    }
  }

  Future<void> _updateExerciseProgress(int index, int output) async {
    String userId = _auth.currentUser!.uid;
    String exerciseName = _exerciseProgress[index]['name'];

    // For both competitive and collaborative workouts
    await _firestore
        .collection('group_workouts')
        .doc(widget.workoutCode)
        .collection('exercise_progress')
        .doc(exerciseName)
        .set({
      'userId': userId,
      'output': output,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      _exerciseProgress[index]['completed'] = true;
    });

    // Check if all exercises are completed
    _checkWorkoutCompletion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCompetitive
            ? 'Competitive Workout'
            : 'Collaborative Workout'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/workoutPlanSelection'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _navigateToResults,
            tooltip: 'View Results',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildInviteSection(),
          _buildParticipantsSection(),
          Expanded(
            child: _buildExercisesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Workout Code: ${widget.workoutCode}",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          QrImageView(
            data: widget.workoutCode,
            size: 150,
          ),
          SizedBox(height: 10),
          Text(
            widget.isCompetitive
                ? "Compete with friends! Share this code to invite others."
                : "Team up with friends! Share this code to invite others.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Participants (${_participants.length})",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _participants.length,
                    (index) => Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(Icons.person, color: Colors.teal.shade700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _exerciseProgress.length,
      itemBuilder: (context, index) {
        final exercise = _exerciseProgress[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(exercise['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Target: ${exercise['targetOutput']} ${exercise['type']}"),
                if (widget.isCompetitive)
                  Text(
                    "Mode: Competitive - Aim for your personal best!",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.orange,
                    ),
                  )
                else
                  Text(
                    "Mode: Collaborative - Work together to reach the target!",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            trailing: exercise['completed']
                ? Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
              onPressed: () async {
                int output = await _showInputDialog(
                    context, exercise['type']);
                if (output > 0) {
                  await _updateExerciseProgress(index, output);
                }
              },
              child: Text('Submit'),
            ),
            isThreeLine: true,
          ),
        );
      },
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
            decoration: InputDecoration(
              suffix: Text(type),
              hintText: "Enter amount",
            ),
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
    ) ??
        0;
  }
}