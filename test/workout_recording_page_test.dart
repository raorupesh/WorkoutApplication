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
            date: now.toString(),
            exerciseResults: [
              ExerciseResult('Push-ups', 'Reps', 10),
              ExerciseResult('Running', 'Meters', 100),
              ExerciseResult('Plank', 'Seconds', 10),
              ExerciseResult('Squats', 'Reps', 10),
              ExerciseResult('Cycling', 'Meters', 100),
              ExerciseResult('Cardio', 'Seconds', 10),
              ExerciseResult('Bicep Curls', 'Reps', 10),
            ],
            exercises: [
              Exercise('Push-ups', 'Reps', 10),
              Exercise('Running', 'Meters', 100),
              Exercise('Plank', 'Seconds', 10),
              Exercise('Squats', 'Reps', 10),
              Exercise('Cycling', 'Meters', 100),
              Exercise('Cardio', 'Seconds', 10),
              Exercise('Bicep Curls', 'Reps', 10),
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
          expect(find.text('Running'), findsOneWidget);
          expect(find.text('Plank'), findsOneWidget);
          expect(find.text('Squats'), findsOneWidget);

          // Check for the input widgets
          expect(find.byType(NumericInputWidget), findsNWidgets(2));
          expect(find.byType(MetersInputWidget), findsNWidgets(1));
          expect(find.byType(TimeInputWidget), findsNWidgets(1));
        });
  });
}
