import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // only if needed
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/workout_model.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutHistoryPage extends StatefulWidget {
  @override
  _WorkoutHistoryPageState createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Workout> _firebaseCollaborative = [];
  List<Workout> _firebaseCompetitive = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _fetchGroupWorkouts();
  }


  Future<void> _fetchGroupWorkouts() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        print("Error: User ID is empty.");
        return;
      }

      final query = await FirebaseFirestore.instance.collection('group_workouts').get();

      final List<Workout> collab = [];
      final List<Workout> comp = [];

      for (var doc in query.docs) {
        final data = doc.data();
        final docRef = doc.reference;

        // Check if user is in the "participants" list
        final List<dynamic> participants = data['participants'] ?? [];
        if (!participants.contains(userId)) continue; // Skip workouts user hasn't participated in

        // Get workout type
        final String type = data['workoutType'] ?? '';

        // Extract metadata
        final String workoutName = data['workoutName'] ?? 'Group Workout';
        final Timestamp? createdAt = data['createdAt'] as Timestamp?;
        final String dateString = createdAt?.toDate().toIso8601String() ?? DateTime.now().toIso8601String();

        // Parse exercises
        final exercises = data['exercises'] as List<dynamic>? ?? [];
        final List<Exercise> exerciseList = exercises.map((e) {
          return Exercise(
            name: e['name'] ?? 'Unnamed',
            targetOutput: e['target'] ?? e['targetOutput'] ?? 0,
            type: e['unit'] ?? e['type'] ?? 'reps',
          );
        }).toList();

        // Fetch the user's recorded results
        final List<ExerciseResult> userResults = [];

        for (var ex in exerciseList) {
          final exerciseName = ex.name;

          final participantDoc = await docRef
              .collection('exercise_progress')
              .doc(exerciseName)
              .collection('participants')
              .doc(userId)
              .get();

          if (participantDoc.exists) {
            final participantData = participantDoc.data() ?? {};
            final output = participantData['output'] ?? 0;

            userResults.add(
              ExerciseResult(
                name: exerciseName,
                achievedOutput: output,
                type: ex.type,
              ),
            );
          } else {
            // If the user has not recorded this exercise, assume 0 output
            userResults.add(
              ExerciseResult(
                name: exerciseName,
                achievedOutput: 0,
                type: ex.type,
              ),
            );
          }
        }

        // Build workout object
        final workout = Workout(
          workoutName: workoutName,
          date: dateString,
          exercises: exerciseList,
          exerciseResults: userResults,
          type: type,
        );

        // Add to correct list
        if (type == 'competitive') {
          comp.add(workout);
        } else if (type == 'collaborative') {
          collab.add(workout);
        }
      }

      // Update state with only relevant workouts
      setState(() {
        _firebaseCollaborative = collab;
        _firebaseCompetitive = comp;
      });

    } catch (e) {
      print("Error fetching group workouts: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Workout History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Solo'),
            Tab(text: 'Competitive'),
            Tab(text: 'Collaborative'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Performance Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Text(
              'Daily Progress Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Solo Workouts -> still from local DB if you want
                WorkoutHistoryTabContent(
                  workoutType: 'solo',
                ),

                // Competitive (fresh from Firebase)
                WorkoutHistoryTabContent(
                  workoutType: 'competitive',
                  firebaseWorkouts: _firebaseCompetitive,
                ),

                // Collaborative (fresh from Firebase)
                WorkoutHistoryTabContent(
                  workoutType: 'collaborative',
                  firebaseWorkouts: _firebaseCollaborative,
                ),
              ],
            ),
          ),

          // Recent Performance Widget
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              height: 80,
              child: RecentPerformanceWidget(),
            ),
          ),
        ],
      ),

      // Floating Action Buttons remain as you had them
      floatingActionButton: _buildFloatingActions(context),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Tooltip(
          message: 'Select Workout Plan',
          child: FloatingActionButton(
            heroTag: "workoutPlanSelectionButton",
            onPressed: () => context.push('/workoutPlanSelection'),
            child: Icon(Icons.add),
            backgroundColor: Colors.teal,
          ),
        ),
        SizedBox(height: 10),
        Tooltip(
          message: 'Join Workout',
          child: FloatingActionButton(
            heroTag: "joinWorkoutButton",
            onPressed: () => context.push('/joinWorkout'),
            child: Icon(Icons.link),
            backgroundColor: Colors.teal,
          ),
        ),
      ],
    );
  }
}


class WorkoutHistoryTabContent extends StatelessWidget {
  final String workoutType;

  final List<Workout> firebaseWorkouts;

  const WorkoutHistoryTabContent({
    Key? key,
    required this.workoutType,
    this.firebaseWorkouts = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If this is "solo," we'll fetch from local DB.
    // Otherwise, we rely on firebaseWorkouts.
    List<Workout> workouts;
    if (workoutType == 'solo') {
      final workoutProvider = Provider.of<WorkoutProvider>(context);
      workouts = workoutProvider.workouts
          .where((w) => w.type == 'solo')
          .toList();
    } else {
      workouts = firebaseWorkouts;
    }

    workouts.sort(
          (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );

    if (workouts.isEmpty) {
      return _buildEmptyState(workoutType);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _buildWorkoutCard(context, workout);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'competitive':
        message = 'No competitive workouts yet.';
        icon = Icons.emoji_events;
        break;
      case 'collaborative':
        message = 'No collaborative workouts yet.';
        icon = Icons.people;
        break;
      default:
        message = 'No solo workouts recorded yet.';
        icon = Icons.fitness_center;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.teal.shade200),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.teal.shade400),
          ),
        ],
      ),
    );
  }


  Widget _buildWorkoutCard(BuildContext context, Workout workout) {

    final completedExercises = workout.exerciseResults.where((result) {
      final matchingExercise = workout.exercises.firstWhere(
            (e) => e.name == result.name,
        orElse: () => Exercise(name: '', targetOutput: 0, type: ''),
      );
      return result.achievedOutput >= matchingExercise.targetOutput;
    }).length;

    final incompleteExercises =
        workout.exerciseResults.length - completedExercises;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout Name
            Text(
              workout.workoutName.isNotEmpty
                  ? workout.workoutName
                  : "Unnamed Workout",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            SizedBox(height: 4),
            // Date
            Text(
              DateFormat('MMM dd, yyyy h:mm a')
                  .format(DateTime.parse(workout.date)),
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.teal.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text('Completed: $completedExercises'),
              SizedBox(width: 16),
              Icon(Icons.cancel, color: Colors.red, size: 16),
              SizedBox(width: 4),
              Text('Incomplete: $incompleteExercises'),
            ],
          ),
        ),
        trailing: _buildTrailingIcon(context, workout),
      ),
    );
  }

  Widget _buildTrailingIcon(BuildContext context, Workout workout) {
    IconData iconData;
    Color backgroundColor;

    switch (workoutType) {
      case 'competitive':
        iconData = Icons.emoji_events;
        backgroundColor = Colors.amber.shade100;
        break;
      case 'collaborative':
        iconData = Icons.people;
        backgroundColor = Colors.blue.shade100;
        break;
      default:
        iconData = Icons.arrow_forward_rounded;
        backgroundColor = Colors.teal.shade100;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(iconData, color: Colors.teal.shade800),
        onPressed: () {
          context.push('/workoutDetails', extra: workout);
        },
      ),
    );
  }
}
