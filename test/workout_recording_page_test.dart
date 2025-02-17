import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart'; // Assuming this is the entry point
import 'package:workoutpage/models/workout_model.dart';
import 'package:workoutpage/widgets/meters_input_widget.dart';
import 'package:workoutpage/widgets/numeric_input_widget.dart';
import 'package:workoutpage/widgets/time_input_widget.dart';
import 'package:workoutpage/workout_details/workout_recording_page.dart'; // Assuming the page is here

void main() {
  group('WorkoutRecordingPage Tests', () {
    testWidgets('Shows input fields for each exercise in the workout plan',
            (WidgetTester tester) async {
          // Set up mock workout data with exercises
          final mockWorkoutProvider = WorkoutProvider();
          final now = DateTime.now();
          mockWorkoutProvider.addWorkout(Workout(
            workoutName: "Your Reocrded Workout",
            date: now.toString(),
            exerciseResults: [
              ExerciseResult(name: 'Push-ups', type: 'Reps',achievedOutput:  10),
              ExerciseResult(name: 'Rowing', type: 'Meters',achievedOutput:  100),
              ExerciseResult(name: 'Planks', type: 'Seconds',achievedOutput:  10),
              ExerciseResult(name: 'Burpees',type:  'Reps',achievedOutput:  10),
              ExerciseResult(name: 'Cycling', type: 'Meters',achievedOutput:  100),
              ExerciseResult(name: 'Cardio', type: 'Seconds',achievedOutput:  10),
              ExerciseResult(name: 'Hammer Curls', type: 'Reps',achievedOutput:  10),
            ],
            exercises: [
              Exercise(name: 'Push-ups', type: 'Reps',targetOutput:  10),
              Exercise(name: 'Rowing', type: 'Meters',targetOutput:  100),
              Exercise(name: 'Planks', type: 'Seconds', targetOutput: 10),
              Exercise(name: 'Burpees',type:   'Reps',targetOutput:  10),
              Exercise(name: 'Cycling', type: 'Meters', targetOutput: 100),
              Exercise(name: 'Cardio',type:  'Seconds', targetOutput: 10),
              Exercise(name: 'Hammer Curls',type:  'Reps',targetOutput:  10),
            ],
          ));

          // Render the page with the mock provider
          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<WorkoutProvider>.value(
                value: mockWorkoutProvider,
                child: Scaffold(
                  body:
                  WorkoutRecordingPage(), // The page containing the input fields for exercises
                ),
              ),
            ),
          );

          // Wait for the widget to build and settle
          await tester.pumpAndSettle();

          // Check for the exercise names to ensure they are displayed
          expect(find.text('Push-ups'), findsOneWidget);
          expect(find.text('Rowing'), findsOneWidget);
          expect(find.text('Planks'), findsOneWidget);
          expect(find.text('Cycling'), findsOneWidget);

          // Check for the input widgets
          expect(find.byType(NumericInputWidget), findsNWidgets(1));
          expect(find.byType(MetersInputWidget), findsNWidgets(2));
          expect(find.byType(TimeInputWidget), findsNWidgets(1));
        });
  });
}
