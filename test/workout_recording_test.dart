import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/widgets/numeric_input_widget.dart';
import 'package:workoutpage/widgets/time_input_Widget.dart';
import 'package:workoutpage/widgets/meters_input_widget.dart';
import 'package:workoutpage/workout_details/workout_recording_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('WorkoutRecordingPage shows separate input for each exercise', (WidgetTester tester) async {
    // Ensure the provider is above the widget in the widget tree
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ],
        child: MaterialApp(
          home: WorkoutRecordingPage(),
        ),
      ),
    );

    // Ensure the correct number of exercises are displayed
    expect(find.byType(NumericInputWidget), findsNWidgets(3)); // 'Push-ups', 'Squats', 'Bicep Curls', 'Reps' exercises
    expect(find.byType(TimeInputWidget), findsNWidgets(2));    // 'Plank', 'Cardio' exercises (Seconds)
    expect(find.byType(MetersInputWidget), findsNWidgets(2));  // 'Running', 'Cycling' exercises (Meters)

    // Ensure the labels and types are correctly displayed for each exercise
    expect(find.text('Push-ups'), findsOneWidget);
    expect(find.text('Target: Reps'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Target: Meters'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);
    expect(find.text('Target: Seconds'), findsOneWidget);
    expect(find.text('Squats'), findsOneWidget);
    expect(find.text('Target: Reps'), findsOneWidget);

    // Test interaction with the NumericInputWidget for 'Push-ups'
    await tester.enterText(find.byKey(Key('input_Push-ups')), '10');
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget); // Check if input field has the updated value

    // Test interaction with the TimeInputWidget for 'Plank'
    await tester.enterText(find.byKey(Key('input_Plank')), '60');
    await tester.pumpAndSettle();
    expect(find.text('60'), findsOneWidget); // Check if input field has the updated value

    // Test interaction with the MetersInputWidget for 'Running'
    await tester.enterText(find.byKey(Key('input_Running')), '100');
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget); // Check if input field has the updated value
  });
}
