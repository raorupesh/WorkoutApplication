import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/models/workout_model.dart';
import 'package:workoutpage/widgets/numeric_input_widget.dart';
import 'package:workoutpage/workout_details/workout_details_page.dart';

void main() {
  group('WorkoutDetailsPage Tests', () {
    testWidgets('Shows exercise details and completion status',
        (WidgetTester tester) async {
      final workout = Workout(
        workoutName: "Test Workout",
        date: DateTime.now().toString(),
        exercises: [Exercise(name: 'Push-up', type: 'Reps', targetOutput: 30)],
        exerciseResults: [
          ExerciseResult(name: 'Push-up', type: 'Reps', achievedOutput: 35)
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => WorkoutProvider(),
            child: WorkoutDetailsPage(workout),
          ),
        ),
      );

      expect(find.text('Push-up'), findsOneWidget);
      expect(find.text('Target: 30 Reps'), findsOneWidget);
      expect(find.text('Achieved: 35 Reps'), findsOneWidget);
      expect(find.text('Status: Completed'), findsOneWidget);
    });
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
