import 'package:flutter/material.dart';

import '../../features/auth/data/auth_service.dart';
import '../../features/exercises/presentation/exercise_library_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/progress/presentation/progress_page.dart';
import '../../features/workout_automation/presentation/auto_workout_page.dart';
import '../../features/workouts/presentation/workouts_page.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  Future<void> _openRootPage(BuildContext context, Widget page) async {
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  Future<void> _showMoreSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F1B2D),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BottomSheetAction(
                  icon: Icons.auto_awesome,
                  title: 'Treino automatico',
                  subtitle: 'Monte um treino com poucos toques.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _openRootPage(context, const AutoWorkoutPage());
                  },
                ),
                const SizedBox(height: 10),
                _BottomSheetAction(
                  icon: Icons.photo_library_outlined,
                  title: 'Biblioteca',
                  subtitle: 'Veja exercicios e referencias locais.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _openRootPage(context, const ExerciseLibraryPage());
                  },
                ),
                const SizedBox(height: 10),
                _BottomSheetAction(
                  icon: Icons.logout_rounded,
                  title: 'Sair da conta',
                  subtitle: 'Encerrar sessao neste dispositivo.',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await AuthService().logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context, int index) async {
    if (index == 0) {
      await _openRootPage(context, const HomePage());
      return;
    }

    if (index == 1) {
      await _openRootPage(context, const WorkoutsPage());
      return;
    }

    if (index == 2) {
      await _openRootPage(context, const HistoryPage());
      return;
    }

    if (index == 3) {
      await _openRootPage(context, const ProgressPage());
      return;
    }

    await _showMoreSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => _handleTap(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Treinos',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historico',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Progresso',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Mais',
            ),
          ],
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
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(22),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF86EFAC)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
