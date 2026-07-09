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

  Future<WorkoutPlan?> getPlanOnce() async {
    final doc = await planRef.get();
    if (!doc.exists) return null;
    return WorkoutPlan.fromFirestore(doc);
  }

  Future<void> savePlan({
    required List<String> sequenceWorkoutIds,
    required List<int> trainingWeekDays,
  }) async {
    final existingDoc = await planRef.get();
    final existingData = existingDoc.data() ?? const <String, dynamic>{};
    final existingPlan = existingDoc.exists
        ? WorkoutPlan.fromMap(existingData)
        : null;
    final currentWorkoutId = existingPlan?.currentWorkoutId;
    final nextCurrentWorkoutIndex = sequenceWorkoutIds.indexOf(
      currentWorkoutId ?? '',
    );
    final sortedTrainingWeekDays = [...trainingWeekDays]..sort();

    await planRef.set({
      'sequenceWorkoutIds': sequenceWorkoutIds,
      'currentWorkoutIndex': nextCurrentWorkoutIndex >= 0
          ? nextCurrentWorkoutIndex
          : 0,
      'trainingWeekDays': sortedTrainingWeekDays,
      'trackingStartedAt':
          existingData['trackingStartedAt'] ??
          existingData['createdAt'] ??
          existingData['updatedAt'] ??
          FieldValue.serverTimestamp(),
      'createdAt':
          existingData['createdAt'] ??
          existingData['updatedAt'] ??
          FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> advanceToNextWorkout() async {
    return _firestore.runTransaction((transaction) async {
      final planSnapshot = await transaction.get(planRef);
      final planData = planSnapshot.data();

      if (planData == null) {
        return false;
      }

      final plan = WorkoutPlan.fromMap(planData);
      final nextWorkoutIndex = plan.nextWorkoutIndex;

      if (nextWorkoutIndex == null) {
        return false;
      }

      transaction.update(planRef, {
        'currentWorkoutIndex': nextWorkoutIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }
}
