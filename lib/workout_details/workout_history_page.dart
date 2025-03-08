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

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                // Solo Workouts Tab
                WorkoutHistoryTabContent(workoutType: 'solo'),

                // Competitive Workouts Tab
                WorkoutHistoryTabContent(workoutType: 'competitive'),

                // Collaborative Workouts Tab
                WorkoutHistoryTabContent(workoutType: 'collaborative'),
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
      floatingActionButton: _buildFloatingActions(context),
    );
  }

  /// Build Floating Action Buttons
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

  const WorkoutHistoryTabContent({
    Key? key,
    required this.workoutType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final workouts = workoutProvider.workouts.where((workout) {
      // Filter workouts based on type
      // Note: You'll need to add a 'type' field to your Workout model
      return workout.type == workoutType;
    }).toList();

    // Sort workouts by date (newest first)
    workouts.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    // Debugging
    print("$workoutType Workouts: ${workouts.map((w) => w.toJson()).toList()}");

    return workouts.isEmpty
        ? _buildEmptyState(workoutType)
        : ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _buildWorkoutCard(context, workout);
      },
    );
  }

  /// Build Empty State when no workouts are available
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

  /// Build Individual Workout Card
  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    final completedExercises = workout.exerciseResults.where((result) {
      final matchingExercise = workout.exercises.firstWhere(
              (e) => e.name == result.name,
          orElse: () => Exercise(name: '', targetOutput: 0, type: ''));
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