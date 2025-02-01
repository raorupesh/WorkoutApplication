import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart'; // Import the main app to access the page
import 'package:workoutpage/models/workout_model.dart'; // Assuming the WorkoutProvider uses Workout model
import 'package:workoutpage/workout_details/workout_history_page.dart';

void main() {
  group('WorkoutHistoryPage Tests', () {
    testWidgets('WorkoutHistoryPage shows multiple entries with timestamps',
        (WidgetTester tester) async {
      // Set up mock workout data with different timestamps
      final mockWorkoutProvider = WorkoutProvider();
      final now = DateTime.now();
      mockWorkoutProvider.addWorkout(Workout(
        date: now.toString(),
        exerciseResults: [],
        exercises: [],
      ));
      mockWorkoutProvider.addWorkout(Workout(
        date: now.subtract(Duration(days: 1)).toString(),
        exerciseResults: [],
        exercises: [],
      ));

      // Render the page with the mock provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WorkoutProvider>.value(
            value: mockWorkoutProvider,
            child: Scaffold(
              body:
                  WorkoutHistoryPage(), // Page that shows the list of workouts
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Get the formatted timestamps of the workouts
      final formattedTimestamp1 = DateFormat('yyyy-MM-dd h:mm a').format(now);
      final formattedTimestamp2 = DateFormat('yyyy-MM-dd h:mm a')
          .format(now.subtract(Duration(days: 1)));

      // Verify that the timestamps and "Total" text are displayed for each workout
      expect(find.text(formattedTimestamp1),
          findsOneWidget); // Today's workout timestamp
      expect(find.text(formattedTimestamp2),
          findsOneWidget); // Yesterday's workout timestamp
    });
  });
}
