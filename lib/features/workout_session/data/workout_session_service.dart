import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/date_key.dart';
import '../../workout_plan/models/workout_plan.dart';
import '../../workouts/models/workout.dart';
import '../models/completed_set_input.dart';
import '../models/performed_set.dart';
import '../models/workout_session_summary.dart';

class WorkoutSessionService {
  WorkoutSessionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
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

  CollectionReference<Map<String, dynamic>> get _sessionsCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('workout_sessions');
  }

  CollectionReference<Map<String, dynamic>> get _workoutsCollection {
    return _firestore.collection('users').doc(_userId).collection('workouts');
  }

  CollectionReference<Map<String, dynamic>> get _exerciseStatsCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('exercise_stats');
  }

  DocumentReference<Map<String, dynamic>> get _planRef {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('training_plan')
        .doc('main');
  }

  Stream<List<WorkoutSessionSummary>> watchRecentSessions({int limit = 50}) {
    return _sessionsCollection
        .orderBy('finishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutSessionSummary.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<WorkoutSessionSummary>> watchSessionsBetween({
    required DateTime start,
    required DateTime end,
  }) {
    final startKey = DateKey.fromDate(start);
    final endKey = DateKey.fromDate(end);

    return _sessionsCollection
        .where('workoutDateKey', isGreaterThanOrEqualTo: startKey)
        .where('workoutDateKey', isLessThanOrEqualTo: endKey)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutSessionSummary.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<PerformedSet>> watchSessionSets({required String sessionId}) {
    return _sessionsCollection
        .doc(sessionId)
        .collection('sets')
        .orderBy('completedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PerformedSet.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<WorkoutSessionSummary>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final startKey = DateKey.fromDate(start);
    final endKey = DateKey.fromDate(end);

    final snapshot = await _sessionsCollection
        .where('workoutDateKey', isGreaterThanOrEqualTo: startKey)
        .where('workoutDateKey', isLessThanOrEqualTo: endKey)
        .get();

    return snapshot.docs
        .map((doc) => WorkoutSessionSummary.fromFirestore(doc))
        .toList();
  }

  Future<List<PerformedSet>> getSessionSets({required String sessionId}) async {
    final snapshot = await _sessionsCollection
        .doc(sessionId)
        .collection('sets')
        .orderBy('completedAt')
        .get();

    return snapshot.docs.map((doc) => PerformedSet.fromFirestore(doc)).toList();
  }

  Future<Map<String, List<PerformedSet>>> getSetsBySessionIds(
    List<String> sessionIds,
  ) async {
    final entries = await Future.wait(
      sessionIds.map((sessionId) async {
        final sets = await getSessionSets(sessionId: sessionId);
        return MapEntry(sessionId, sets);
      }),
    );

    return {for (final entry in entries) entry.key: entry.value};
  }

  Future<void> finishWorkoutSession({
    required Workout workout,
    required DateTime startedAt,
    required List<CompletedSetInput> completedSets,
  }) async {
    if (completedSets.isEmpty) {
      throw Exception('Nenhuma série foi registrada.');
    }

    final finishedAt = DateTime.now();
    final durationSeconds = finishedAt.difference(startedAt).inSeconds;
    final totalVolume = completedSets.fold<double>(
      0,
      (sum, item) => sum + item.volume,
    );
    final totalSets = completedSets.length;
    final workoutDateKey = DateKey.fromDate(finishedAt);

    final sessionRef = _sessionsCollection.doc();

    final latestSetByWorkoutExerciseId = <String, CompletedSetInput>{};
    final latestSetByExerciseLibraryId = <String, CompletedSetInput>{};

    for (final item in completedSets) {
      latestSetByWorkoutExerciseId[item.exercise.id] = item;
      latestSetByExerciseLibraryId[item.exercise.exerciseLibraryId] = item;
    }

    await _firestore.runTransaction((transaction) async {
      final planSnapshot = await transaction.get(_planRef);
      final planData = planSnapshot.data();

      transaction.set(sessionRef, {
        'workoutId': workout.id,
        'workoutName': workout.name,
        'startedAt': Timestamp.fromDate(startedAt),
        'finishedAt': Timestamp.fromDate(finishedAt),
        'workoutDateKey': workoutDateKey,
        'durationSeconds': durationSeconds,
        'totalVolume': totalVolume,
        'totalSets': totalSets,
        'status': 'finished',
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final item in completedSets) {
        final setRef = sessionRef.collection('sets').doc();

        transaction.set(setRef, {
          'workoutExerciseId': item.exercise.id,
          'exerciseLibraryId': item.exercise.exerciseLibraryId,
          'exerciseName': item.exercise.name,
          'muscleGroup': item.exercise.muscleGroup,
          'setNumber': item.setNumber,
          'weight': item.weight,
          'reps': item.reps,
          'volume': item.volume,
          'completedAt': Timestamp.fromDate(finishedAt),
        });
      }

      for (final entry in latestSetByWorkoutExerciseId.entries) {
        final item = entry.value;
        final exerciseRef = _workoutsCollection
            .doc(workout.id)
            .collection('exercises')
            .doc(entry.key);

        transaction.update(exerciseRef, {
          'currentWeight': item.weight,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      for (final entry in latestSetByExerciseLibraryId.entries) {
        final item = entry.value;

        transaction.set(_exerciseStatsCollection.doc(entry.key), {
          'exerciseLibraryId': item.exercise.exerciseLibraryId,
          'exerciseName': item.exercise.name,
          'lastUsedWeight': item.weight,
          'lastWorkoutId': workout.id,
          'lastWorkoutName': workout.name,
          'lastWorkoutExerciseId': item.exercise.id,
          'lastPerformedAt': Timestamp.fromDate(finishedAt),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (planData != null) {
        final plan = WorkoutPlan.fromMap(planData);
        final nextWorkoutIndex = plan.nextWorkoutIndex;

        if (nextWorkoutIndex != null) {
          transaction.update(_planRef, {
            'currentWorkoutIndex': nextWorkoutIndex,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }
}
