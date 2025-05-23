import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  String _generateRandomCode() {
    final random = Random();
    final codeInt = random.nextInt(900000) + 100000;
    return codeInt.toString();
  }

  // Create a new workout code
  Future<String> createWorkoutCode({
    required String workoutType,
    required List<Map<String, dynamic>> exercises,
  }) async {
    // Generate a unique code
    String code;
    bool isUnique = false;

    do {
      code = _generateRandomCode();
      final docSnapshot =
          await _firestore.collection('group_workouts').doc(code).get();
      isUnique = !docSnapshot.exists;
    } while (!isUnique);

    // Get current user
    final userId = _auth.currentUser!.uid;

    // Create workout document
    await _firestore.collection('group_workouts').doc(code).set({
      'workoutCode': code,
      'workoutType': workoutType,
      'exercises': exercises,
      'isCompetitive': workoutType == 'competitive',
      'participants': [userId],
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt':
          FieldValue.serverTimestamp().toString().replaceAll(' ', 'T') + 'Z',
    });

    return code;
  }

  // Validate a workout code
  Future<Map<String, dynamic>?> validateWorkoutCode(
    String code,
    String expectedType,
  ) async {
    try {
      final docSnapshot =
          await _firestore.collection('group_workouts').doc(code).get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data()!;


      if (data['workoutType'] != expectedType) {
        return null;
      }

      // Check if code is expired (24 hours)
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(createdAt);

      if (diff.inHours > 24) {
        return null; // Code expired
      }

      return data;
    } catch (e) {
      print('Error validating code: $e');
      return null;
    }
  }
}
