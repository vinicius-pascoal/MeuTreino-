import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../exercises/models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';

class WorkoutService {
  WorkoutService({FirebaseFirestore? firestore, FirebaseAuth? auth})
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

  CollectionReference<Map<String, dynamic>> get _workoutsCollection {
    return _firestore.collection('users').doc(_userId).collection('workouts');
  }

  Stream<List<Workout>> watchWorkouts() {
    return _workoutsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList(),
        );
  }

  Future<void> createWorkout({
    required String name,
    required String description,
    required List<String> weekDays,
  }) async {
    await _workoutsCollection.add({
      'name': name.trim(),
      'description': description.trim(),
      'weekDays': weekDays,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<WorkoutExercise>> watchWorkoutExercises({
    required String workoutId,
  }) {
    return _workoutsCollection
        .doc(workoutId)
        .collection('exercises')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutExercise.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addExerciseToWorkout({
    required String workoutId,
    required Exercise exercise,
    required int order,
    required int sets,
    required String targetReps,
    required int restSeconds,
    required double currentWeight,
    String notes = '',
  }) async {
    await _workoutsCollection.doc(workoutId).collection('exercises').add({
      'exerciseLibraryId': exercise.id,
      'name': exercise.name,
      'muscleGroup': exercise.muscleGroup,
      'imageAsset': exercise.imageAsset,
      'order': order,
      'sets': sets,
      'targetReps': targetReps,
      'restSeconds': restSeconds,
      'currentWeight': currentWeight,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
