import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String muscleRegion;
  final String movementPattern;
  final String equipment;
  final bool isCompound;
  final int priority;
  final String imageAsset;
  final String instructions;
  final DateTime? createdAt;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.muscleRegion,
    required this.movementPattern,
    required this.equipment,
    required this.isCompound,
    required this.priority,
    required this.imageAsset,
    required this.instructions,
    this.createdAt,
  });

  bool get isBodyweight => equipment.trim().toLowerCase() == 'peso corporal';

  factory Exercise.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      muscleGroup: data['muscleGroup'] ?? '',
      muscleRegion: data['muscleRegion'] ?? '',
      movementPattern: data['movementPattern'] ?? '',
      equipment: data['equipment'] ?? '',
      isCompound: data['isCompound'] ?? false,
      priority: (data['priority'] as num?)?.toInt() ?? 3,
      imageAsset: data['imageAsset'] ?? '',
      instructions: data['instructions'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'muscleGroup': muscleGroup,
      'muscleRegion': muscleRegion,
      'movementPattern': movementPattern,
      'equipment': equipment,
      'isCompound': isCompound,
      'priority': priority,
      'imageAsset': imageAsset,
      'instructions': instructions,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
