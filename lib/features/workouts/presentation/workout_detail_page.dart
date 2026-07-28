import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/navigation/app_navigation_state_service.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/exercise_image.dart';
import '../../exercise_stats/data/user_exercise_stats_service.dart';
import '../../exercises/data/exercise_library_service.dart';
import '../../exercises/models/exercise.dart';
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditWorkoutExerciseSheet(
          workoutId: workout.id,
          exercise: exercise,
          subtitle: _exerciseSubtitle(exercise),
        );
      },
    );
  }

  Future<void> _replaceExercise({
    required BuildContext context,
    required WorkoutExercise exercise,
  }) async {
    final workoutService = WorkoutService();
    final libraryService = ExerciseLibraryService();
    final exerciseStatsService = UserExerciseStatsService();

    try {
      final libraryExercises = await libraryService.getExercisesOnce();
      final replacementOptions = _buildReplacementOptions(
        currentExercise: exercise,
        libraryExercises: libraryExercises,
      );

      if (!context.mounted) return;

      if (replacementOptions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao encontrei exercicios do mesmo grupo muscular para trocar.',
            ),
          ),
        );
        return;
      }

      final replacement = await showModalBottomSheet<Exercise>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return _ReplacementExerciseSheet(
            currentExercise: exercise,
            options: replacementOptions,
            subtitleBuilder: _replacementSubtitle,
            normalize: _normalize,
          );
        },
      );

      if (replacement == null) {
        return;
      }

      final replacementWeight =
          replacement.isBodyweight
          ? 0.0
          : await exerciseStatsService.getLastUsedWeight(
                  exerciseLibraryId: replacement.id,
                ) ??
                exercise.currentWeight;

      await workoutService.replaceWorkoutExercise(
        workoutId: workout.id,
        workoutExerciseId: exercise.id,
        exercise: replacement,
        currentWeight: replacementWeight,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Exercicio trocado. Series, repeticoes e descanso foram mantidos.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao trocar exercicio: $error')),
      );
    }
  }

  List<Exercise> _buildReplacementOptions({
    required WorkoutExercise currentExercise,
    required List<Exercise> libraryExercises,
  }) {
    final currentGroup = _normalize(currentExercise.muscleGroup);
    final currentRegion = _normalize(currentExercise.muscleRegion);
    final currentPattern = _normalize(currentExercise.movementPattern);

    final options = libraryExercises.where((candidate) {
      if (candidate.id == currentExercise.exerciseLibraryId) {
        return false;
      }

      return _normalize(candidate.muscleGroup) == currentGroup;
    }).toList();

    options.sort((a, b) {
      final regionCompare = _matchPriority(
        valueA: a.muscleRegion,
        valueB: b.muscleRegion,
        target: currentRegion,
      );
      if (regionCompare != 0) {
        return regionCompare;
      }

      final patternCompare = _matchPriority(
        valueA: a.movementPattern,
        valueB: b.movementPattern,
        target: currentPattern,
      );
      if (patternCompare != 0) {
        return patternCompare;
      }

      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.name.compareTo(b.name);
    });

    return options;
  }

  int _matchPriority({
    required String valueA,
    required String valueB,
    required String target,
  }) {
    final aScore = _normalize(valueA) == target ? 0 : 1;
    final bScore = _normalize(valueB) == target ? 0 : 1;
    return aScore.compareTo(bScore);
  }

  String _replacementSubtitle(Exercise exercise) {
    final parts = <String>[exercise.muscleGroup];

    if (exercise.muscleRegion.trim().isNotEmpty) {
      parts.add(exercise.muscleRegion.trim());
    }

    if (exercise.equipment.trim().isNotEmpty) {
      parts.add(exercise.equipment.trim());
    }

    return parts.join(' - ');
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
          title: const Text('Excluir exercicio'),
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
    final navigationStateService = AppNavigationStateService();

    return AppPageScaffold(
      title: workout.name,
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'Adicionar exercicio',
          onPressed: () {
            final nextOrder = DateTime.now().millisecondsSinceEpoch;

            unawaited(
              navigationStateService.pushTrackedPage(
                context: context,
                pageState: PersistedPageState.selectExercise(
                  workoutId: workout.id,
                  nextOrder: nextOrder,
                ),
                builder: (_) => SelectExercisePage(
                  workoutId: workout.id,
                  nextOrder: nextOrder,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          unawaited(
            navigationStateService.pushTrackedPage(
              context: context,
              pageState: PersistedPageState.workoutSession(
                workoutId: workout.id,
              ),
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
                'Nenhum exercicio neste treino.\nClique no + para adicionar.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
            children: [
              _WorkoutDetailSummaryCard(
                workout: workout,
                exerciseCount: exercises.length,
                totalSets: _totalSets(exercises),
              ),
              const SizedBox(height: 10),
              ...exercises.map((exercise) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _WorkoutExerciseListCard(
                    exercise: exercise,
                    subtitle: _exerciseSubtitle(exercise),
                    onMenuSelected: (value) {
                      if (value == 'replace') {
                        _replaceExercise(context: context, exercise: exercise);
                      }

                      if (value == 'edit') {
                        _editExerciseDialog(
                          context: context,
                          exercise: exercise,
                        );
                      }

                      if (value == 'delete') {
                        _deleteExercise(context: context, exercise: exercise);
                      }
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

  int _totalSets(List<WorkoutExercise> exercises) {
    return exercises.fold(0, (total, exercise) => total + exercise.sets);
  }

  String _exerciseSubtitle(WorkoutExercise exercise) {
    final parts = <String>[exercise.muscleGroup];

    if (exercise.muscleRegion.trim().isNotEmpty) {
      parts.add(exercise.muscleRegion.trim());
    }

    if (exercise.equipment.trim().isNotEmpty) {
      parts.add(exercise.equipment.trim());
    }

    return parts.join(' - ');
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u00e1\u00e0\u00e2\u00e3\u00e4]'), 'a')
        .replaceAll(RegExp(r'[\u00e9\u00e8\u00ea\u00eb]'), 'e')
        .replaceAll(RegExp(r'[\u00ed\u00ec\u00ee\u00ef]'), 'i')
        .replaceAll(RegExp(r'[\u00f3\u00f2\u00f4\u00f5\u00f6]'), 'o')
        .replaceAll(RegExp(r'[\u00fa\u00f9\u00fb\u00fc]'), 'u')
        .replaceAll('\u00e7', 'c');
  }
}

class _EditWorkoutExerciseSheet extends StatefulWidget {
  final String workoutId;
  final WorkoutExercise exercise;
  final String subtitle;

  const _EditWorkoutExerciseSheet({
    required this.workoutId,
    required this.exercise,
    required this.subtitle,
  });

  @override
  State<_EditWorkoutExerciseSheet> createState() =>
      _EditWorkoutExerciseSheetState();
}

class _EditWorkoutExerciseSheetState extends State<_EditWorkoutExerciseSheet> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _restController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final exercise = widget.exercise;

    _setsController = TextEditingController(text: '${exercise.sets}');
    _repsController = TextEditingController(text: exercise.targetReps);
    _restController = TextEditingController(text: '${exercise.restSeconds}');
    _weightController = TextEditingController(
      text: _formatWeight(exercise.currentWeight),
    );
    _notesController = TextEditingController(text: exercise.notes);
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final exercise = widget.exercise;
    final sets = int.tryParse(_setsController.text.trim());
    final targetReps = _repsController.text.trim();
    final restSeconds = int.tryParse(_restController.text.trim());
    final currentWeight = exercise.isBodyweight
        ? 0.0
        : double.tryParse(_weightController.text.trim().replaceAll(',', '.'));

    if (sets == null || sets <= 0) {
      _showError('Informe uma quantidade valida de series.');
      return;
    }

    if (targetReps.isEmpty) {
      _showError('Informe a meta de repeticoes.');
      return;
    }

    if (restSeconds == null || restSeconds < 0) {
      _showError('Informe um descanso valido.');
      return;
    }

    if (currentWeight == null || currentWeight < 0) {
      _showError('Informe uma carga valida.');
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      await WorkoutService().updateWorkoutExercise(
        workoutId: widget.workoutId,
        workoutExerciseId: exercise.id,
        sets: sets,
        targetReps: targetReps,
        restSeconds: restSeconds,
        currentWeight: currentWeight,
        notes: _notesController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _errorText = 'Erro ao salvar: $error';
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorText = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = screenHeight - bottomInset - 24;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: AppThemeColors.surfaceHigh,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppThemeColors.outlineStrong),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxSheetHeight < 320
                  ? screenHeight * 0.72
                  : maxSheetHeight,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 12),
                  _SheetExerciseHeader(
                    label: 'Editar exercicio',
                    name: exercise.name,
                    subtitle: widget.subtitle,
                    imageAsset: exercise.imageAsset,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 14),
                  _buildFieldPair(
                    _WorkoutDetailTextField(
                      controller: _setsController,
                      label: 'Series',
                      icon: Icons.repeat_rounded,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    _WorkoutDetailTextField(
                      controller: _repsController,
                      label: 'Repeticoes',
                      hint: 'Ex: 8-10',
                      icon: Icons.format_list_numbered_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFieldPair(
                    _WorkoutDetailTextField(
                      controller: _restController,
                      label: 'Descanso',
                      suffix: 's',
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    exercise.isBodyweight
                        ? const _BodyweightInfoCard()
                        : _WorkoutDetailTextField(
                            controller: _weightController,
                            label: 'Carga atual',
                            suffix: 'kg',
                            icon: Icons.fitness_center_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                  ),
                  const SizedBox(height: 10),
                  _WorkoutDetailTextField(
                    controller: _notesController,
                    label: 'Observacoes',
                    icon: Icons.notes_rounded,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 10),
                    _SheetMessage(
                      icon: Icons.error_outline_rounded,
                      text: _errorText!,
                      tone: AppThemeColors.danger,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF07100C),
                                  ),
                                )
                              : const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldPair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              first,
              const SizedBox(height: 10),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  String _formatWeight(double value) {
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _ReplacementExerciseSheet extends StatefulWidget {
  final WorkoutExercise currentExercise;
  final List<Exercise> options;
  final String Function(Exercise exercise) subtitleBuilder;
  final String Function(String value) normalize;

  const _ReplacementExerciseSheet({
    required this.currentExercise,
    required this.options,
    required this.subtitleBuilder,
    required this.normalize,
  });

  @override
  State<_ReplacementExerciseSheet> createState() =>
      _ReplacementExerciseSheetState();
}

class _ReplacementExerciseSheetState extends State<_ReplacementExerciseSheet> {
  final _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> get _filteredOptions {
    final query = widget.normalize(_query);

    if (query.isEmpty) {
      return widget.options;
    }

    return widget.options.where((exercise) {
      final haystack = widget.normalize(
        [
          exercise.name,
          exercise.muscleGroup,
          exercise.muscleRegion,
          exercise.movementPattern,
          exercise.equipment,
        ].join(' '),
      );

      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.currentExercise;
    final filteredOptions = _filteredOptions;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final rawAvailableHeight = screenHeight - bottomInset - 24;
    final availableHeight = rawAvailableHeight < 280
        ? 280.0
        : rawAvailableHeight;
    final sheetHeight = availableHeight < 360
        ? availableHeight
        : availableHeight * 0.82;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
        child: SizedBox(
          height: sheetHeight,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: BoxDecoration(
              color: AppThemeColors.surfaceHigh,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppThemeColors.outlineStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 12),
                _SheetExerciseHeader(
                  label: 'Trocar exercicio',
                  name: current.name,
                  subtitle: 'Mantem series, repeticoes e descanso',
                  imageAsset: current.imageAsset,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  textInputAction: TextInputAction.search,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar substituto',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${filteredOptions.length} de ${widget.options.length} opcoes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeColors.textMuted,
                        ),
                      ),
                    ),
                    const _SortHintChip(),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredOptions.isEmpty
                      ? const _EmptyReplacementSearchCard()
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: filteredOptions.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final option = filteredOptions[index];

                            return _ReplacementOptionCard(
                              option: option,
                              currentExercise: current,
                              subtitle: widget.subtitleBuilder(option),
                              normalize: widget.normalize,
                              onTap: () {
                                Navigator.of(context).pop(option);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: AppThemeColors.outlineStrong,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetExerciseHeader extends StatelessWidget {
  final String label;
  final String name;
  final String subtitle;
  final String imageAsset;
  final VoidCallback onClose;

  const _SheetExerciseHeader({
    required this.label,
    required this.name,
    required this.subtitle,
    required this.imageAsset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _SheetExerciseImage(imageAsset: imageAsset),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppThemeColors.primaryStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppThemeColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Fechar',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _SheetExerciseImage extends StatelessWidget {
  final String imageAsset;

  const _SheetExerciseImage({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppThemeColors.outlineStrong),
      ),
      child: ExerciseImage(
        imageAsset: imageAsset,
        width: 60,
        height: 60,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _WorkoutDetailTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final String? suffix;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _WorkoutDetailTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.suffix,
    this.minLines,
    this.maxLines,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      ),
    );
  }
}

class _BodyweightInfoCard extends StatelessWidget {
  const _BodyweightInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppThemeColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppThemeColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.accessibility_new_rounded,
            size: 18,
            color: AppThemeColors.primaryStrong,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Peso corporal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemeColors.primaryStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color tone;

  const _SheetMessage({
    required this.icon,
    required this.text,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortHintChip extends StatelessWidget {
  const _SortHintChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppThemeColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppThemeColors.secondary.withValues(alpha: 0.16),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 13,
            color: AppThemeColors.secondary,
          ),
          SizedBox(width: 4),
          Text(
            'Mais proximos',
            style: TextStyle(
              color: AppThemeColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReplacementSearchCard extends StatelessWidget {
  const _EmptyReplacementSearchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppThemeColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppThemeColors.warning,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhum substituto encontrado nessa busca.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemeColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplacementOptionCard extends StatelessWidget {
  final Exercise option;
  final WorkoutExercise currentExercise;
  final String subtitle;
  final String Function(String value) normalize;
  final VoidCallback onTap;

  const _ReplacementOptionCard({
    required this.option,
    required this.currentExercise,
    required this.subtitle,
    required this.normalize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sameRegion = normalize(option.muscleRegion) ==
        normalize(currentExercise.muscleRegion);
    final samePattern =
        normalize(option.movementPattern) ==
        normalize(currentExercise.movementPattern);
    final sameEquipment =
        normalize(option.equipment) == normalize(currentExercise.equipment);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ReplacementOptionImage(imageAsset: option.imageAsset),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppThemeColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (sameRegion)
                          const _ExerciseMetricChip(
                            icon: Icons.center_focus_strong_rounded,
                            label: 'Regiao',
                            tone: AppThemeColors.primaryStrong,
                          ),
                        if (samePattern)
                          const _ExerciseMetricChip(
                            icon: Icons.route_rounded,
                            label: 'Movimento',
                            tone: AppThemeColors.secondary,
                          ),
                        if (sameEquipment)
                          const _ExerciseMetricChip(
                            icon: Icons.build_rounded,
                            label: 'Equipamento',
                            tone: AppThemeColors.warning,
                          ),
                        if (!sameRegion && !samePattern && !sameEquipment)
                          const _ExerciseMetricChip(
                            icon: Icons.fitness_center_rounded,
                            label: 'Mesmo grupo',
                            tone: AppThemeColors.textMuted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppThemeColors.textSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplacementOptionImage extends StatelessWidget {
  final String imageAsset;

  const _ReplacementOptionImage({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppThemeColors.outlineStrong),
      ),
      child: ExerciseImage(
        imageAsset: imageAsset,
        width: 68,
        height: 68,
        borderRadius: BorderRadius.circular(17),
      ),
    );
  }
}

class _WorkoutDetailSummaryCard extends StatelessWidget {
  final Workout workout;
  final int exerciseCount;
  final int totalSets;

  const _WorkoutDetailSummaryCard({
    required this.workout,
    required this.exerciseCount,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = workout.description.trim().isEmpty
        ? 'Sem descricao definida'
        : workout.description.trim();
    final exerciseLabel = exerciseCount == 1 ? 'exercicio' : 'exercicios';
    final setsLabel = totalSets == 1 ? 'serie' : 'series';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppThemeColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppThemeColors.primary.withValues(alpha: 0.18),
                ),
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
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppThemeColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$exerciseCount $exerciseLabel - $totalSets $setsLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppThemeColors.primaryStrong,
                    ),
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

class _WorkoutExerciseListCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final String subtitle;
  final ValueChanged<String> onMenuSelected;

  const _WorkoutExerciseListCard({
    required this.exercise,
    required this.subtitle,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightLabel = exercise.isBodyweight
        ? 'Peso corporal'
        : '${exercise.currentWeight.toStringAsFixed(1)} kg';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppThemeColors.outlineStrong),
              ),
              child: ExerciseImage(
                imageAsset: exercise.imageAsset,
                width: 84,
                height: 84,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppThemeColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _ExerciseMetricChip(
                        icon: Icons.repeat_rounded,
                        label: '${exercise.sets}x ${exercise.targetReps}',
                        tone: AppThemeColors.secondary,
                      ),
                      _ExerciseMetricChip(
                        icon: Icons.timer_outlined,
                        label: '${exercise.restSeconds}s',
                        tone: AppThemeColors.warning,
                      ),
                      _ExerciseMetricChip(
                        icon: exercise.isBodyweight
                            ? Icons.accessibility_new_rounded
                            : Icons.fitness_center_rounded,
                        label: weightLabel,
                        tone: AppThemeColors.primaryStrong,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Opcoes',
              icon: const Icon(Icons.more_horiz_rounded),
              padding: EdgeInsets.zero,
              onSelected: onMenuSelected,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'replace',
                  child: Text('Trocar por similar'),
                ),
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tone;

  const _ExerciseMetricChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
