import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/group_workout_models.dart';

class GroupWorkoutResultsPage extends StatefulWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;
  final bool isCompetitive;

  const GroupWorkoutResultsPage({
    Key? key,
    required this.workoutCode,
    required this.workoutData,
    required this.isCompetitive,
  }) : super(key: key);

  @override
  _GroupWorkoutResultsPageState createState() => _GroupWorkoutResultsPageState();
}

class _GroupWorkoutResultsPageState extends State<GroupWorkoutResultsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _exerciseResults = [];
  Map<String, String> _userNames = {};
  Map<String, int> _userTotalScores = {};
  int _totalCollaborativeScore = 0;
  double _collaborativeCompletion = 0.0;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      // Get all exercise progress documents
      final exerciseProgressSnapshot = await _firestore
          .collection('group_workouts')
          .doc(widget.workoutCode)
          .collection('exercise_progress')
          .get();

      // Get workout participants
      final workoutSnapshot = await _firestore
          .collection('group_workouts')
          .doc(widget.workoutCode)
          .get();

      final workoutData = workoutSnapshot.data();
      final List<dynamic> participants = workoutData?['participants'] ?? [];

      // Fetch user names
      for (String userId in List<String>.from(participants)) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          _userNames[userId] = userDoc.data()?['displayName'] ?? 'Anonymous';
        } else {
          _userNames[userId] = 'Anonymous';
        }
      }

      // Process the exercise results
      final exercises = widget.workoutData['exercises'] as List<dynamic>;
      final targetOutputs = Map<String, int>.fromIterable(
        exercises,
        key: (e) => e['name'],
        value: (e) => e['targetOutput'],
      );

      // Organize results by exercise
      Map<String, List<Map<String, dynamic>>> exerciseData = {};
      int totalTargetOutput = 0;
      int totalAchievedOutput = 0;

      for (var doc in exerciseProgressSnapshot.docs) {
        final data = doc.data();
        final exerciseName = doc.id;
        final userId = data['userId'];
        final output = data['output'] as int;

        // For competitive mode: track user scores
        if (widget.isCompetitive) {
          _userTotalScores[userId] = (_userTotalScores[userId] ?? 0) + output;
        }

        // For collaborative mode: track total achievement
        if (!widget.isCompetitive) {
          if (targetOutputs.containsKey(exerciseName)) {
            totalTargetOutput += targetOutputs[exerciseName] ?? 0;
            totalAchievedOutput += output;
          }
        }

        if (!exerciseData.containsKey(exerciseName)) {
          exerciseData[exerciseName] = [];
        }

        exerciseData[exerciseName]?.add({
          'userId': userId,
          'userName': _userNames[userId] ?? 'Anonymous',
          'output': output,
          'timestamp': data['timestamp'],
        });
      }

      // Sort and prepare final results list
      _exerciseResults = exercises.map((exercise) {
        final name = exercise['name'];
        final targetOutput = exercise['targetOutput'];
        final type = exercise['type'];

        return {
          'name': name,
          'targetOutput': targetOutput,
          'type': type,
          'results': exerciseData[name] ?? [],
        };
      }).toList();

      // Calculate collaborative completion percentage
      if (!widget.isCompetitive && totalTargetOutput > 0) {
        _totalCollaborativeScore = totalAchievedOutput;
        _collaborativeCompletion = totalAchievedOutput / totalTargetOutput;
        if (_collaborativeCompletion > 1.0) _collaborativeCompletion = 1.0;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCompetitive
            ? 'Competitive Results'
            : 'Collaborative Results'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/workoutPlanSelection'),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildResultsContent(),
    );
  }

  Widget _buildResultsContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isCompetitive ? 'Competition Results' : 'Team Results',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Display leaderboard for competitive or progress for collaborative
            widget.isCompetitive
                ? _buildCompetitiveLeaderboard()
                : _buildCollaborativeProgress(),

            Divider(height: 32),

            Text(
              'Exercise Breakdown',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Exercise details
            ..._exerciseResults.map((exercise) => _buildExerciseCard(exercise)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitiveLeaderboard() {
    // Sort users by total score
    final sortedUsers = _userTotalScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leaderboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...sortedUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final userId = entry.value.key;
              final score = entry.value.value;
              final userName = _userNames[userId] ?? 'Anonymous';

              // Highlight current user
              final isCurrentUser = userId == _auth.currentUser?.uid;

              return ListTile(
                leading: _getRankIcon(index),
                title: Text(
                  userName,
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentUser ? Colors.teal : null,
                  ),
                ),
                trailing: Text(
                  score.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _getRankIcon(int index) {
    if (index == 0) {
      return CircleAvatar(
        backgroundColor: Colors.amber,
        child: Icon(Icons.emoji_events, color: Colors.white),
      );
    } else if (index == 1) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.emoji_events, color: Colors.white),
      );
    } else if (index == 2) {
      return CircleAvatar(
        backgroundColor: Colors.brown.shade300,
        child: Icon(Icons.emoji_events, color: Colors.white),
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.teal.shade100,
        child: Text('${index + 1}'),
      );
    }
  }

  Widget _buildCollaborativeProgress() {
    final exercises = widget.workoutData['exercises'] as List<dynamic>;
    int targetTotal = 0;

    for (var exercise in exercises) {
      targetTotal += exercise['targetOutput'] as int;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Progress bar
            ClipRounded(
              child: LinearProgressIndicator(
                value: _collaborativeCompletion,
                minHeight: 24,
                backgroundColor: Colors.grey.shade200,
                color: _getProgressColor(_collaborativeCompletion),
              ),
            ),
            SizedBox(height: 8),

            // Progress text
            Text(
              '${(_collaborativeCompletion * 100).toStringAsFixed(1)}% Complete',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),
            Text(
              '$_totalCollaborativeScore / $targetTotal total output',
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 16),
            Text(
              'Team Members (${_userNames.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            // Team members list
            ..._userNames.entries.map((entry) {
              final isCurrentUser = entry.key == _auth.currentUser?.uid;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal.shade700),
                ),
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentUser ? Colors.teal : null,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final results = exercise['results'] as List<dynamic>;

    // Sort results by output (higher first)
    results.sort((a, b) => (b['output'] as int).compareTo(a['output'] as int));

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(exercise['name']),
        subtitle: Text('Target: ${exercise['targetOutput']} ${exercise['type']}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participants',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No results recorded yet'),
                  )
                else
                  ...results.asMap().entries.map((entry) {
                    final index = entry.key;
                    final result = entry.value;
                    final isCurrentUser = result['userId'] == _auth.currentUser?.uid;

                    return ListTile(
                      leading: widget.isCompetitive ? Text('${index + 1}.') : Icon(Icons.check_circle),
                      title: Text(
                        result['userName'],
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentUser ? Colors.teal : null,
                        ),
                      ),
                      trailing: Text(
                        '${result['output']} ${exercise['type']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClipRounded extends StatelessWidget {
  final Widget child;

  const ClipRounded({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}