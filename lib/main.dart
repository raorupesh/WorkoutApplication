import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/workout_details/join_workout_page.dart';

import 'models/workout_model.dart';
import 'services/database_service.dart';
import 'splash_screen.dart';
import 'workout_details/download_workout_input_page.dart';
import 'workout_details/download_workout_page.dart';
import 'workout_details/standard_workout_recording_page.dart';
import 'workout_details/workout_details_page.dart';
import 'workout_details/workout_history_page.dart';
import 'workout_details/workout_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final workoutProvider = WorkoutProvider();
  await workoutProvider.initProvider();

  runApp(
    ChangeNotifierProvider(
      create: (_) => workoutProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => WorkoutHistoryPage()),
      GoRoute(path: '/join-workout', builder: (context, state) => JoinWorkoutPage()),
      GoRoute(
          path: '/workout-selection',
          builder: (context, state) => WorkoutPlanSelectionPage()),
      GoRoute(
          path: '/workout-recording',
          builder: (context, state) => StandardWorkoutRecordingPage()),
      GoRoute(
          path: '/download-workout',
          builder: (context, state) => DownloadWorkoutPage()),
      GoRoute(
          path: '/download-workout-input',
          builder: (context, state) {
            final workout = state.extra as Workout?;
            if (workout == null) {
              return Scaffold(
                body: Center(child: Text("Error: No workout data provided")),
              );
            }
            return DownloadedWorkoutInputPage(workoutPlan: workout);
          }),
      GoRoute(
          path: '/workout-details',
          builder: (context, state) {
            final workout = state.extra as Workout?;
            if (workout == null) {
              return Scaffold(
                body: Center(child: Text("Error: No workout data provided")),
              );
            }
            return WorkoutDetailsPage(workout: workout);
          }),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CoreSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class WorkoutProvider with ChangeNotifier {
  List<Workout> _workouts = [];
  List<Workout> _downloadedPlans = [];

  // Expose them via getters
  List<Workout> get workouts => _workouts;

  List<Workout> get downloadedPlans => _downloadedPlans;

  // This runs once at app startup (see main())
  Future<void> initProvider() async {
    _workouts = await Future.delayed(Duration(milliseconds: 200), () {
      return DBService.instance.getAllCompletedWorkouts();
    });
    _downloadedPlans = await Future.delayed(Duration(milliseconds: 200), () {
      return DBService.instance.getAllDownloadedPlans();
    });
    notifyListeners();
  }


  // Called when user finishes recording a workout
  Future<void> addWorkout(Workout workout) async {
    _workouts.add(workout);
    notifyListeners();
    await DBService.instance.insertCompletedWorkout(workout);
  }

  // Called to save a new downloaded plan for future usage
  Future<void> addDownloadedPlan(Workout plan) async {
    _downloadedPlans.add(plan);
    notifyListeners();
    await DBService.instance.insertDownloadedPlan(plan);
  }
}
