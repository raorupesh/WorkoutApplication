import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/recent_performance_widget.dart';
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

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);


    if (_localWorkoutData['exercises'] == null) {
      try {
        final docSnap = await _firestore
            .collection('group_workouts')
            .doc(widget.workoutCode)
            .get();
        if (!docSnap.exists) {
          _showErrorAndGoBack("Workout does not exist or has been removed.");
          return;
        }

        final serverData = docSnap.data() ?? {};
        _localWorkoutData['exercises'] = serverData['exercises'] ?? [];
        _localWorkoutData['description'] = serverData['description'] ?? '';
      } catch (e) {
        _showErrorAndGoBack("Error loading workout: $e");
        return;
      }
    }

    await _joinWorkout();
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
        'userInput': 0,
      };
    }).toList();
  }

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

  void _startListeningToExerciseUpdates() {
    for (int i = 0; i < _exerciseProgress.length; i++) {
      final exerciseName = _exerciseProgress[i]['name'];

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
          final data = docSnap.data() ?? {};
          setState(() {
            _exerciseProgress[i]['completed'] = true;
            _exerciseProgress[i]['userInput'] = data['output'] ?? 0;
          });
          _checkAllDone();
        }
      });
    }
  }

  void _checkAllDone() {
    final all = _exerciseProgress.every((ex) => ex['completed'] == true);
    if (all && !_isFinished) {
      setState(() => _isFinished = true);
    }
  }


  Future<void> _submitAllExercises() async {
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

        final int output = ex['userInput'] ?? 0;
        if (output > 0) {
          await _updateSingleExerciseProgress(i, output);
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }

      setState(() => _isFinished = true);
      _navigateToResults();
    } catch (e) {
      // Close the loading indicator
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting results: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


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

    // Mark local state as completed
    setState(() {
      _exerciseProgress[index]['completed'] = true;
    });
  }

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
            Expanded(child: _buildExercisesList(themeColor)),
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton(
            onPressed: _submitAllExercises,
            child: Icon(Icons.save),
            backgroundColor: themeColor,
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
                    final isYou =
                        _participants[index] == _auth.currentUser!.uid;
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

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCompleted ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
                    width: isCompleted ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Name
                      Text(
                        ex['name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),

                      // Progress Bar
                      _buildTargetProgressBar(ex, isCompleted, themeColor),

                      // If done, show chip; otherwise show input field
                      if (isCompleted)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Chip(
                            label: Text('Completed'),
                            avatar: Icon(Icons.check_circle, color: Colors.white, size: 16),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        )
                      else
                        _buildExerciseInput(index, themeColor),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 80),
      ],
    );
  }



  Widget _buildExerciseInput(int index, Color themeColor) {
    final ex = _exerciseProgress[index];
    final exerciseType = (ex['type'] as String).toLowerCase();
    final currentVal = ex['userInput'] ?? 0;

    void onChanged(int value) {
      setState(() {
        _exerciseProgress[index]['userInput'] = value;
      });
    }

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
      // Fallback: treat other types like 'reps'
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

}
