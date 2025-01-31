import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/widgets/time_input_widget.dart';

import '../main.dart';
import '../models/workout_model.dart';
import '../widgets/exercise_helper.dart';
import '../widgets/meters_input_widget.dart';
import '../widgets/numeric_input_widget.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutRecordingPage extends StatefulWidget {
  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  final List<Exercise> exercises = [
    Exercise('Push-ups', 'Reps'),
    Exercise('Running', 'Meters'),
    Exercise('Plank', 'Seconds'),
    Exercise('Squats', 'Reps'),
    Exercise('Cycling', 'Meters'),
    Exercise('Cardio', 'Seconds'),
    Exercise('Bicep Curls', 'Reps'),
  ];

  final Map<int, int> exerciseOutputs =
      {}; // Map to store inputs for each exercise

  void _saveWorkout() {
    final workout = Workout(
      date: DateTime.now().toString(),
      exercises: exercises
          .map((exercise) => ExerciseResult(
                exercise.name,
                exercise.type,
                exerciseOutputs[exercises.indexOf(exercise)] ?? 0,
              ))
          .toList(),
    );

    // Add workout to shared state using Provider
    Provider.of<WorkoutProvider>(context, listen: false).addWorkout(workout);

    // Navigate back to WorkoutHistoryPage after saving
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Workout'),
      ),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          final target = getTargetForExercise(
              exercise.name, exercise.type); // Get the target

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the exercise name and the target
                Text(exercise.name, style: TextStyle(fontSize: 18)),
                Text('Target: $target ${exercise.type}',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),

                // Show the input field based on exercise type (Reps, Seconds, Meters)
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
