import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> validateWorkoutCode(
      String code, String workoutType // 'collaborative' or 'competitive'
      ) async {
    try {
      // Query Firestore for the workout code
      final querySnapshot = await _firestore
          .collection('workout_codes')
          .where('code', isEqualTo: code)
          .where('type', isEqualTo: workoutType)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      // If no matching code found
      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // Get the first (and only) document
      final workoutDoc = querySnapshot.docs.first;
      final workoutData = workoutDoc.data();

      // Check if the code is still valid
      if (workoutData['expiresAt'] != null) {
        final expiresAt = (workoutData['expiresAt'] as Timestamp).toDate();
        if (expiresAt.isBefore(DateTime.now())) {
          // Code has expired
          return null;
        }
      }

      // Optional: Check max participants
      if (workoutData['currentParticipants'] >=
          workoutData['maxParticipants']) {
        return null;
      }

      // Update participant count
      await workoutDoc.reference.update({
        'currentParticipants': FieldValue.increment(1),
        'participants': FieldValue.arrayUnion([_auth.currentUser!.uid])
      });

      return workoutData;
    } catch (e) {
      print('Error validating workout code: $e');
      return null;
    }
  }

  // Method to create a new workout code (for admin/workout creation)
  Future<String> createWorkoutCode({
    required String workoutType,
    required int maxParticipants,
    DateTime? expiresAt,
  }) async {
    // Generate a 6-digit code
    final code = _generateSixDigitCode();

    await _firestore.collection('workout_codes').add({
      'code': code,
      'type': workoutType,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt ??
          Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
      'maxParticipants': maxParticipants,
      'currentParticipants': 0,
      'active': true,
      'participants': [],
      'createdBy': _auth.currentUser!.uid,
    });

    return code;
  }

  String _generateSixDigitCode() {
    // Generate a random 6-digit code
    return (100000 + Random().nextInt(900000)).toString();
  }
}
