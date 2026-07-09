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
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList(),
        );
  }

  Future<List<Workout>> getWorkoutsOnce() async {
    final snapshot = await _workoutsCollection.orderBy('createdAt').get();

    return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
  }

  Future<Workout?> getWorkoutById({required String workoutId}) async {
    final doc = await _workoutsCollection.doc(workoutId).get();
    if (!doc.exists) return null;
    return Workout.fromFirestore(doc);
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

  Future<String> createWorkoutReturningId({
    required String name,
    required String description,
    required List<String> weekDays,
  }) async {
    final docRef = await _workoutsCollection.add({
      'name': name.trim(),
      'description': description.trim(),
      'weekDays': weekDays,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> updateWorkout({
    required String workoutId,
    required String name,
    required String description,
  }) async {
    await _workoutsCollection.doc(workoutId).update({
      'name': name.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteWorkout({required String workoutId}) async {
    final exercisesSnapshot = await _workoutsCollection
        .doc(workoutId)
        .collection('exercises')
        .get();

    final batch = _firestore.batch();

    for (final doc in exercisesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_workoutsCollection.doc(workoutId));

    await batch.commit();
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
      'muscleRegion': exercise.muscleRegion,
      'movementPattern': exercise.movementPattern,
      'equipment': exercise.equipment,
      'isCompound': exercise.isCompound,
      'priority': exercise.priority,
      'imageAsset': exercise.imageAsset,
      'order': order,
      'sets': sets,
      'targetReps': targetReps,
      'restSeconds': restSeconds,
      'currentWeight': currentWeight,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addExercisesToWorkoutBatch({
    required String workoutId,
    required List<Exercise> exercises,
    required int sets,
    required String targetReps,
    required int restSeconds,
    required double currentWeight,
  }) async {
    final batch = _firestore.batch();

    for (int index = 0; index < exercises.length; index++) {
      final exercise = exercises[index];

      final docRef = _workoutsCollection
          .doc(workoutId)
          .collection('exercises')
          .doc();

      batch.set(docRef, {
        'exerciseLibraryId': exercise.id,
        'name': exercise.name,
        'muscleGroup': exercise.muscleGroup,
        'muscleRegion': exercise.muscleRegion,
        'movementPattern': exercise.movementPattern,
        'equipment': exercise.equipment,
        'isCompound': exercise.isCompound,
        'priority': exercise.priority,
        'imageAsset': exercise.imageAsset,
        'order': index + 1,
        'sets': sets,
        'targetReps': targetReps,
        'restSeconds': restSeconds,
        'currentWeight': currentWeight,
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> updateWorkoutExercise({
    required String workoutId,
    required String workoutExerciseId,
    required int sets,
    required String targetReps,
    required int restSeconds,
    required double currentWeight,
    required String notes,
  }) async {
    await _workoutsCollection
        .doc(workoutId)
        .collection('exercises')
        .doc(workoutExerciseId)
        .update({
          'sets': sets,
          'targetReps': targetReps.trim(),
          'restSeconds': restSeconds,
          'currentWeight': currentWeight,
          'notes': notes.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> replaceWorkoutExercise({
    required String workoutId,
    required String workoutExerciseId,
    required Exercise exercise,
    required double currentWeight,
  }) async {
    await _workoutsCollection
        .doc(workoutId)
        .collection('exercises')
        .doc(workoutExerciseId)
        .update({
          'exerciseLibraryId': exercise.id,
          'name': exercise.name,
          'muscleGroup': exercise.muscleGroup,
          'muscleRegion': exercise.muscleRegion,
          'movementPattern': exercise.movementPattern,
          'equipment': exercise.equipment,
          'isCompound': exercise.isCompound,
          'priority': exercise.priority,
          'imageAsset': exercise.imageAsset,
          'currentWeight': currentWeight,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteWorkoutExercise({
    required String workoutId,
    required String workoutExerciseId,
  }) async {
    await _workoutsCollection
        .doc(workoutId)
        .collection('exercises')
        .doc(workoutExerciseId)
        .delete();
  }
}
