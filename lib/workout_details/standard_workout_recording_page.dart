import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/workout_model.dart';
import '../widgets/meters_input_widget.dart';
import '../widgets/numeric_input_widget.dart';
import '../widgets/recent_performance_widget.dart';
import '../widgets/time_input_widget.dart';

class StandardWorkoutRecordingPage extends StatefulWidget {
  final Workout? workoutPlan;

  StandardWorkoutRecordingPage({Key? key, this.workoutPlan}) : super(key: key);

  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<StandardWorkoutRecordingPage> {
  late List<Exercise> exercises;
  final Map<int, int> exerciseOutputs = {};

  @override
  void initState() {
    super.initState();
    exercises = widget.workoutPlan?.exercises ??
        [
          Exercise(name: 'Push-ups', targetOutput: 10, type: 'Reps'),
          Exercise(name: 'Planks', targetOutput: 10, type: 'Seconds'),
          Exercise(name: 'Rowing', targetOutput: 10, type: 'Meters'),
          Exercise(name: 'Cycling', targetOutput: 10, type: 'Meters'),
          Exercise(name: 'Cardio', targetOutput: 10, type: 'Seconds'),
          Exercise(name: 'Burpees', targetOutput: 10, type: 'Reps'),
          Exercise(name: 'Hammer Curls', targetOutput: 10, type: 'Reps'),
        ];
  }

  void _saveWorkout() async {
    final exerciseResults = exercises.map((exercise) {
      final idx = exercises.indexOf(exercise);
      final achievedOutput = exerciseOutputs[idx] ?? 0;
      return ExerciseResult(
        name: exercise.name,
        achievedOutput: achievedOutput,
        type: exercise.type,
      );
    }).toList();

    final workout = Workout(
      workoutName: widget.workoutPlan?.workoutName ?? "Standard Workout",
      date: DateTime.now().toIso8601String(),
      exercises: exercises,
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
        title: Text(widget.workoutPlan?.workoutName ?? 'Record Workout'),
      ),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Target: ${exercise.targetOutput} ${exercise.type}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 10),
                if (exercise.type == 'Meters')
                  MetersInputWidget(
                    onInputChanged: (value) {
                      exerciseOutputs[index] = value;
                    },
                  ),
                if (exercise.type == 'Seconds')
                  TimeInputWidget(
                    onInputChanged: (value) {
                      exerciseOutputs[index] = value;
                    },
                  ),
                if (exercise.type == 'Reps')
                  NumericInputWidget(
                    label: exercise.type,
                    initialValue: 0,
                    onInputChanged: (value) {
                      exerciseOutputs[index] = value;
                    },
                  ),
              ],
            ),
          );
        },
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
