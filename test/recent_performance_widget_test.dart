import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/models/workout_model.dart';
import 'package:workoutpage/widgets/recent_performance_widget.dart';

void main() {
  group('RecentPerformanceWidget Tests', () {
    testWidgets('Displays "No workout done" when there are no workouts',
        (WidgetTester tester) async {
      final mockWorkoutProvider = WorkoutProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: mockWorkoutProvider,
            child: Scaffold(body: RecentPerformanceWidget()),
          ),
        ),
      );

      await tester.pump();

      expect(find.text("No workout done."), findsOneWidget);
    });

    testWidgets('Displays performance scores when workouts exist',
        (WidgetTester tester) async {
      final mockWorkoutProvider = WorkoutProvider();
      final now = DateTime.now();

      mockWorkoutProvider.workouts.add(
        Workout(
          workoutName: "Test Workout",
          date: now.toString(),
          exercises: [
            Exercise(name: 'Push-ups', type: 'Reps', targetOutput: 10),
          ],
          exerciseResults: [
            ExerciseResult(name: 'Push-ups', type: 'Reps', achievedOutput: 12),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: mockWorkoutProvider,
            child: Scaffold(body: RecentPerformanceWidget()),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Overall Score'), findsOneWidget);
      expect(find.textContaining('Today\'s Score'), findsOneWidget);
    });
  });
}
