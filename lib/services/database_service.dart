import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/workout_model.dart';

class DBService {
  // Singleton pattern
  DBService._privateConstructor();
  static final DBService instance = DBService._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    String path = join(dbPath, 'workouts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create the tables
  Future<void> _onCreate(Database db, int version) async {
    // Table for completed workouts
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutJson TEXT NOT NULL
      )
    ''');

    // Table for downloaded workout plans
    await db.execute('''
      CREATE TABLE downloaded_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutJson TEXT NOT NULL
      )
    ''');
  }

  // ------- Completed Workouts --------
  Future<void> insertCompletedWorkout(Workout workout) async {
    final db = await database;
    // Convert workout to JSON so we can store it in a single column
    String workoutJson = jsonEncode({
      'workoutName': workout.workoutName,
      'date': workout.date,
      'exercises': workout.exercises.map((e) => {
        'name': e.name,
        'target': e.targetOutput,
        'unit': e.type
      }).toList(),
      'exerciseResults': workout.exerciseResults.map((r) => {
        'name': r.name,
        'output': r.achievedOutput,
        'type': r.type
      }).toList(),
    });
    await db.insert('workouts', {'workoutJson': workoutJson});
  }

  // Retrieve all completed workouts from database
  Future<List<Workout>> getAllCompletedWorkouts() async {
    final db = await database;
    final result = await db.query('workouts');
    List<Workout> workouts = result.map((row) {
      final Map<String, dynamic> jsonMap = jsonDecode(row['workoutJson'] as String);
      return Workout.fromJson(jsonMap);
    }).toList();
    return workouts;
  }

  // ------- Downloaded Plans --------
  Future<void> insertDownloadedPlan(Workout plan) async {
    final db = await database;
    // Convert plan to JSON so we can store it
    String planJson = jsonEncode({
      'name': plan.workoutName,
      'exercises': plan.exercises.map((e) => {
        'name': e.name,
        'target': e.targetOutput,
        'unit': e.type
      }).toList()
      // We typically don’t need exerciseResults for a newly downloaded plan
      // because it hasn’t been performed yet. But you could store them if you want.
    });
    await db.insert('downloaded_plans', {'workoutJson': planJson});
  }

  Future<List<Workout>> getAllDownloadedPlans() async {
    final db = await database;
    final result = await db.query('downloaded_plans');
    return result.map((row) {
      final Map<String, dynamic> jsonMap = jsonDecode(row['workoutJson'] as String);
      return Workout.fromJson(jsonMap);
    }).toList();
  }
}
