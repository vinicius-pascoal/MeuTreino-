import 'package:flutter/material.dart';

import '../../features/history/presentation/history_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/progress/presentation/progress_page.dart';
import '../../features/workouts/presentation/workouts_page.dart';
import 'app_bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;

  int _currentIndex = 0;

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

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
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
