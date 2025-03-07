import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/main.dart';
import 'package:workoutpage/workout_details/download_workout_page.dart';

// Mock WorkoutProvider for dependency injection
class MockWorkoutProvider extends Mock implements WorkoutProvider {}

void main() {
  group('DownloadWorkoutPage Tests', () {
    testWidgets('Displays an error message when an invalid URL is entered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => WorkoutProvider(),
            child: DownloadWorkoutPage(),
          ),
        ),
      );

      // Enter an invalid URL
      await tester.enterText(find.byType(TextField), "invalid_url");
      await tester.tap(find.text("Download Plan"));

      // Wait for UI update
      await tester.pumpAndSettle();

      // Check for an error message
      expect(find.textContaining("Failed to fetch content"), findsOneWidget);
    });
  });
}
