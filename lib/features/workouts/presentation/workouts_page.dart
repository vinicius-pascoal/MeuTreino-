import 'package:flutter/material.dart';

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
                  labelText: 'Descrição',
                  hintText: 'Ex: Peito, ombro e tríceps',
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
            'Deseja excluir "${workout.name}"? Os exercícios desse treino também serão removidos.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus treinos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEditWorkoutDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Treino'),
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

          if (workouts.isEmpty) {
            return const Center(child: Text('Nenhum treino cadastrado.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final workout = workouts[index];

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    workout.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    workout.description.isEmpty
                        ? 'Sem descrição'
                        : workout.description,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _createOrEditWorkoutDialog(workout: workout);
                      }

                      if (value == 'delete') {
                        _deleteWorkout(workout);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkoutDetailPage(workout: workout),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
