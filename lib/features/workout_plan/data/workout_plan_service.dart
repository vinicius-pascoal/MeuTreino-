import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/workout_plan.dart';

class WorkoutPlanService {
  WorkoutPlanService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get planRef {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('training_plan')
        .doc('main');
  }

  Stream<WorkoutPlan?> watchPlan() {
    return planRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      return WorkoutPlan.fromFirestore(doc);
    });
  }

  Future<void> savePlan({
    required List<String> sequenceWorkoutIds,
    required List<int> trainingWeekDays,
  }) async {
    await planRef.set({
      'sequenceWorkoutIds': sequenceWorkoutIds,
      'currentWorkoutIndex': 0,
      'trainingWeekDays': trainingWeekDays,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
