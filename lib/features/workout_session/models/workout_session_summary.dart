import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSessionSummary {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String workoutDateKey;
  final int durationSeconds;
  final double totalVolume;
  final int totalSets;
  final String status;

  WorkoutSessionSummary({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.finishedAt,
    required this.workoutDateKey,
    required this.durationSeconds,
    required this.totalVolume,
    required this.totalSets,
    required this.status,
  });

  factory WorkoutSessionSummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return WorkoutSessionSummary(
      id: doc.id,
      workoutId: data['workoutId'] ?? '',
      workoutName: data['workoutName'] ?? '',
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
      workoutDateKey: data['workoutDateKey'] ?? '',
      durationSeconds: data['durationSeconds'] ?? 0,
      totalVolume: ((data['totalVolume'] ?? 0) as num).toDouble(),
      totalSets: data['totalSets'] ?? 0,
      status: data['status'] ?? '',
    );
  }
}
