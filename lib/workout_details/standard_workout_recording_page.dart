import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/widgets/meters_input_widget.dart';
import 'package:workoutpage/widgets/numeric_input_widget.dart';
import 'package:workoutpage/widgets/recent_performance_widget.dart';
import 'package:workoutpage/widgets/time_input_widget.dart';
import '../main.dart';
import '../models/workout_model.dart';

class StandardWorkoutRecordingPage extends StatefulWidget {
  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<StandardWorkoutRecordingPage> {
  final List<Exercise> exercises = [
    Exercise(name: 'Push-ups', targetOutput:  10, type: 'Reps'),
    Exercise(name: 'Planks', targetOutput:  10, type: 'Seconds'),
    Exercise(name: 'Rowing', targetOutput:  10, type: 'Meters'),
    Exercise(name: 'Cycling', targetOutput:  10, type: 'Meters'),
    Exercise(name: 'Cardio', targetOutput:  10, type: 'Seconds'),
    Exercise(name: 'Burpees', targetOutput:  10, type: 'Reps'),
    Exercise(name: 'Hammer Curls', targetOutput:  10, type: 'Reps'),
  ];

  final Map<int, int> exerciseOutputs =
  {}; // Map to store inputs for each exercise

  void _saveWorkout() {
    // Generate the ExerciseResult list based on the user's inputs
    final exerciseResults = exercises.map((exercise) {
      final achievedOutput = exerciseOutputs[exercises.indexOf(exercise)] ?? 0;
      return ExerciseResult(
        name: exercise.name,
        achievedOutput: achievedOutput,
        type: exercise.type,
      );
    }).toList();

    // Create the Workout object
    final workout = Workout(
      workoutName: "Your Recorded Workout",
      date: DateTime.now().toString(),
      exerciseResults: exerciseResults,
      exercises: exercises, // Include the exercises for reference
    );

    // Add the workout to the shared state using Provider
    Provider.of<WorkoutProvider>(context, listen: false).addWorkout(workout);

    // Navigate back to the WorkoutHistoryPage after saving
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
          final target = exercise.targetOutput; // Get the target output

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
                    key: Key('${exercise.name}-input'), // Dynamically set key for the input field
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
