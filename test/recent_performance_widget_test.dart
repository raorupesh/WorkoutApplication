import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/models/workout_model.dart';
import 'package:workoutpage/widgets/recent_performance_widget.dart';

void main() {
  group('RecentPerformanceWidget Tests', () {
    // Test 1: Check for "No workouts in the past 7 days" when there are no workouts
    testWidgets(
        'Displays "No workouts in the past 7 days" when no workouts are available',
        (WidgetTester tester) async {
      // Create a WorkoutProvider with no workouts
      final mockWorkoutProvider = WorkoutProvider();

      // Render the widget with the provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WorkoutProvider>.value(
            value: mockWorkoutProvider,
            child: Scaffold(
              body: RecentPerformanceWidget(),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Verify that the widget shows the "No workouts in the past 7 days" text
      expect(find.text("No workout done."), findsOneWidget);
    });

    // Test 2: Check for recent performance scores when workouts are available
    testWidgets(
        'Displays recent performance widget when workouts are available',
        (WidgetTester tester) async {
      // Create mock workout data with some exercise results
      final mockWorkoutProvider = WorkoutProvider();

      final now = DateTime.now();
      mockWorkoutProvider.addWorkout(Workout(
        workoutName: "User Recorded Workout",
        date: now.toString(),
        exerciseResults: [
          ExerciseResult(name: 'Push-ups', type: 'Reps', achievedOutput: 10),
          ExerciseResult(name: 'Rowing', type: 'Meters', achievedOutput: 100),
          ExerciseResult(name: 'Plank', type: 'Seconds', achievedOutput: 10),
        ],
        exercises: [
          Exercise(name: 'Push-ups', type: 'Reps', targetOutput: 10),
          Exercise(name: 'Cycling', type: 'Meters', targetOutput: 100),
          Exercise(name: 'Plank', type: 'Seconds', targetOutput: 10),
        ],
      ));

      // Render the widget with the provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WorkoutProvider>.value(
            value: mockWorkoutProvider,
            child: Scaffold(
              body: RecentPerformanceWidget(),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Verify that the widget displays the overall score and today's score
      expect(find.textContaining('Overall Score'), findsOneWidget);
      expect(find.textContaining('Today\'s Score'), findsOneWidget);
    });
  });
}
