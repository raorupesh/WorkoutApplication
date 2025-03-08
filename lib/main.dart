import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:provider/provider.dart';
import 'package:workoutpage/workout_details/workout_selection_page.dart';

import 'firebase_options.dart';
import 'group_workouts/collaborative_workout_page.dart';
import 'group_workouts/competitive_workout_page.dart';
import 'group_workouts/group_workouts_results_screen.dart';
import 'group_workouts/join_collaborative_workout_page.dart';
import 'group_workouts/join_competitive_workout_page.dart';
import 'models/workout_model.dart';
import 'services/database_service.dart';
import 'splash_screen.dart';
import 'workout_details/download_workout_input_page.dart';
import 'workout_details/download_workout_page.dart';
import 'workout_details/join_workout_page.dart';
import 'workout_details/standard_workout_recording_page.dart';
import 'workout_details/workout_details_page.dart';
import 'workout_details/workout_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleApiAvailability apiAvailability = GoogleApiAvailability.instance;
  GooglePlayServicesAvailability availability =
      await apiAvailability.checkGooglePlayServicesAvailability();

  if (availability == GooglePlayServicesAvailability.success) {
    print("Google Play Services are available.");
  } else {
    print("Google Play Services are NOT available: $availability");
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _ensureAnonymousAuthentication(); // Ensure Firebase Auth

  final workoutProvider = WorkoutProvider();
  await workoutProvider.initProvider();

  runApp(
    ChangeNotifierProvider(
      create: (_) => workoutProvider,
      child: MyApp(),
    ),
  );
}

Future<void> _ensureAnonymousAuthentication() async {
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      print("Anonymous sign-in successful. UID: ${auth.currentUser!.uid}");
    } else {
      print("User already signed in. UID: ${auth.currentUser!.uid}");
    }
  } catch (e) {
    print("Error during anonymous sign-in: $e");
  }
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
    await DBService.instance.insertCompletedWorkout(workout); // Ensure it saves
  }

  Future<void> addDownloadedPlan(Workout plan) async {
    _downloadedPlans.add(plan);
    notifyListeners();
    await DBService.instance.insertDownloadedPlan(plan);
  }
}

// Define app routing
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
        final workout = state.extra as Workout?;
        if (workout == null) {
          return ErrorPage("Workout data is missing.");
        }
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
        final workout = state.extra as Workout?;
        if (workout == null) {
          return ErrorPage("Workout data is missing.");
        }
        return DownloadedWorkoutInputPage(workoutPlan: workout);
      },
    ),
    GoRoute(
      path: '/workoutHistory',
      builder: (context, state) => WorkoutHistoryPage(),
    ),
    GoRoute(
      path: '/collaborativeWorkoutCode',
      builder: (context, state) => JoinCollaborativeWorkoutCodePage(),
    ),
    GoRoute(
      path: '/competitiveWorkoutCode',
      builder: (context, state) => JoinCompetitiveWorkoutPage(),
    ),
    GoRoute(
      path: '/competitiveWorkoutDetails',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('code') ||
            !args.containsKey('workoutData')) {
          return ErrorPage("Workout details are missing.");
        }
        return CompetitiveWorkoutDetailsPage(
          workoutCode: args['code'],
          workoutData: args['workoutData'],
        );
      },
    ),
    GoRoute(
      path: '/collaborativeWorkoutDetails',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('code') ||
            !args.containsKey('workoutData')) {
          return ErrorPage("Workout details are missing.");
        }
        return CollaborativeWorkoutDetailsPage(
          workoutCode: args['code'],
          workoutData: args['workoutData'],
        );
      },
    ),
    GoRoute(
        path: '/collaborativeWorkoutResults',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return GroupWorkoutResultsPage(
            workoutCode: extra['code'] as String,
            workoutData: extra['workoutData'] as Map<String, dynamic>,
            isCompetitive: false,
          );
        }),
    GoRoute(
        path: '/competitiveWorkoutResults',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return GroupWorkoutResultsPage(
            workoutCode: extra['code'] as String,
            workoutData: extra['workoutData'] as Map<String, dynamic>,
            isCompetitive: true,
          );
        }),
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

// Error Page for missing data cases
class ErrorPage extends StatelessWidget {
  final String errorMessage;

  const ErrorPage(this.errorMessage, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Error")),
      body: Center(
        child: Text(errorMessage,
            style: TextStyle(fontSize: 18, color: Colors.red)),
      ),
    );
  }
}
