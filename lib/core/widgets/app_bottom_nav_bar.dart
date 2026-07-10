import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/navigation/app_navigation_state_service.dart';
import '../../features/workout_automation/presentation/auto_workout_page.dart';
import '../../features/workout_plan/presentation/workout_plan_page.dart';

const double _navIconSize = 18;

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  static final _navigationStateService = AppNavigationStateService();

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  static const _primaryDestinations = [
    _NavDestinationData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    _NavDestinationData(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Treinos',
    ),
    _NavDestinationData(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Evol.',
    ),
    _NavDestinationData(
      icon: Icons.calendar_view_week_outlined,
      activeIcon: Icons.calendar_view_week_rounded,
      label: 'Semana',
    ),
    _NavDestinationData(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'Auto',
    ),
  ];

  Future<void> _openOverlayPage({
    required BuildContext context,
    required Widget page,
    required PersistedPageState pageState,
  }) async {
    await _navigationStateService.pushTrackedPage(
      context: context,
      pageState: pageState,
      builder: (_) => page,
    );
  }

  Future<void> _handleTap(BuildContext context, int index) async {
    switch (index) {
      case 3:
        if (currentIndex == index) return;
        await _openOverlayPage(
          context: context,
          page: const WorkoutPlanPage(),
          pageState: const PersistedPageState.workoutPlan(),
        );
        return;
      case 4:
        if (currentIndex == index) return;
        await _openOverlayPage(
          context: context,
          page: const AutoWorkoutPage(),
          pageState: const PersistedPageState.autoWorkout(),
        );
        return;
      default:
        if (index == currentIndex) return;
        onItemSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = 6.0;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemeColors.surfaceHigh.withValues(alpha: 0.94),
                  AppThemeColors.surface.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: AppThemeColors.outlineStrong),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth =
                    (constraints.maxWidth -
                        ((_primaryDestinations.length - 1) * gap)) /
                    _primaryDestinations.length;
                final highlightLeft = currentIndex * (slotWidth + gap);

                return SizedBox(
                  height: 74,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        left: highlightLeft,
                        top: 0,
                        width: slotWidth,
                        height: 74,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppThemeColors.primary.withValues(alpha: 0.24),
                                  AppThemeColors.secondary.withValues(
                                    alpha: 0.14,
                                  ),
                                ],
                              ),
                              border: Border.all(
                                color: AppThemeColors.primary.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(_primaryDestinations.length, (
                          index,
                        ) {
                          final item = _primaryDestinations[index];

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index == _primaryDestinations.length - 1
                                    ? 0
                                    : gap,
                              ),
                              child: _NavItem(
                                data: item,
                                selected: currentIndex == index,
                                compact: index >= 3,
                                onTap: () => _handleTap(context, index),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestinationData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestinationData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final _NavDestinationData data;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontSize: compact ? 9 : 10,
      height: 1,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      color: selected ? Colors.white : AppThemeColors.textMuted,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          scale: selected ? 1 : 0.97,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 2 : 4,
              vertical: 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: compact ? 34 : 36,
                  height: compact ? 34 : 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppThemeColors.primary.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: selected
                          ? AppThemeColors.primary.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Icon(
                    selected ? data.activeIcon : data.icon,
                    color: selected
                        ? AppThemeColors.primaryStrong
                        : AppThemeColors.textMuted,
                    size: _navIconSize,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: labelStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
