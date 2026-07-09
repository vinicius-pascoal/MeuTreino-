import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../../core/models/rest_timer_value.dart';
import '../../workouts/models/workout.dart';
import '../models/completed_set_input.dart';

class WorkoutSessionDraft {
  final String workoutId;
  final DateTime startedAt;
  final String? selectedExerciseId;
  final List<WorkoutSessionDraftSet> completedSets;
  final WorkoutSessionRestDraft? restTimer;

  const WorkoutSessionDraft({
    required this.workoutId,
    required this.startedAt,
    required this.selectedExerciseId,
    required this.completedSets,
    required this.restTimer,
  });

  factory WorkoutSessionDraft.fromJson(Map<String, dynamic> json) {
    final rawSets = json['completedSets'];
    final rawRestTimer = json['restTimer'];

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
      restTimer: rawRestTimer is Map
          ? WorkoutSessionRestDraft.fromJson(
              Map<String, dynamic>.from(rawRestTimer),
            )
          : null,
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

class WorkoutSessionRestDraft {
  final String workoutExerciseId;
  final int completedSetsCount;
  final RestTimerValue timer;

  const WorkoutSessionRestDraft({
    required this.workoutExerciseId,
    required this.completedSetsCount,
    required this.timer,
  });

  factory WorkoutSessionRestDraft.fromJson(Map<String, dynamic> json) {
    final rawTimer = json['timer'];

    return WorkoutSessionRestDraft(
      workoutExerciseId: json['workoutExerciseId'] as String? ?? '',
      completedSetsCount: (json['completedSetsCount'] as num?)?.toInt() ?? 0,
      timer: rawTimer is Map<String, dynamic>
          ? RestTimerValue.fromJson(rawTimer)
          : RestTimerValue.initial(
              initialSeconds: (json['initialSeconds'] as num?)?.toInt() ?? 0,
            ),
    );
  }

  bool get shouldPersist => timer.isModified;

  Map<String, dynamic> toJson() {
    return {
      'workoutExerciseId': workoutExerciseId,
      'completedSetsCount': completedSetsCount,
      'timer': timer.toJson(),
    };
  }
}

class WorkoutSessionDraftService {
  static const _keyPrefix = 'workout_session_draft_';
  static const _activeWorkoutIdKey = 'workout_session_active_workout_id';

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
    WorkoutSessionRestDraft? restTimer,
  }) async {
    final restTimerToPersist = restTimer?.shouldPersist == true ? restTimer : null;

    if (completedSets.isEmpty && restTimerToPersist == null) {
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
      if (restTimerToPersist != null) 'restTimer': restTimerToPersist.toJson(),
    });

    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>(_key(workout.id), payload),
        HomeWidget.saveWidgetData<String>(_activeWorkoutIdKey, workout.id),
      ]);
    } catch (_) {
      return;
    }
  }

  Future<String?> loadActiveWorkoutId() async {
    try {
      final workoutId = await HomeWidget.getWidgetData<String>(_activeWorkoutIdKey);
      if (workoutId == null || workoutId.trim().isEmpty) {
        return null;
      }

      final payload = await HomeWidget.getWidgetData<String>(_key(workoutId));
      if (payload == null || payload.trim().isEmpty) {
        await clearActiveWorkoutId();
        return null;
      }

      return workoutId;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveWorkoutId() async {
    try {
      await HomeWidget.saveWidgetData<String>(_activeWorkoutIdKey, null);
    } catch (_) {
      return;
    }
  }

  Future<void> clearDraft({required String workoutId}) async {
    try {
      final activeWorkoutId = await loadActiveWorkoutId();

      await HomeWidget.saveWidgetData<String>(_key(workoutId), null);

      if (activeWorkoutId == workoutId) {
        await clearActiveWorkoutId();
      }
    } catch (_) {
      return;
    }
  }
}
