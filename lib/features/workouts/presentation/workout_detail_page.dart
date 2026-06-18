import 'package:flutter/material.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../exercises/presentation/select_exercise_page.dart';
import '../../workout_session/presentation/workout_session_page.dart';
import '../data/workout_service.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';

class WorkoutDetailPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  Future<void> _editExerciseDialog({
    required BuildContext context,
    required WorkoutExercise exercise,
  }) async {
    final service = WorkoutService();

    final setsController = TextEditingController(text: '${exercise.sets}');
    final repsController = TextEditingController(text: exercise.targetReps);
    final restController = TextEditingController(
      text: '${exercise.restSeconds}',
    );
    final weightController = TextEditingController(
      text: exercise.currentWeight.toStringAsFixed(1),
    );
    final notesController = TextEditingController(text: exercise.notes);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(exercise.name),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: setsController,
                  decoration: const InputDecoration(labelText: 'Séries'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repsController,
                  decoration: const InputDecoration(labelText: 'Repetições'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: restController,
                  decoration: const InputDecoration(
                    labelText: 'Descanso em segundos',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Carga atual'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Observações'),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await service.updateWorkoutExercise(
                  workoutId: workout.id,
                  workoutExerciseId: exercise.id,
                  sets: int.tryParse(setsController.text) ?? exercise.sets,
                  targetReps: repsController.text,
                  restSeconds:
                      int.tryParse(restController.text) ?? exercise.restSeconds,
                  currentWeight:
                      double.tryParse(
                        weightController.text.replaceAll(',', '.'),
                      ) ??
                      exercise.currentWeight,
                  notes: notesController.text,
                );

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

    setsController.dispose();
    repsController.dispose();
    restController.dispose();
    weightController.dispose();
    notesController.dispose();
  }

  Future<void> _deleteExercise({
    required BuildContext context,
    required WorkoutExercise exercise,
  }) async {
    final service = WorkoutService();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir exercício'),
          content: Text('Deseja excluir "${exercise.name}" deste treino?'),
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
      await service.deleteWorkoutExercise(
        workoutId: workout.id,
        workoutExerciseId: exercise.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = WorkoutService();

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        actions: [
          IconButton(
            tooltip: 'Adicionar exercício',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SelectExercisePage(
                    workoutId: workout.id,
                    nextOrder: DateTime.now().millisecondsSinceEpoch,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutSessionPage(workout: workout),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar treino'),
      ),
      body: StreamBuilder<List<WorkoutExercise>>(
        stream: service.watchWorkoutExercises(workoutId: workout.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = snapshot.data!;

          if (exercises.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum exercício neste treino.\nClique no + para adicionar.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final exercise = exercises[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExerciseImage(imageAsset: exercise.imageAsset, height: 170),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editExerciseDialog(
                                      context: context,
                                      exercise: exercise,
                                    );
                                  }

                                  if (value == 'delete') {
                                    _deleteExercise(
                                      context: context,
                                      exercise: exercise,
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${exercise.muscleGroup} • ${exercise.sets} séries • ${exercise.targetReps} reps • ${exercise.restSeconds}s descanso',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Última carga: ${exercise.currentWeight.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
