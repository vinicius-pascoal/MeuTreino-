import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutPlan {
  final List<String> sequenceWorkoutIds;
  final int currentWorkoutIndex;
  final List<int> trainingWeekDays;

  WorkoutPlan({
    required this.sequenceWorkoutIds,
    required this.currentWorkoutIndex,
    required this.trainingWeekDays,
  });

  String? get currentWorkoutId {
    if (sequenceWorkoutIds.isEmpty) return null;

    final safeIndex = currentWorkoutIndex % sequenceWorkoutIds.length;
    return sequenceWorkoutIds[safeIndex];
  }

  factory WorkoutPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return WorkoutPlan(
      sequenceWorkoutIds: List<String>.from(data['sequenceWorkoutIds'] ?? []),
      currentWorkoutIndex: data['currentWorkoutIndex'] ?? 0,
      trainingWeekDays: List<int>.from(data['trainingWeekDays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sequenceWorkoutIds': sequenceWorkoutIds,
      'currentWorkoutIndex': currentWorkoutIndex,
      'trainingWeekDays': trainingWeekDays,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
