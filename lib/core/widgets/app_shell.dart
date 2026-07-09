import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/exercises/presentation/exercise_library_page.dart';
import '../../features/exercises/presentation/select_exercise_page.dart';
import '../../features/history/presentation/history_detail_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/progress/presentation/progress_page.dart';
import '../../features/workout_automation/presentation/auto_workout_page.dart';
import '../../features/workout_plan/presentation/workout_plan_page.dart';
import '../../features/workout_session/data/workout_session_draft_service.dart';
import '../../features/workout_session/data/workout_session_service.dart';
import '../../features/workout_session/presentation/workout_session_page.dart';
import '../../features/workouts/data/workout_service.dart';
import '../../features/workouts/presentation/workout_detail_page.dart';
import '../../features/workouts/presentation/workouts_page.dart';
import '../navigation/app_navigation_state_service.dart';
import 'app_bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _navigationStateService = AppNavigationStateService();
  final _workoutService = WorkoutService();
  final _workoutSessionService = WorkoutSessionService();
  final _draftService = WorkoutSessionDraftService();
  late final PageController _pageController;

  int _currentIndex = 0;
  bool _didRestoreInitialPage = false;

  static const _pages = [
    _ShellTab(storageKey: 'home-tab', child: HomePage()),
    _ShellTab(storageKey: 'workouts-tab', child: WorkoutsPage()),
    _ShellTab(storageKey: 'history-tab', child: HistoryPage()),
    _ShellTab(storageKey: 'progress-tab', child: ProgressPage()),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    unawaited(_restoreShellState());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _selectTab(int index) async {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
    unawaited(_navigationStateService.saveSelectedTab(index));

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  int _normalizeTabIndex(int index) {
    if (index < 0) return 0;
    if (index >= _pages.length) return _pages.length - 1;
    return index;
  }

  Future<void> _restoreShellState() async {
    final savedTab = _normalizeTabIndex(
      await _navigationStateService.loadSelectedTab(),
    );

    if (!mounted) return;

    if (savedTab != _currentIndex) {
      setState(() {
        _currentIndex = savedTab;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(savedTab);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreInitialPage());
    });
  }

  Future<void> _restoreInitialPage() async {
    if (_didRestoreInitialPage || !mounted) return;
    _didRestoreInitialPage = true;

    final savedPage = await _navigationStateService.loadCurrentPage();

    if (!mounted) return;

    if (!savedPage.isNone) {
      final page = await _buildPageForState(savedPage);

      if (!mounted) return;

      if (page != null) {
        await _navigationStateService.clearPageStack();

        unawaited(
          _navigationStateService.pushTrackedPage(
            context: context,
            pageState: savedPage,
            builder: (_) => page,
          ),
        );
        return;
      }

      await _navigationStateService.clearPageStack();
    }

    final activeWorkoutId = await _draftService.loadActiveWorkoutId();
    if (!mounted || activeWorkoutId == null || activeWorkoutId.isEmpty) return;

    final workout = await _workoutService.getWorkoutById(
      workoutId: activeWorkoutId,
    );

    if (!mounted) return;

    if (workout == null) {
      await _draftService.clearActiveWorkoutId();
      return;
    }

    unawaited(
      _navigationStateService.pushTrackedPage(
        context: context,
        pageState: PersistedPageState.workoutSession(workoutId: workout.id),
        builder: (_) => WorkoutSessionPage(workout: workout),
      ),
    );
  }

  Future<Widget?> _buildPageForState(PersistedPageState state) async {
    switch (state.type) {
      case PersistedPageType.none:
        return null;
      case PersistedPageType.workoutPlan:
        return const WorkoutPlanPage();
      case PersistedPageType.autoWorkout:
        return const AutoWorkoutPage();
      case PersistedPageType.exerciseLibrary:
        return const ExerciseLibraryPage();
      case PersistedPageType.workoutDetail:
        return _buildWorkoutDetailPage(state.workoutId);
      case PersistedPageType.workoutSession:
        return _buildWorkoutSessionPage(state.workoutId);
      case PersistedPageType.selectExercise:
        if (state.workoutId == null) return null;

        return SelectExercisePage(
          workoutId: state.workoutId!,
          nextOrder: state.nextOrder ?? DateTime.now().millisecondsSinceEpoch,
        );
      case PersistedPageType.historyDetail:
        return _buildHistoryDetailPage(state.sessionId);
    }
  }

  Future<Widget?> _buildWorkoutDetailPage(String? workoutId) async {
    if (workoutId == null || workoutId.isEmpty) return null;

    final workout = await _workoutService.getWorkoutById(workoutId: workoutId);
    if (workout == null) return null;

    return WorkoutDetailPage(workout: workout);
  }

  Future<Widget?> _buildWorkoutSessionPage(String? workoutId) async {
    if (workoutId == null || workoutId.isEmpty) return null;

    final workout = await _workoutService.getWorkoutById(workoutId: workoutId);
    if (workout == null) return null;

    return WorkoutSessionPage(workout: workout);
  }

  Future<Widget?> _buildHistoryDetailPage(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) return null;

    final session = await _workoutSessionService.getSessionById(
      sessionId: sessionId,
    );
    if (session == null) return null;

    return HistoryDetailPage(session: session);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (_currentIndex == index) return;

            setState(() {
              _currentIndex = index;
            });
            unawaited(_navigationStateService.saveSelectedTab(index));
          },
          children: _pages,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AppBottomNavBar(
            currentIndex: _currentIndex,
            onItemSelected: _selectTab,
          ),
        ),
      ],
    );
  }
}

class _ShellTab extends StatelessWidget {
  final String storageKey;
  final Widget child;

  const _ShellTab({required this.storageKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: PageStorageKey(storageKey),
      child: child,
    );
  }
}
