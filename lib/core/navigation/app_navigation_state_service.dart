import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

enum PersistedPageType {
  none,
  workoutPlan,
  autoWorkout,
  exerciseLibrary,
  workoutDetail,
  workoutSession,
  selectExercise,
  historyDetail,
}

class PersistedPageState {
  final PersistedPageType type;
  final String? workoutId;
  final String? sessionId;
  final int? nextOrder;

  const PersistedPageState({
    required this.type,
    this.workoutId,
    this.sessionId,
    this.nextOrder,
  });

  const PersistedPageState.none() : this(type: PersistedPageType.none);

  const PersistedPageState.workoutPlan()
    : this(type: PersistedPageType.workoutPlan);

  const PersistedPageState.autoWorkout()
    : this(type: PersistedPageType.autoWorkout);

  const PersistedPageState.exerciseLibrary()
    : this(type: PersistedPageType.exerciseLibrary);

  const PersistedPageState.workoutDetail({required String workoutId})
    : this(type: PersistedPageType.workoutDetail, workoutId: workoutId);

  const PersistedPageState.workoutSession({required String workoutId})
    : this(type: PersistedPageType.workoutSession, workoutId: workoutId);

  const PersistedPageState.selectExercise({
    required String workoutId,
    required int nextOrder,
  }) : this(
         type: PersistedPageType.selectExercise,
         workoutId: workoutId,
         nextOrder: nextOrder,
       );

  const PersistedPageState.historyDetail({required String sessionId})
    : this(type: PersistedPageType.historyDetail, sessionId: sessionId);

  bool get isNone => type == PersistedPageType.none;

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'workoutId': workoutId,
      'sessionId': sessionId,
      'nextOrder': nextOrder,
    };
  }

  factory PersistedPageState.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'] as String? ?? PersistedPageType.none.name;

    final type = PersistedPageType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => PersistedPageType.none,
    );

    return PersistedPageState(
      type: type,
      workoutId: map['workoutId'] as String?,
      sessionId: map['sessionId'] as String?,
      nextOrder: (map['nextOrder'] as num?)?.toInt(),
    );
  }
}

class AppNavigationStateService {
  static const _selectedTabKey = 'app_shell_selected_tab';
  static const _pageStackKey = 'app_navigation_page_stack';

  final FirebaseAuth _auth;

  AppNavigationStateService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  String _scopedKey(String key) {
    final userId = _auth.currentUser?.uid;
    return userId == null ? key : '${userId}_$key';
  }

  Future<int> loadSelectedTab() async {
    try {
      final value = await HomeWidget.getWidgetData<int>(_scopedKey(_selectedTabKey));
      return value ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> saveSelectedTab(int index) async {
    try {
      await HomeWidget.saveWidgetData<int>(_scopedKey(_selectedTabKey), index);
    } catch (_) {
      return;
    }
  }

  Future<List<PersistedPageState>> loadPageStack() async {
    try {
      final payload = await HomeWidget.getWidgetData<String>(
        _scopedKey(_pageStackKey),
      );

      if (payload == null || payload.trim().isEmpty) {
        return <PersistedPageState>[];
      }

      final decoded = jsonDecode(payload);
      if (decoded is! List) {
        await clearPageStack();
        return <PersistedPageState>[];
      }

      return decoded
          .whereType<Map>()
          .map((item) => PersistedPageState.fromMap(Map<String, dynamic>.from(item)))
          .where((item) => !item.isNone)
          .toList();
    } catch (_) {
      return <PersistedPageState>[];
    }
  }

  Future<PersistedPageState> loadCurrentPage() async {
    final stack = await loadPageStack();
    return stack.isEmpty ? const PersistedPageState.none() : stack.last;
  }

  Future<void> clearPageStack() async {
    try {
      await HomeWidget.saveWidgetData<String>(_scopedKey(_pageStackKey), null);
    } catch (_) {
      return;
    }
  }

  Future<T?> pushTrackedPage<T>({
    required BuildContext context,
    required PersistedPageState pageState,
    required WidgetBuilder builder,
  }) async {
    final stack = await loadPageStack();
    stack.add(pageState);
    await _savePageStack(stack);

    try {
      return await Navigator.of(context).push<T>(
        MaterialPageRoute(builder: builder),
      );
    } finally {
      await _popTrackedPage();
    }
  }

  Future<void> _savePageStack(List<PersistedPageState> stack) async {
    final payload = jsonEncode(stack.map((item) => item.toMap()).toList());

    try {
      await HomeWidget.saveWidgetData<String>(_scopedKey(_pageStackKey), payload);
    } catch (_) {
      return;
    }
  }

  Future<void> _popTrackedPage() async {
    final stack = await loadPageStack();

    if (stack.isEmpty) {
      await clearPageStack();
      return;
    }

    stack.removeLast();

    if (stack.isEmpty) {
      await clearPageStack();
      return;
    }

    await _savePageStack(stack);
  }
}
