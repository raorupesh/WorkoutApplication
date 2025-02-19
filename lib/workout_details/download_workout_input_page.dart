
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/workout_details/workout_history_page.dart';
import '../models/workout_model.dart';
import '../widgets/meters_input_widget.dart';
import '../widgets/numeric_input_widget.dart';
import '../widgets/time_input_widget.dart';
import '../main.dart';

class DownloadedWorkoutInputPage extends StatefulWidget {
  final Workout workoutPlan;

  DownloadedWorkoutInputPage({required this.workoutPlan});

  @override
  _DownloadedWorkoutInputPageState createState() => _DownloadedWorkoutInputPageState();
}

class _DownloadedWorkoutInputPageState extends State<DownloadedWorkoutInputPage> {
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

    await Provider.of<WorkoutProvider>(context, listen: false).addWorkout(workout);
    // Ensure only one instance of history page exists
    Navigator.popUntil(context, (route) => route.isFirst);

    // Push history page if not already there
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WorkoutHistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workoutPlan.workoutName)),
      body: ListView.builder(
        itemCount: widget.workoutPlan.exercises.length,
        itemBuilder: (context, index) {
          final exercise = widget.workoutPlan.exercises[index];

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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveWorkout,
        child: Icon(Icons.save),
      ),
    );
  }
}
