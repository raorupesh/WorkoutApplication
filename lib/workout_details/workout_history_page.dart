import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../widgets/recent_performance_widget.dart';
import 'workout_details_page.dart';
import 'workout_selection_page.dart';

class WorkoutHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = Provider.of<WorkoutProvider>(context).workouts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Daily Progress Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: workouts.isEmpty
                ? Center(child: Text('No workouts recorded yet.'))
                : ListView.builder(
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      final completedExercises = workout.exerciseResults
                          .where((result) =>
                              result.achievedOutput >=
                              workout.exercises[index].targetOutput)
                          .length;
                      final incompleteExercises =
                          workout.exerciseResults.length - completedExercises;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(
                            DateFormat('yyyy-MM-dd h:mm a')
                                .format(DateTime.parse(workout.date)),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Completed: $completedExercises'),
                              Text('Incomplete: $incompleteExercises'),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_rounded, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WorkoutDetailsPage(workout),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutPlanSelectionPage(),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
