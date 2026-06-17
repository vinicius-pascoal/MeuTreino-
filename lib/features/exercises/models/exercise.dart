import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String imageAsset;
  final String instructions;
  final DateTime? createdAt;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.imageAsset,
    required this.instructions,
    this.createdAt,
  });

  factory Exercise.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      muscleGroup: data['muscleGroup'] ?? '',
      imageAsset: data['imageAsset'] ?? '',
      instructions: data['instructions'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'muscleGroup': muscleGroup,
      'imageAsset': imageAsset,
      'instructions': instructions,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
