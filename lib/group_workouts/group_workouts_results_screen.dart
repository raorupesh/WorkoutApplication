import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/recent_performance_widget.dart';

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
  _GroupWorkoutResultsPageState createState() =>
      _GroupWorkoutResultsPageState();
}

class _GroupWorkoutResultsPageState extends State<GroupWorkoutResultsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;


  List<Map<String, dynamic>> _exerciseResults = [];
  Map<String, String> _userNames = {};
  Map<String, int> _userTotals = {};

  int _totalAchieved = 0;
  int _totalTarget = 0;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      // 1) Get the group doc
      final groupDoc = await _firestore
          .collection('group_workouts')
          .doc(widget.workoutCode)
          .get();
      if (!groupDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }
      final groupData = groupDoc.data() ?? {};


      final List<dynamic> participants = groupData['participants'] ?? [];

      for (String uid in participants) {

        _userNames[uid] = uid == _auth.currentUser?.uid
            ? "You"
            : "User-${uid.substring(0, 5)}";
      }

      final exercises = widget.workoutData['exercises'] as List<dynamic>? ?? [];
      Map<String, int> targetMap = {};
      for (var ex in exercises) {
        final exName = ex['name'];
        final targetVal = ex['target'] ?? ex['targetOutput'] ?? 0;
        targetMap[exName] = targetVal;
      }


      List<Map<String, dynamic>> loadedResults = [];
      for (var ex in exercises) {
        final name = ex['name'];
        final type = ex['type'] ?? ex['unit'] ?? 'reps';
        final target = targetMap[name] ?? 0;

        final snap = await _firestore
            .collection('group_workouts')
            .doc(widget.workoutCode)
            .collection('exercise_progress')
            .doc(name)
            .collection('participants')
            .get();

        // Build a list
        List<Map<String, dynamic>> userData = [];
        int sumOutput = 0;

        for (var doc in snap.docs) {
          final d = doc.data();
          final uid = d['userId'] as String;
          final userName = d['userName'] ?? _userNames[uid] ?? "Anonymous";
          final output = (d['output'] ?? 0) as int;
          userData.add({
            'userId': uid,
            'userName': userName,
            'output': output,
          });

          sumOutput += output;


          if (widget.isCompetitive) {
            _userTotals[uid] = (_userTotals[uid] ?? 0) + output;
          }
        }


        userData.sort((a, b) => (b['output'] as int).compareTo(a['output'] as int));

        if (!widget.isCompetitive) {
          _totalAchieved += sumOutput;
          _totalTarget += target;
        }

        loadedResults.add({
          'name': name,
          'type': type,
          'target': target,
          'participants': userData,
          'totalOutput': sumOutput,
        });
      }

      setState(() {
        _exerciseResults = loadedResults;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading results: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCompetitive
        ? 'Competitive Results'
        : 'Collaborative Results';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/workoutPlanSelection'),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildResultsBody(),
    );
  }

  Widget _buildResultsBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isCompetitive ? "Competition Leaderboard" : "Team Progress",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          widget.isCompetitive
              ? _buildCompetitiveLeaderboard()
              : _buildCollaborativeOverview(),

          SizedBox(height: 24),
          Divider(),

          Text(
            'Exercise Breakdown',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),

          ..._exerciseResults.map((ex) => _buildExerciseCard(ex)).toList(),

          SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              height: 100,  // Adjust the height as needed
              child: RecentPerformanceWidget(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCompetitiveLeaderboard() {
    // Sort by total points desc
    final sorted = _userTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("No results yet."),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: sorted.asMap().entries.map((entry) {
            final rank = entry.key;
            final userId = entry.value.key;
            final total = entry.value.value;
            final userName = _userNames[userId] ?? "User-${userId.substring(0,5)}";
            return ListTile(
              leading: _buildRankIcon(rank),
              title: Text(
                userName,
                style: TextStyle(
                  fontWeight: userId == _auth.currentUser!.uid
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: userId == _auth.currentUser!.uid ? Colors.teal : null,
                ),
              ),
              trailing: Text("$total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRankIcon(int rank) {
    if (rank == 0) {
      return CircleAvatar(
        backgroundColor: Colors.amber,
        child: Icon(Icons.emoji_events, color: Colors.white),
      );
    } else if (rank == 1) {
      return CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.emoji_events, color: Colors.white),
      );
    } else if (rank == 2) {
      return CircleAvatar(
        backgroundColor: Colors.brown,
        child: Icon(Icons.emoji_events, color: Colors.white),
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.teal.shade100,
      child: Text("${rank + 1}"),
    );
  }


  Widget _buildCollaborativeOverview() {
    if (_exerciseResults.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("No results yet."),
        ),
      );
    }

    double progress = 0;
    if (_totalTarget > 0) {
      progress = _totalAchieved / _totalTarget;
      if (progress > 1.0) progress = 1.0;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Team Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 20,
                backgroundColor: Colors.grey.shade300,
                color: progress < 0.3
                    ? Colors.red
                    : (progress < 0.7 ? Colors.orange : Colors.green),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "${(progress * 100).toStringAsFixed(1)}% complete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("$_totalAchieved / $_totalTarget total outputs"),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ex) {
    final name = ex['name'];
    final type = ex['type'];
    final target = ex['target'];
    final totalOutput = ex['totalOutput'] ?? 0;
    final participants = ex['participants'] as List<dynamic>;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(name),
        subtitle: Text("Target: $target $type"),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Achieved: $totalOutput $type",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Participants:"),
                SizedBox(height: 8),

                if (participants.isEmpty)
                  Text("No one has logged this exercise yet.")
                else
                  Column(
                    children: participants.map((p) {
                      final userId = p['userId'] ?? '';
                      final userName = p['userName'] ?? 'Unknown';
                      final output = p['output'] ?? 0;
                      final isMe = userId == _auth.currentUser?.uid;

                      return ListTile(
                        leading: widget.isCompetitive
                            ? Icon(Icons.emoji_events_outlined)
                            : Icon(Icons.check_circle_outline),
                        title: Text(
                          userName,
                          style: TextStyle(
                            fontWeight:
                            isMe ? FontWeight.bold : FontWeight.normal,
                            color: isMe ? Colors.teal : null,
                          ),
                        ),
                        trailing: Text("$output $type"),
                      );
                    }).toList().cast<Widget>(),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
