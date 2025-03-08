import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/workout_model.dart';

class DBService {
  DBService._privateConstructor();
  static final DBService instance = DBService._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    String path = join(dbPath, 'workouts.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutJson TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE downloaded_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutJson TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertCompletedWorkout(Workout workout) async {
    final db = await database;
    String workoutJson = jsonEncode(workout.toJson());
    await db.insert('workouts', {'workoutJson': workoutJson});
  }

  Future<List<Workout>> getAllCompletedWorkouts() async {
    final db = await database;
    final result = await db.query('workouts');
    return result.map((row) {
      final jsonMap = jsonDecode(row['workoutJson'] as String);
      return Workout.fromJson(jsonMap);
    }).toList();
  }

  Future<void> insertDownloadedPlan(Workout plan) async {
    final db = await database;
    String planJson = jsonEncode(plan.toJson());
    await db.insert('downloaded_plans', {'workoutJson': planJson});
  }

  Future<List<Workout>> getAllDownloadedPlans() async {
    final db = await database;
    final result = await db.query('downloaded_plans');
    return result.map((row) {
      final jsonMap = jsonDecode(row['workoutJson'] as String);
      return Workout.fromJson(jsonMap);
    }).toList();
  }
}
