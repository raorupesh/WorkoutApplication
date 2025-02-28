import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/workout_model.dart';
import 'services/database_service.dart';
import 'splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Make sure DB is initialized before runApp
  final workoutProvider = WorkoutProvider();
  await workoutProvider.initProvider();

  runApp(
    ChangeNotifierProvider(
      create: (_) => workoutProvider,
      child: MaterialApp(
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
        home: SplashScreen(), // Start with SplashScreen
      ),
    ),
  );
}

class WorkoutProvider with ChangeNotifier {
  List<Workout> _workouts = [];
  List<Workout> _downloadedPlans = [];

  // Expose them via getters
  List<Workout> get workouts => _workouts;
  List<Workout> get downloadedPlans => _downloadedPlans;

  // This runs once at app startup (see main())
  Future<void> initProvider() async {
    _workouts = await DBService.instance.getAllCompletedWorkouts();
    _downloadedPlans = await DBService.instance.getAllDownloadedPlans();
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
