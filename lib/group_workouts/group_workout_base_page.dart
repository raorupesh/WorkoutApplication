import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../widgets/meters_input_widget.dart';
import '../widgets/numeric_input_widget.dart';
import '../widgets/time_input_widget.dart';

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

class _WorkoutDetailsBasePageState extends State<WorkoutDetailsBasePage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Each exercise is stored as a map:
  ///   {
  ///     'name': <String>,
  ///     'targetOutput': <int>,
  ///     'type': <String>,
  ///     'completed': <bool>,
  ///     'userInput': <int>
  ///   }
  List<Map<String, dynamic>> _exerciseProgress = [];
  List<String> _participants = [];
  bool _isLoading = true;
  bool _isFinished = false;

  late Map<String, dynamic> _localWorkoutData;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _localWorkoutData = Map<String, dynamic>.from(widget.workoutData);
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

  /// Fetch or fill in the workout data (in case user scanned code)
  /// Then join the workout, set up the progress watchers
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    // If user scanned a code, we might not have the full "exercises" array
    if (_localWorkoutData['exercises'] == null) {
      try {
        final docSnap = await _firestore
            .collection('group_workouts')
            .doc(widget.workoutCode)
            .get();
        if (!docSnap.exists) {
          // No valid workout doc
          _showErrorAndGoBack("Workout does not exist or has been removed.");
          return;
        }

        final serverData = docSnap.data() ?? {};
        // Merge into local
        _localWorkoutData['exercises'] = serverData['exercises'] ?? [];
        _localWorkoutData['description'] = serverData['description'] ?? '';
      } catch (e) {
        _showErrorAndGoBack("Error loading workout: $e");
        return;
      }
    }

    // Now that we have data, join the participants
    await _joinWorkout();

    // Prepare local exerciseProgress
    _initializeExerciseProgress();
    _startListeningToParticipants();
    _startListeningToExerciseUpdates();

    setState(() {
      _isLoading = false;
    });
    _animController.forward();
  }

  void _showErrorAndGoBack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) context.go('/workoutPlanSelection');
    });
  }

  Future<void> _joinWorkout() async {
    final userId = _auth.currentUser!.uid;
    await _firestore
        .collection('group_workouts')
        .doc(widget.workoutCode)
        .update({
      'participants': FieldValue.arrayUnion([userId]),
    });
  }

  void _initializeExerciseProgress() {
    final exercises = _localWorkoutData['exercises'];
    if (exercises == null || exercises is! List) {
      _exerciseProgress = [];
      return;
    }

    _exerciseProgress = exercises.map<Map<String, dynamic>>((exercise) {
      return {
        'name': exercise['name'] ?? 'Unnamed',
        'targetOutput': exercise['target'] ?? exercise['targetOutput'] ?? 0,
        'type': exercise['unit'] ?? exercise['type'] ?? 'reps',
        'completed': false,
        'userInput': 0, // The user’s local input
      };
    }).toList();
  }

  /// Start listening for changes in the "participants" array
  void _startListeningToParticipants() {
    _firestore
        .collection('group_workouts')
        .doc(widget.workoutCode)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};
      setState(() {
        _participants = List<String>.from(data['participants'] ?? []);
      });
    });
  }

  /// For each exercise, see if the user has submitted
  void _startListeningToExerciseUpdates() {
    for (int i = 0; i < _exerciseProgress.length; i++) {
      final exerciseName = _exerciseProgress[i]['name'];

      // We track if the user has completed it in the subcollection
      _firestore
          .collection('group_workouts')
          .doc(widget.workoutCode)
          .collection('exercise_progress')
          .doc(exerciseName)
          .collection('participants')
          .doc(_auth.currentUser!.uid)
          .snapshots()
          .listen((docSnap) {
        if (docSnap.exists) {
          // If we see data for this user, mark completed
          final data = docSnap.data() ?? {};
          setState(() {
            _exerciseProgress[i]['completed'] = true;
            _exerciseProgress[i]['userInput'] = data['output'] ?? 0;
          });

          // Then see if everything is done
          _checkAllDone();
        }
      });
    }
  }

  void _checkAllDone() {
    // For the current user
    final all = _exerciseProgress.every((ex) => ex['completed'] == true);
    if (all && !_isFinished) {
      setState(() => _isFinished = true);
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text('Workout Completed!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToResults();
            },
            child: Text('View Results', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  /// Submits the entire set of exercises in one go
  Future<void> _submitAllExercises() async {
    // Validate userInput for each exercise
    for (final ex in _exerciseProgress) {
      if (ex['completed'] == true) continue; // skip already-submitted

      // Check if userInput is > 0
      if ((ex['userInput'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill all exercises before submitting.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show a loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(
          color: widget.isCompetitive ? Colors.orange : Colors.teal,
        ),
      ),
    );

    try {
      for (int i = 0; i < _exerciseProgress.length; i++) {
        final ex = _exerciseProgress[i];
        if (ex['completed'] == true) continue; // skip

        final int output = ex['userInput'];
        await _updateSingleExerciseProgress(i, output);
      }

      Navigator.pop(context); // Close the loading dialog

      // If everything is done by now, show success
      bool allDone = _exerciseProgress.every((ex) => ex['completed'] == true);
      if (allDone) {
        setState(() => _isFinished = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All results submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Go to results
        Future.delayed(Duration(seconds: 1), () {
          _navigateToResults();
        });
      }
    } catch (e) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting results: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Submits a single exercise result to the Firestore subcollection
  Future<void> _updateSingleExerciseProgress(int index, int output) async {
    final ex = _exerciseProgress[index];
    final exerciseName = ex['name'];
    final userId = _auth.currentUser!.uid;
    final userName = _auth.currentUser!.displayName ??
        _auth.currentUser!.email ??
        'User-${userId.substring(0, 5)}';

    await _firestore
        .collection('group_workouts')
        .doc(widget.workoutCode)
        .collection('exercise_progress')
        .doc(exerciseName)
        .collection('participants')
        .doc(userId)
        .set({
      'userId': userId,
      'userName': userName,
      'output': output,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Also store a summary in the doc itself if needed
    await _firestore
        .collection('group_workouts')
        .doc(widget.workoutCode)
        .collection('exercise_progress')
        .doc(exerciseName)
        .set({
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Mark local state completed
    setState(() {
      _exerciseProgress[index]['completed'] = true;
    });
  }

  /// After finishing, jump to results
  void _navigateToResults() {
    if (widget.isCompetitive) {
      context.go(
        '/competitiveWorkoutResults',
        extra: {
          'code': widget.workoutCode,
          'workoutData': _localWorkoutData,
        },
      );
    } else {
      context.go(
        '/collaborativeWorkoutResults',
        extra: {
          'code': widget.workoutCode,
          'workoutData': _localWorkoutData,
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isCompetitive ? Colors.orange : Colors.teal;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isCompetitive
              ? 'Competitive Workout'
              : 'Collaborative Workout',
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
            Expanded(child: _buildExercisesList(themeColor)),
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
    final desc = _localWorkoutData['description'] ?? '';
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: desc.isNotEmpty
          ? Text(
        desc,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade700,
        ),
        textAlign: TextAlign.center,
      )
          : SizedBox.shrink(),
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

              // Non-tapable QR code
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
                  children: List.generate(_participants.length, (index) {
                    final isYou = _participants[index] == _auth.currentUser!.uid;
                    return Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Column(
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
                          SizedBox(height: 4),
                          Text(
                            isYou
                                ? "You"
                                : "User ${_participants[index].substring(0, 5)}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              isYou ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList(Color themeColor) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _exerciseProgress.length,
            itemBuilder: (context, index) {
              final ex = _exerciseProgress[index];
              final isCompleted = ex['completed'] == true;
              final exerciseType = (ex['type'] as String).toLowerCase();

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
                    child: FadeTransition(opacity: curvedAnimation, child: child),
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
                        // Exercise Title/Name
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
                                _getExerciseIcon(ex['name']),
                                color: isCompleted ? Colors.green : themeColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTargetProgressBar(ex, isCompleted, themeColor),
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

                        // If completed, show a "Completed" chip, otherwise show input
                        if (isCompleted)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Chip(
                              label: Text('Completed'),
                              avatar: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          )
                        else
                          _buildExerciseInput(index, themeColor),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // One big "Submit All" at the bottom
        if (!_isFinished)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _submitAllExercises,
              icon: Icon(Icons.save, size: 20),
              label: Text(
                'SUBMIT ALL RESULTS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
      ],
    );
  }

  // Build the appropriate input widget depending on the type (reps/seconds/meters/ etc.)
  Widget _buildExerciseInput(int index, Color themeColor) {
    final ex = _exerciseProgress[index];
    final exerciseType = (ex['type'] as String).toLowerCase();
    final currentVal = ex['userInput'] ?? 0;

    void onChanged(int value) {
      setState(() {
        _exerciseProgress[index]['userInput'] = value;
      });
    }

    // Simple wrapper
    Widget label(String text) => Text(
      text,
      style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
    );

    switch (exerciseType) {
      case 'reps':
        return NumericInputWidget(
          label: 'Reps',
          initialValue: currentVal,
          onInputChanged: onChanged,
        );
      case 'seconds':
        return TimeInputWidget(
          initialValue: currentVal,
          onInputChanged: onChanged,
          key: ValueKey('timeInput-$index'),
        );
      case 'meters':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: MetersInputWidget(
            onInputChanged: onChanged,
            key: ValueKey('metersInput-$index'),
          ),
        );
      default:
      // fallback: treat any other type like 'reps'
        return NumericInputWidget(
          label: exerciseType,
          initialValue: currentVal,
          onInputChanged: onChanged,
        );
    }
  }

  Widget _buildTargetProgressBar(
      Map<String, dynamic> ex,
      bool isCompleted,
      Color themeColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Target: ", style: TextStyle(fontWeight: FontWeight.w500)),
            Text(
              "${ex['targetOutput']} ${ex['type']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeColor,
                fontSize: 16,
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

  IconData _getExerciseIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('run') || lower.contains('sprint')) {
      return Icons.directions_run;
    } else if (lower.contains('push')) {
      return Icons.fitness_center;
    } else if (lower.contains('squat')) {
      return Icons.accessibility_new;
    } else if (lower.contains('jump')) {
      return Icons.height;
    } else if (lower.contains('plank')) {
      return Icons.horizontal_rule;
    } else if (lower.contains('bike') || lower.contains('cycle')) {
      return Icons.directions_bike;
    } else if (lower.contains('swim')) {
      return Icons.pool;
    }
    return Icons.fitness_center;
  }
}
