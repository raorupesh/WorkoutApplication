import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = Provider.of<WorkoutProvider>(context).workouts;

    workouts.sort(
        (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

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

          // Workout List
          Expanded(
            child: workouts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 100,
                          color: Colors.teal.shade200,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No workouts recorded yet.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.teal.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      final completedExercises = workout.exerciseResults
                          .where((result) =>
                              result.achievedOutput >=
                              workout
                                  .exercises[
                                      workout.exerciseResults.indexOf(result)]
                                  .targetOutput)
                          .length;
                      final incompleteExercises =
                          workout.exerciseResults.length - completedExercises;

                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Workout Name
                              Text(
                                workout.workoutName, // Display workout name
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
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text('Completed: $completedExercises'),
                                SizedBox(width: 16),
                                Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text('Incomplete: $incompleteExercises'),
                              ],
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.teal.shade800,
                              ),
                              onPressed: () {
                                context.push('/workoutDetails', extra: workout);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Floating Action Buttons
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                children: [
                  Tooltip(
                    message: 'Select Workout Plan',
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: FloatingActionButton(
                        heroTag: "workoutPlanSelectionButton", // Unique tag
                        onPressed: () {
                          context.push('/workoutPlanSelection');
                        },
                        child: Icon(Icons.add),
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Tooltip(
                    message: 'Join Workout',
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: FloatingActionButton(
                        heroTag: "joinWorkoutButton", // Unique tag
                        onPressed: () {
                          context.push('/joinWorkout');
                        },
                        child: Icon(Icons.link),
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
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
    );
  }
}
