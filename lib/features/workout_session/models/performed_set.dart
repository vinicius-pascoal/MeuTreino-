import 'package:cloud_firestore/cloud_firestore.dart';

class PerformedSet {
  final String id;
  final String workoutExerciseId;
  final String exerciseLibraryId;
  final String exerciseName;
  final String muscleGroup;
  final int setNumber;
  final double weight;
  final int reps;
  final double volume;
  final DateTime? completedAt;

  PerformedSet({
    required this.id,
    required this.workoutExerciseId,
    required this.exerciseLibraryId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.volume,
    required this.completedAt,
  });

  factory PerformedSet.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PerformedSet(
      id: doc.id,
      workoutExerciseId: data['workoutExerciseId'] ?? '',
      exerciseLibraryId: data['exerciseLibraryId'] ?? '',
      exerciseName: data['exerciseName'] ?? '',
      muscleGroup: data['muscleGroup'] ?? '',
      setNumber: data['setNumber'] ?? 0,
      weight: ((data['weight'] ?? 0) as num).toDouble(),
      reps: data['reps'] ?? 0,
      volume: ((data['volume'] ?? 0) as num).toDouble(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}
