import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/workout_model.dart';
import '../widgets/meters_input_widget.dart';
import '../widgets/numeric_input_widget.dart';
import '../widgets/recent_performance_widget.dart';
import '../widgets/time_input_widget.dart';

class DownloadedWorkoutInputPage extends StatefulWidget {
  final Workout workoutPlan;

  DownloadedWorkoutInputPage({required this.workoutPlan});

  @override
  _DownloadedWorkoutInputPageState createState() =>
      _DownloadedWorkoutInputPageState();
}

class _DownloadedWorkoutInputPageState
    extends State<DownloadedWorkoutInputPage> {
  final Map<int, int> exerciseOutputs = {};

  void _saveWorkout() async {
    final exerciseResults = widget.workoutPlan.exercises.map((exercise) {
      final idx = widget.workoutPlan.exercises.indexOf(exercise);
      final achievedOutput = exerciseOutputs[idx] ?? 0;
      return ExerciseResult(
        name: exercise.name,
        achievedOutput: achievedOutput,
        type: exercise.type,
      );
    }).toList();

    final workout = Workout(
      workoutName: widget.workoutPlan.workoutName,
      date: DateTime.now().toIso8601String(),
      exercises: widget.workoutPlan.exercises,
      exerciseResults: exerciseResults,
    );

    await Provider.of<WorkoutProvider>(context, listen: false)
        .addWorkout(workout);

    // Navigate to WorkoutHistoryPage using go_router
    context.go('/workoutHistory');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the previous screen
            context.go('/workoutPlanSelection');
          },
        ),
        title: Text(widget.workoutPlan.workoutName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.workoutPlan.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = widget.workoutPlan.exercises[index];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Target: ${exercise.targetOutput} ${exercise.type}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          if (exercise.type == 'meters')
                            MetersInputWidget(
                              onInputChanged: (value) {
                                setState(() {
                                  exerciseOutputs[index] = value;
                                });
                              },
                            ),
                          if (exercise.type == 'seconds')
                            TimeInputWidget(
                              onInputChanged: (value) {
                                setState(() {
                                  exerciseOutputs[index] = value;
                                });
                              },
                            ),
                          if (exercise.type == 'reps')
                            NumericInputWidget(
                              label: exercise.type,
                              initialValue: 0,
                              onInputChanged: (value) {
                                setState(() {
                                  exerciseOutputs[index] = value;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveWorkout,
        child: Icon(Icons.save),
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
}
