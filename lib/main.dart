import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:workoutpage/workout_details/workout_selection_page.dart';
import 'models/workout_model.dart';
import 'services/database_service.dart';
import 'splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'workout_details/workout_history_page.dart';
import 'workout_details/join_workout_page.dart';
import 'workout_details/workout_details_page.dart';
import 'workout_details/standard_workout_recording_page.dart';
import 'workout_details/download_workout_page.dart';
import 'workout_details/download_workout_input_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final workoutProvider = WorkoutProvider();
  await workoutProvider.initProvider();

  runApp(
    ChangeNotifierProvider(
      create: (_) => workoutProvider,
      child: MyApp(),
    ),
  );
}

class WorkoutProvider with ChangeNotifier {
  List<Workout> _workouts = [];
  List<Workout> _downloadedPlans = [];

  List<Workout> get workouts => _workouts;
  List<Workout> get downloadedPlans => _downloadedPlans;

  Future<void> initProvider() async {
    _workouts = await DBService.instance.getAllCompletedWorkouts();
    _downloadedPlans = await DBService.instance.getAllDownloadedPlans();
    notifyListeners();
  }

  Future<void> addWorkout(Workout workout) async {
    _workouts.add(workout);
    notifyListeners();
    await DBService.instance.insertCompletedWorkout(workout);
  }

  Future<void> addDownloadedPlan(Workout plan) async {
    _downloadedPlans.add(plan);
    notifyListeners();
    await DBService.instance.insertDownloadedPlan(plan);
  }
}

final _router = GoRouter(
  initialLocation: '/splash', // Start with splash screen
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => WorkoutHistoryPage(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: '/workoutPlanSelection',
      builder: (context, state) => WorkoutPlanSelectionPage(),
    ),
    GoRoute(
      path: '/joinWorkout',
      builder: (context, state) => JoinWorkoutPage(),
    ),
    GoRoute(
      path: '/workoutDetails',
      builder: (context, state) {
        final workout = state.extra as Workout;
        return WorkoutDetailsPage(workout);
      },
    ),
    GoRoute(
      path: '/standardWorkoutRecording',
      builder: (context, state) => StandardWorkoutRecordingPage(),
    ),
    GoRoute(
      path: '/downloadWorkout',
      builder: (context, state) => DownloadWorkoutPage(),
    ),
    GoRoute(
      path: '/downloadedWorkoutInput',
      builder: (context, state) {
        final workout = state.extra as Workout;
        return DownloadedWorkoutInputPage(workoutPlan: workout);
      },
    ),
    GoRoute(
      path: '/workoutHistory',
      builder: (context, state) => WorkoutHistoryPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
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
    );
  }
}