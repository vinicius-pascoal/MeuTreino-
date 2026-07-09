import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/navigation/app_navigation_state_service.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/exercises/presentation/exercise_library_page.dart';
import '../../features/workout_automation/presentation/auto_workout_page.dart';
import '../../features/workout_plan/presentation/workout_plan_page.dart';

const double _navIconSize = 20;

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
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Historico',
    ),
    _NavDestinationData(
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart,
      label: 'Progresso',
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

  Future<void> _showMoreSheet(BuildContext context) async {
    final screenHeight = MediaQuery.sizeOf(context).height;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppThemeColors.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppThemeColors.outlineStrong),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mais opcoes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atalhos que complementam a navegacao principal do app.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          _BottomSheetAction(
                            icon: Icons.calendar_view_week_rounded,
                            title: 'Treino semanal',
                            subtitle:
                                'Edite a sequencia e os dias esperados da rotina.',
                            onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await _openOverlayPage(
                              context: context,
                              page: const WorkoutPlanPage(),
                              pageState: const PersistedPageState.workoutPlan(),
                            );
                          },
                        ),
                          const SizedBox(height: 6),
                          _BottomSheetAction(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Treino automatico',
                            subtitle:
                                'Monte uma rotina inicial com poucos toques.',
                            onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await _openOverlayPage(
                              context: context,
                              page: const AutoWorkoutPage(),
                              pageState: const PersistedPageState.autoWorkout(),
                            );
                          },
                        ),
                          const SizedBox(height: 6),
                          _BottomSheetAction(
                            icon: Icons.photo_library_outlined,
                            title: 'Biblioteca',
                            subtitle:
                                'Consulte exercicios e referencias locais.',
                            onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await _openOverlayPage(
                              context: context,
                              page: const ExerciseLibraryPage(),
                              pageState:
                                  const PersistedPageState.exerciseLibrary(),
                            );
                          },
                        ),
                          const SizedBox(height: 6),
                          _BottomSheetAction(
                            icon: Icons.logout_rounded,
                            title: 'Sair da conta',
                            subtitle: 'Encerrar a sessao neste dispositivo.',
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              await AuthService().logout();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context, int index) async {
    if (index == _primaryDestinations.length) {
      await _showMoreSheet(context);
      return;
    }

    if (index == currentIndex) return;

    onItemSelected(index);
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
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final slotWidth =
                          (constraints.maxWidth -
                              ((_primaryDestinations.length - 1) * gap)) /
                          _primaryDestinations.length;
                      final highlightLeft =
                          currentIndex * (slotWidth + gap);

                      return SizedBox(
                        height: 76,
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.easeOutCubic,
                              left: highlightLeft,
                              top: 0,
                              width: slotWidth,
                              height: 76,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppThemeColors.primary.withValues(
                                          alpha: 0.24,
                                        ),
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
                              children: List.generate(
                                _primaryDestinations.length,
                                (index) {
                                  final item = _primaryDestinations[index];

                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: index ==
                                                _primaryDestinations.length - 1
                                            ? 0
                                            : gap,
                                      ),
                                      child: _NavItem(
                                        data: item,
                                        selected: currentIndex == index,
                                        onTap: () => _handleTap(context, index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _MoreButton(
                  onTap: () => _handleTap(context, _primaryDestinations.length),
                ),
              ],
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
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontSize: 10,
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
          scale: selected ? 1 : 0.98,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 36,
                  height: 36,
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

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 76,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.grid_view_rounded,
                    color: AppThemeColors.textMuted,
                    size: _navIconSize,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mais',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: AppThemeColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BottomSheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppThemeColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppThemeColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(icon, color: AppThemeColors.primaryStrong),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
