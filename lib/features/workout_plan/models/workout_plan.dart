import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutPlan {
  final List<String> sequenceWorkoutIds;
  final int currentWorkoutIndex;
  final List<int> trainingWeekDays;
  final DateTime? trackingStartedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutPlan({
    required this.sequenceWorkoutIds,
    required this.currentWorkoutIndex,
    required this.trainingWeekDays,
    required this.trackingStartedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  int get safeCurrentWorkoutIndex {
    if (sequenceWorkoutIds.isEmpty) return 0;
    return currentWorkoutIndex % sequenceWorkoutIds.length;
  }

  String? get currentWorkoutId {
    if (sequenceWorkoutIds.isEmpty) return null;

    return sequenceWorkoutIds[safeCurrentWorkoutIndex];
  }

  int? get nextWorkoutIndex {
    if (sequenceWorkoutIds.isEmpty) return null;

    return (safeCurrentWorkoutIndex + 1) % sequenceWorkoutIds.length;
  }

  int indexForWorkoutId(String? workoutId) {
    if (workoutId == null || sequenceWorkoutIds.isEmpty) {
      return 0;
    }

    final index = sequenceWorkoutIds.indexOf(workoutId);
    return index >= 0 ? index : 0;
  }

  factory WorkoutPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WorkoutPlan.fromMap(doc.data() ?? const <String, dynamic>{});
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> data) {
    return WorkoutPlan(
      sequenceWorkoutIds: List<String>.from(data['sequenceWorkoutIds'] ?? []),
      currentWorkoutIndex: data['currentWorkoutIndex'] ?? 0,
      trainingWeekDays: List<int>.from(data['trainingWeekDays'] ?? []),
      trackingStartedAt: (data['trackingStartedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sequenceWorkoutIds': sequenceWorkoutIds,
      'currentWorkoutIndex': currentWorkoutIndex,
      'trainingWeekDays': trainingWeekDays,
      'trackingStartedAt': trackingStartedAt == null
          ? null
          : Timestamp.fromDate(trackingStartedAt!),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
