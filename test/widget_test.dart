import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/models/workout_model.dart';
import 'package:workoutpage/widgets/numeric_input_widget.dart';
import 'package:workoutpage/workout_details/workout_details_page.dart';

void main() {
  testWidgets('Shows exercise details and completion status',
      (WidgetTester tester) async {
    // Create a sample workout with an exercise and a completed result
    final workout = Workout(
      workoutName: "Test Workout",
      date: DateTime.now().toString(),
      exercises: [Exercise(name: 'Planks', type: 'Seconds', targetOutput: 10)],
      exerciseResults: [
        ExerciseResult(name: 'Planks', type: 'Seconds', achievedOutput: 10)
      ],
    );

    // Create a mock GoRouter instance
    final mockGoRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/workout-details',
          builder: (context, state) {
            return WorkoutDetailsPage(workout: workout);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WorkoutProvider(),
        child: MaterialApp.router(
          routerConfig: mockGoRouter,
        ),
      ),
    );

    // Ensure workout details are displayed correctly
    expect(find.text('Planks'), findsOneWidget);
    expect(find.text('Target: 10 Seconds'), findsOneWidget);
    expect(find.text('Achieved: 10 Seconds'), findsOneWidget);
    expect(find.text('Status: Completed'), findsOneWidget);
  });
  testWidgets('Numeric input widget allows user to change reps',
      (WidgetTester tester) async {
    int selectedReps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericInputWidget(
            label: 'Reps',
            initialValue: 0,
            onInputChanged: (value) => selectedReps = value,
          ),
        ),
      ),
    );

    expect(find.text('Reps'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(selectedReps, 1);
  });
}
