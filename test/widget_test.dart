import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/widgets/meters_input_widget.dart';
import 'package:workoutpage/widgets/numeric_input_widget.dart';
import 'package:workoutpage/workout_details/download_workout_page.dart';
import 'package:workoutpage/workout_details/workout_details_page.dart';
import 'package:workoutpage/models/workout_model.dart'; // Import the models
import 'package:workoutpage/widgets/recent_performance_widget.dart';
import 'package:workoutpage/workout_details/workout_recording_page.dart';
import 'package:workoutpage/workout_details/workout_selection_page.dart'; // Import RecentPerformanceWidget

void main() {
  group('WorkoutDetailsPage Tests', () {
    testWidgets('should show exercise details and actual output', (WidgetTester tester) async {
      // Prepare a mock workout with exercises and exercise results
      final exercise = Exercise(name: 'Push-up', type: 'reps', targetOutput: 30);
      final exerciseResult = ExerciseResult(name: 'Push-up', type: 'reps', achievedOutput: 35); // Completed more than target
      final workout = Workout(workoutName: "Your Recorded Workout", date: '2025-02-14 10:00:00', exercises: [exercise], exerciseResults: [exerciseResult]);

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => WorkoutProvider(),
            child: WorkoutDetailsPage(workout),
          ),
        ),
      );

      // Verify the exercise name
      expect(find.text('Push-up'), findsOneWidget);
      // Verify the target output
      expect(find.text('Target: 30 reps'), findsOneWidget);
      // Verify the actual output
      expect(find.text('Achieved: 35 reps'), findsOneWidget);
      // Verify the completion status
      expect(find.text('Status: Completed'), findsOneWidget);
    });
  });

  group('Widget Testing', () {
    testWidgets('Numeric input widget should allow user to change reps', (WidgetTester tester) async {
      int selectedReps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumericInputWidget(
              label: 'Reps',
              initialValue: 0,
              onInputChanged: (value) {
                selectedReps = value;
              },
            ),
          ),
        ),
      );

      // Verify initial value
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Increment the value
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify the value has been incremented
      expect(selectedReps, 1);
      expect(find.text('1'), findsOneWidget);

      // Decrement the value
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      // Verify the value has been decremented
      expect(selectedReps, 0);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Meters input widget should allow user to change distance', (WidgetTester tester) async {
      int selectedMeters = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetersInputWidget(
              onInputChanged: (value) {
                selectedMeters = value;
              },
            ),
          ),
        ),
      );

      // Verify initial value
      expect(find.text('Enter distance in meters'), findsOneWidget);

      // Simulate user entering text
      await tester.enterText(find.byType(TextField), '100');
      await tester.pumpAndSettle();

      // Verify the value has been updated
      expect(selectedMeters, 100);
    });
  });
}
