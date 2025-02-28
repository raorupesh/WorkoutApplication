import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/models/workout_model.dart';
import 'package:workoutpage/workout_details/workout_history_page.dart';

void main() {
  group('WorkoutHistoryPage Tests', () {
    testWidgets('Displays multiple workout entries with timestamps',
        (WidgetTester tester) async {
      final mockWorkoutProvider = WorkoutProvider();
      final now = DateTime.now();

      // Manually set workouts list instead of using addWorkout
      mockWorkoutProvider.workouts.addAll([
        Workout(
            workoutName: "Workout 1",
            date: now.toString(),
            exercises: [],
            exerciseResults: []),
        Workout(
            workoutName: "Workout 2",
            date: now.subtract(Duration(days: 1)).toString(),
            exercises: [],
            exerciseResults: []),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: mockWorkoutProvider,
            child: WorkoutHistoryPage(),
          ),
        ),
      );

      await tester.pump();

      // Verify workouts are displayed
      expect(find.text(DateFormat('yyyy-MM-dd h:mm a').format(now)),
          findsOneWidget);
      expect(
          find.text(DateFormat('yyyy-MM-dd h:mm a')
              .format(now.subtract(Duration(days: 1)))),
          findsOneWidget);
    });
  });
}
