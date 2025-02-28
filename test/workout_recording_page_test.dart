import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/models/workout_model.dart';
import 'package:workoutpage/widgets/meters_input_widget.dart';
import 'package:workoutpage/widgets/numeric_input_widget.dart';
import 'package:workoutpage/widgets/time_input_widget.dart';
import 'package:workoutpage/workout_details/standard_workout_recording_page.dart';

void main() {
  testWidgets('Displays input fields for each exercise type',
      (WidgetTester tester) async {
    // Mock workout data
    final mockWorkout = Workout(
      workoutName: "Test Workout",
      date: DateTime.now().toString(),
      exercises: [
        Exercise(name: 'Push-ups', type: 'Reps', targetOutput: 10),
        Exercise(name: 'Running', type: 'Meters', targetOutput: 100),
        Exercise(name: 'Plank', type: 'Seconds', targetOutput: 30),
      ],
    );

    // Create a mock GoRouter instance
    final mockGoRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/workout-recording',
          builder: (context, state) {
            final workout = state.extra as Workout?;
            return StandardWorkoutRecordingPage(
                workoutPlan: workout ?? mockWorkout);
          },
        ),
      ],
    );

    // Render the page
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WorkoutProvider(),
        child: MaterialApp.router(
          routerConfig: mockGoRouter,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify exercise names are displayed
    expect(find.text('Push-ups'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);

    // Check correct input widgets are used
    expect(find.byType(NumericInputWidget), findsOneWidget);
    expect(find.byType(MetersInputWidget), findsOneWidget);
    expect(find.byType(TimeInputWidget), findsOneWidget);
  });
}
