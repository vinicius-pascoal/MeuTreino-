import 'package:flutter/material.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../workouts/data/workout_service.dart';
import '../data/exercise_library_service.dart';
import '../models/exercise.dart';

class SelectExercisePage extends StatelessWidget {
  final String workoutId;
  final int nextOrder;

  const SelectExercisePage({
    super.key,
    required this.workoutId,
    required this.nextOrder,
  });

  Future<void> _showConfigDialog(
    BuildContext context,
    Exercise exercise,
  ) async {
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '8-10');
    final restController = TextEditingController(text: '90');
    final weightController = TextEditingController(text: '0');

    final service = WorkoutService();

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
                  decoration: const InputDecoration(
                    labelText: 'Repetições',
                    hintText: 'Ex: 8-10',
                  ),
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
                  decoration: const InputDecoration(labelText: 'Carga inicial'),
                  keyboardType: TextInputType.number,
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
                final sets = int.tryParse(setsController.text) ?? 3;
                final restSeconds = int.tryParse(restController.text) ?? 90;
                final currentWeight =
                    double.tryParse(
                      weightController.text.replaceAll(',', '.'),
                    ) ??
                    0;

                await service.addExerciseToWorkout(
                  workoutId: workoutId,
                  exercise: exercise,
                  order: nextOrder,
                  sets: sets,
                  targetReps: repsController.text.trim(),
                  restSeconds: restSeconds,
                  currentWeight: currentWeight,
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    setsController.dispose();
    repsController.dispose();
    restController.dispose();
    weightController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ExerciseLibraryService();

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar exercício')),
      body: StreamBuilder<List<Exercise>>(
        stream: service.watchExercises(),
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
                'A biblioteca está vazia.\nVolte para a biblioteca e clique em popular biblioteca.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exercise = exercises[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showConfigDialog(context, exercise),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExerciseImage(
                        imageAsset: exercise.imageAsset,
                        height: 150,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise.muscleGroup,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
