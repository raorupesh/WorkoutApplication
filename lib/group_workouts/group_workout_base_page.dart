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

class _WorkoutDetailsBasePageState extends State<WorkoutDetailsBasePage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _exerciseProgress = [];
  bool _isLoading = true;
  List<String> _participants = [];
  bool _isFinished = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _joinWorkout();
    _initializeExerciseProgress();
    _startListeningToParticipants();
    setState(() {
      _isLoading = false;
    });
    _animController.forward();
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
      'targetOutput': exercise['target'],
      'type': exercise['unit'],
      'completed': false,
      'userProgress': [],
    })
        .toList();
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
    final allCompleted =
    _exerciseProgress.every((exercise) => exercise['completed'] == true);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text('Workout Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/success.png', height: 100),
            SizedBox(height: 15),
            Text(
              'Congratulations! You have completed all exercises.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              'Would you like to view the results?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToResults();
            },
            child: Text('View Results', style: TextStyle(fontSize: 16)),
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

  void _showQrCodePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Workout Code: ${widget.workoutCode}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isCompetitive ? Colors.orange : Colors.teal,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.workoutCode,
                size: 200,
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: Size(40, 40),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isCompetitive ? Colors.orange : Colors.teal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isCompetitive ? 'Competitive Workout' : 'Collaborative Workout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
          ? Center(child: CircularProgressIndicator(color: themeColor))
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withOpacity(0.2),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildWorkoutInfoHeader(),
            _buildInviteSection(themeColor),
            _buildParticipantsSection(themeColor),
            Expanded(
              child: _buildExercisesList(themeColor),
            ),
          ],
        ),
      ),
      floatingActionButton: _isFinished
          ? FloatingActionButton.extended(
        onPressed: _navigateToResults,
        icon: Icon(Icons.leaderboard),
        label: Text('Results'),
        backgroundColor: themeColor,
      )
          : null,
    );
  }

  Widget _buildWorkoutInfoHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          if (widget.workoutData['description'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                widget.workoutData['description'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInviteSection(Color themeColor) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOut,
          )),
          child: FadeTransition(
            opacity: _animController,
            child: child,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isCompetitive ? Icons.fitness_center : Icons.group,
                    color: themeColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Workout Code: ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SelectableText(
                    widget.workoutCode,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Non-tapable QR code display
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.workoutCode,
                  size: 130,
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: Size(40, 40),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                widget.isCompetitive
                    ? "Compete with friends! Share the code above."
                    : "Team up with friends! Share the code above.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsSection(Color themeColor) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOut,
          )),
          child: FadeTransition(
            opacity: _animController,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: themeColor, size: 20),
                SizedBox(width: 8),
                Text(
                  "Participants (${_participants.length})",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_participants.isEmpty)
              Center(
                child: Text(
                  "Waiting for participants to join...",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    _participants.length,
                        (index) => Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: themeColor.withOpacity(0.2),
                                radius: 24,
                                child: Icon(
                                  Icons.person,
                                  color: themeColor,
                                  size: 28,
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            index == 0 ? "You" : "User ${index + 1}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: index == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList(Color themeColor) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _exerciseProgress.length,
      itemBuilder: (context, index) {
        final exercise = _exerciseProgress[index];
        final isCompleted = exercise['completed'] == true;

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final delay = (index + 3) * 0.2;
            final curvedAnimation = CurvedAnimation(
              parent: _animController,
              curve: Interval(
                delay < 1.0 ? delay : 0.9,
                1.0,
                curve: Curves.easeOut,
              ),
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCompleted
                    ? Colors.green.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.2),
                width: isCompleted ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withOpacity(0.1)
                              : themeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getExerciseIcon(exercise['name']),
                          color: isCompleted ? Colors.green : themeColor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            _buildTargetProgressBar(
                              exercise,
                              isCompleted,
                              themeColor,
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  widget.isCompetitive
                                      ? Icons.emoji_events
                                      : Icons.group_work,
                                  size: 16,
                                  color: widget.isCompetitive
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.isCompetitive
                                        ? "Competitive - Beat your personal best!"
                                        : "Collaborative - Work together to reach the target!",
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: widget.isCompetitive
                                          ? Colors.orange
                                          : Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isCompleted)
                        Chip(
                          label: Text('Completed'),
                          avatar: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            int output = await _showInputDialog(
                                context, exercise['type']);
                            if (output > 0) {
                              await _updateExerciseProgress(index, output);
                            }
                          },
                          icon: Icon(Icons.add_task, size: 18),
                          label: Text('Submit Result'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('run') || name.contains('sprint')) {
      return Icons.directions_run;
    } else if (name.contains('push')) {
      return Icons.fitness_center;
    } else if (name.contains('squat')) {
      return Icons.accessibility_new;
    } else if (name.contains('jump')) {
      return Icons.height;
    } else if (name.contains('plank')) {
      return Icons.horizontal_rule;
    } else if (name.contains('bike') || name.contains('cycle')) {
      return Icons.directions_bike;
    } else if (name.contains('swim')) {
      return Icons.pool;
    } else {
      return Icons.fitness_center;
    }
  }

  Widget _buildTargetProgressBar(
      Map<String, dynamic> exercise, bool isCompleted, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Target: ",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              "${exercise['targetOutput']} ${exercise['type']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeColor,
                fontSize: 16, // Make this larger
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isCompleted ? 1.0 : 0.0,
            backgroundColor: Colors.grey.shade200,
            color: isCompleted ? Colors.green : themeColor,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Future<int> _showInputDialog(BuildContext context, String type) async {
    int input = 0;
    final themeColor = widget.isCompetitive ? Colors.orange : Colors.teal;

    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.fitness_center, color: themeColor, size: 24),
              SizedBox(width: 10),
              Text("Record Your Result"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "How many $type did you complete?",
                style: TextStyle(color: Colors.grey.shade700),
              ),
              SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) => input = int.tryParse(value) ?? 0,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  suffix: Text(type),
                  hintText: "Enter amount",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                ),
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, input),
              child: Text("Submit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        );
      },
    ) ??
        0;
  }
}