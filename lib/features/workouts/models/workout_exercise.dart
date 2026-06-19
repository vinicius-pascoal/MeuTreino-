import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutExercise {
  final String id;
  final String exerciseLibraryId;
  final String name;
  final String muscleGroup;
  final String muscleRegion;
  final String movementPattern;
  final String equipment;
  final bool isCompound;
  final int priority;
  final String imageAsset;
  final int order;
  final int sets;
  final String targetReps;
  final int restSeconds;
  final double currentWeight;
  final String notes;

  WorkoutExercise({
    required this.id,
    required this.exerciseLibraryId,
    required this.name,
    required this.muscleGroup,
    required this.muscleRegion,
    required this.movementPattern,
    required this.equipment,
    required this.isCompound,
    required this.priority,
    required this.imageAsset,
    required this.order,
    required this.sets,
    required this.targetReps,
    required this.restSeconds,
    required this.currentWeight,
    required this.notes,
  });

  factory WorkoutExercise.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return WorkoutExercise(
      id: doc.id,
      exerciseLibraryId: data['exerciseLibraryId'] ?? '',
      name: data['name'] ?? '',
      muscleGroup: data['muscleGroup'] ?? '',
      muscleRegion: data['muscleRegion'] ?? '',
      movementPattern: data['movementPattern'] ?? '',
      equipment: data['equipment'] ?? '',
      isCompound: data['isCompound'] ?? false,
      priority: (data['priority'] as num?)?.toInt() ?? 3,
      imageAsset: data['imageAsset'] ?? '',
      order: data['order'] ?? 0,
      sets: data['sets'] ?? 3,
      targetReps: data['targetReps'] ?? '8-10',
      restSeconds: data['restSeconds'] ?? 90,
      currentWeight: ((data['currentWeight'] ?? 0) as num).toDouble(),
      notes: data['notes'] ?? '',
    );
  }
}
