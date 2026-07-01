import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/widgets/app_page_scaffold.dart';
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AutoWorkoutPage()));
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Treinos',
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'Montar treino automatico',
          onPressed: _openAutoWorkoutPage,
          icon: const Icon(Icons.auto_awesome_rounded),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEditWorkoutDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Novo treino'),
      ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
            children: [
              _WorkoutsOverviewCard(
                count: workouts.length,
                onAutoBuild: _openAutoWorkoutPage,
              ),
              const SizedBox(height: 20),
              if (workouts.isEmpty)
                _EmptyWorkoutsCard(onAutoBuild: _openAutoWorkoutPage)
              else
                ...workouts.map((workout) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkoutListCard(
                      workout: workout,
                      onEdit: () => _createOrEditWorkoutDialog(workout: workout),
                      onDelete: () => _deleteWorkout(workout),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
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

class _WorkoutsOverviewCard extends StatelessWidget {
  final int count;
  final VoidCallback onAutoBuild;

  const _WorkoutsOverviewCard({
    required this.count,
    required this.onAutoBuild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count == 1 ? '1 treino ativo' : '$count treinos ativos';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemeColors.surfaceHigh.withValues(alpha: 0.98),
            AppThemeColors.surface.withValues(alpha: 0.94),
          ],
        ),
        border: Border.all(color: AppThemeColors.outlineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Organize sua base', style: theme.textTheme.labelMedium),
          const SizedBox(height: 10),
          Text('Treinos claros, ajustes rapidos.', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Monte, edite e revise a estrutura da sua semana com uma visao mais limpa.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppThemeColors.outline),
                ),
                child: Text(label, style: theme.textTheme.labelLarge),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onAutoBuild,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Automatizar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkoutsCard extends StatelessWidget {
  final VoidCallback onAutoBuild;

  const _EmptyWorkoutsCard({required this.onAutoBuild});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppThemeColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppThemeColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum treino cadastrado',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie manualmente ou deixe o app montar uma estrutura inicial para voce.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAutoBuild,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Montar treino automatico'),
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
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppThemeColors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    workout.name.isEmpty
                        ? 'T'
                        : workout.name.substring(0, 1).toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppThemeColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Abrir detalhes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppThemeColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppThemeColors.textSoft,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
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
