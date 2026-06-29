import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../workouts/models/workout.dart';
import '../models/completed_set_input.dart';

class WorkoutSessionDraft {
  final String workoutId;
  final DateTime startedAt;
  final String? selectedExerciseId;
  final List<WorkoutSessionDraftSet> completedSets;

  const WorkoutSessionDraft({
    required this.workoutId,
    required this.startedAt,
    required this.selectedExerciseId,
    required this.completedSets,
  });

  factory WorkoutSessionDraft.fromJson(Map<String, dynamic> json) {
    final rawSets = json['completedSets'];

    return WorkoutSessionDraft(
      workoutId: json['workoutId'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      selectedExerciseId: json['selectedExerciseId'] as String?,
      completedSets: rawSets is List
          ? rawSets
                .whereType<Map>()
                .map(
                  (item) => WorkoutSessionDraftSet.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where((item) => item.workoutExerciseId.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

class WorkoutSessionDraftSet {
  final String workoutExerciseId;
  final int setNumber;
  final double weight;
  final int reps;

  const WorkoutSessionDraftSet({
    required this.workoutExerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

  factory WorkoutSessionDraftSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionDraftSet(
      workoutExerciseId: json['workoutExerciseId'] as String? ?? '',
      setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkoutSessionDraftService {
  static const _keyPrefix = 'workout_session_draft_';

  String _key(String workoutId) => '$_keyPrefix$workoutId';

  Future<WorkoutSessionDraft?> loadDraft({required String workoutId}) async {
    try {
      final payload = await HomeWidget.getWidgetData<String>(_key(workoutId));

      if (payload == null || payload.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        await clearDraft(workoutId: workoutId);
        return null;
      }

      final draft = WorkoutSessionDraft.fromJson(decoded);

      if (draft.workoutId != workoutId) {
        return null;
      }

      return draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraft({
    required Workout workout,
    required DateTime startedAt,
    required String? selectedExerciseId,
    required List<CompletedSetInput> completedSets,
  }) async {
    if (completedSets.isEmpty) {
      return;
    }

    final payload = jsonEncode({
      'version': 1,
      'workoutId': workout.id,
      'workoutName': workout.name,
      'startedAt': startedAt.toIso8601String(),
      'selectedExerciseId': selectedExerciseId,
      'savedAt': DateTime.now().toIso8601String(),
      'completedSets': completedSets
          .map(
            (item) => {
              'workoutExerciseId': item.exercise.id,
              'setNumber': item.setNumber,
              'weight': item.weight,
              'reps': item.reps,
            },
          )
          .toList(),
    });

    try {
      await HomeWidget.saveWidgetData<String>(_key(workout.id), payload);
    } catch (_) {
      return;
    }
  }

  Future<void> clearDraft({required String workoutId}) async {
    try {
      await HomeWidget.saveWidgetData<String>(_key(workoutId), null);
    } catch (_) {
      return;
    }
  }
}
