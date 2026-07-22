import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/navigation/app_navigation_state_service.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../exercises/presentation/exercise_library_page.dart';
import '../../workout_automation/presentation/auto_workout_page.dart';
import '../data/workout_service.dart';
import '../models/workout.dart';
import 'workout_detail_page.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final _service = WorkoutService();
  final _navigationStateService = AppNavigationStateService();

  Future<void> _createOrEditWorkoutDialog({Workout? workout}) async {
    final nameController = TextEditingController(text: workout?.name ?? '');
    final descriptionController = TextEditingController(
      text: workout?.description ?? '',
    );

    final editing = workout != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(editing ? 'Editar treino' : 'Novo treino'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex: Treino A',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descricao',
                  hintText: 'Ex: Peito, ombro e triceps',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                if (editing) {
                  await _service.updateWorkout(
                    workoutId: workout.id,
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                } else {
                  await _service.createWorkout(
                    name: nameController.text,
                    description: descriptionController.text,
                    weekDays: [],
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteWorkout(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir treino'),
          content: Text(
            'Deseja excluir "${workout.name}"? Os exercicios desse treino tambem serao removidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _service.deleteWorkout(workoutId: workout.id);
    }
  }

  void _openAutoWorkoutPage() {
    unawaited(
      _navigationStateService.pushTrackedPage(
        context: context,
        pageState: const PersistedPageState.autoWorkout(),
        builder: (_) => const AutoWorkoutPage(),
      ),
    );
  }

  void _openExerciseLibraryPage() {
    unawaited(
      _navigationStateService.pushTrackedPage(
        context: context,
        pageState: const PersistedPageState.exerciseLibrary(),
        builder: (_) => const ExerciseLibraryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Treinos',
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'Biblioteca',
          onPressed: _openExerciseLibraryPage,
          icon: const Icon(Icons.photo_library_outlined),
        ),
      ],
      body: StreamBuilder<List<Workout>>(
        stream: _service.watchWorkouts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final workouts = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 118),
            children: [
              _WorkoutActionsBar(
                workoutCount: workouts.length,
                onCreateWorkout: () => _createOrEditWorkoutDialog(),
                onAutoBuild: _openAutoWorkoutPage,
              ),
              const SizedBox(height: 10),
              if (workouts.isEmpty)
                const _EmptyWorkoutsCard()
              else
                ...workouts.map((workout) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _WorkoutListCard(
                      workout: workout,
                      onEdit: () =>
                          _createOrEditWorkoutDialog(workout: workout),
                      onDelete: () => _deleteWorkout(workout),
                      onTap: () {
                        unawaited(
                          _navigationStateService.pushTrackedPage(
                            context: context,
                            pageState: PersistedPageState.workoutDetail(
                              workoutId: workout.id,
                            ),
                            builder: (_) => WorkoutDetailPage(workout: workout),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _WorkoutActionsBar extends StatelessWidget {
  final int workoutCount;
  final VoidCallback onCreateWorkout;
  final VoidCallback onAutoBuild;

  const _WorkoutActionsBar({
    required this.workoutCount,
    required this.onCreateWorkout,
    required this.onAutoBuild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemeColors.surfaceHigh.withValues(alpha: 0.96),
            AppThemeColors.surface.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: AppThemeColors.outlineStrong),
      ),
      child: Row(
        children: [
          _WorkoutCountBadge(count: workoutCount),
          const SizedBox(width: 8),
          Expanded(
            child: _WorkoutActionButton(
              onPressed: onCreateWorkout,
              icon: Icons.add_rounded,
              label: 'Novo',
              filled: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _WorkoutActionButton(
              onPressed: onAutoBuild,
              icon: Icons.auto_awesome_rounded,
              label: 'Automatico',
              filled: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCountBadge extends StatelessWidget {
  final int count;

  const _WorkoutCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 44,
      decoration: BoxDecoration(
        color: AppThemeColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemeColors.secondary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemeColors.secondary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count == 1 ? 'treino' : 'treinos',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 9,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  const _WorkoutActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );

    return SizedBox(
      height: 44,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: shape,
                textStyle: textStyle,
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: AppThemeColors.outlineStrong),
                shape: shape,
                textStyle: textStyle,
              ),
              child: child,
            ),
    );
  }
}

class _EmptyWorkoutsCard extends StatelessWidget {
  const _EmptyWorkoutsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppThemeColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppThemeColors.primaryStrong,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nenhum treino cadastrado',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Use Novo ou Automatico para comecar.',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutListCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _WorkoutListCard({
    required this.workout,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = workout.description.trim().isEmpty
        ? 'Sem descricao definida'
        : workout.description.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppThemeColors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    workout.name.isEmpty
                        ? 'T'
                        : workout.name.substring(0, 1).toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppThemeColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      workout.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppThemeColors.textSoft,
              ),
              PopupMenuButton<String>(
                tooltip: 'Opcoes',
                icon: const Icon(Icons.more_horiz_rounded),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
