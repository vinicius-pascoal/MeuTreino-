import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final String name;
  final String description;
  final List<String> weekDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.weekDays,
    this.createdAt,
    this.updatedAt,
  });

  factory Workout.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Workout(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      weekDays: List<String>.from(data['weekDays'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
