import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../../core/widgets/rest_timer.dart';
import '../../home_widgets/data/app_home_widget_service.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/models/workout_exercise.dart';
import '../data/workout_session_draft_service.dart';
import '../data/workout_session_service.dart';
import '../models/completed_set_input.dart';

class WorkoutSessionPage extends StatefulWidget {
  final Workout workout;

  const WorkoutSessionPage({super.key, required this.workout});

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage>
    with WidgetsBindingObserver {
  static const _accentColor = Color(0xFF22C55E);
  static const _panelColor = Color(0xFF162033);
  static const _panelBorderColor = Color(0xFF243041);

  final _workoutService = WorkoutService();
  final _sessionService = WorkoutSessionService();
  final _draftService = WorkoutSessionDraftService();
  final _homeWidgetService = AppHomeWidgetService();

  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  final List<CompletedSetInput> _completedSets = [];

  late DateTime _startedAt;

  String? _selectedExerciseId;
  WorkoutSessionDraft? _pendingDraft;
  bool _draftLoaded = false;
  bool _draftApplied = false;
  bool _sessionSaved = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedAt = DateTime.now();
    _loadSavedDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_saveDraft());
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_saveDraft());
    }
  }

  Future<void> _loadSavedDraft() async {
    final draft = await _draftService.loadDraft(workoutId: widget.workout.id);

    if (!mounted) return;

    setState(() {
      _pendingDraft = draft;
      _draftLoaded = true;
    });
  }

  void _applyDraftIfAvailable(
    WorkoutSessionDraft? draft,
    List<WorkoutExercise> exercises,
  ) {
    _draftApplied = true;

    if (draft == null || draft.completedSets.isEmpty) {
      return;
    }

    final exercisesById = {
      for (final exercise in exercises) exercise.id: exercise,
    };

    _startedAt = draft.startedAt;
    _completedSets.clear();

    for (final item in draft.completedSets) {
      final exercise = exercisesById[item.workoutExerciseId];

      if (exercise == null || item.reps <= 0) {
        continue;
      }

      if (_completedSetsCountFor(exercise.id) >= exercise.sets) {
        continue;
      }

      _completedSets.add(
        CompletedSetInput(
          exercise: exercise,
          setNumber: _completedSetsCountFor(exercise.id) + 1,
          weight: item.weight,
          reps: item.reps,
        ),
      );
    }

    final selectedExercise = exercisesById[draft.selectedExerciseId];

    if (selectedExercise != null && !_isExerciseCompleted(selectedExercise)) {
      _selectedExerciseId = selectedExercise.id;
      _loadExerciseFields(selectedExercise);
    } else {
      _selectedExerciseId = null;
    }
  }

  Future<void> _saveDraft() async {
    if (_sessionSaved || _completedSets.isEmpty) {
      return;
    }

    await _draftService.saveDraft(
      workout: widget.workout,
      startedAt: _startedAt,
      selectedExerciseId: _selectedExerciseId,
      completedSets: _completedSets,
    );
  }

  int _completedSetsCountFor(String exerciseId) {
    return _completedSets.where((item) => item.exercise.id == exerciseId).length;
  }

  bool _isExerciseCompleted(WorkoutExercise exercise) {
    return _completedSetsCountFor(exercise.id) >= exercise.sets;
  }

  bool _isWorkoutCompleted(List<WorkoutExercise> exercises) {
    return exercises.every(_isExerciseCompleted);
  }

  int _nextSetNumberFor(WorkoutExercise exercise) {
    final nextSet = _completedSetsCountFor(exercise.id) + 1;
    return nextSet > exercise.sets ? exercise.sets : nextSet;
  }

  double _progressFor(WorkoutExercise exercise) {
    if (exercise.sets <= 0) return 0;
    return _completedSetsCountFor(exercise.id) / exercise.sets;
  }

  double _suggestedWeightFor(WorkoutExercise exercise) {
    for (final item in _completedSets.reversed) {
      if (item.exercise.id == exercise.id) {
        return item.weight;
      }
    }

    return exercise.currentWeight;
  }

  String _formatWeight(double value) {
    if (value <= 0) return '';
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  void _loadExerciseFields(WorkoutExercise exercise) {
    _weightController.text = _formatWeight(_suggestedWeightFor(exercise));
    _repsController.clear();
  }

  void _selectExercise(WorkoutExercise exercise) {
    setState(() {
      _selectedExerciseId = exercise.id;
      _loadExerciseFields(exercise);
    });
    unawaited(_saveDraft());
  }

  WorkoutExercise _resolveSelectedExercise(List<WorkoutExercise> exercises) {
    for (final exercise in exercises) {
      if (exercise.id == _selectedExerciseId) {
        return exercise;
      }
    }

    for (final exercise in exercises) {
      if (!_isExerciseCompleted(exercise)) {
        return exercise;
      }
    }

    return exercises.first;
  }

  Future<void> _completeSet(
    WorkoutExercise exercise,
    List<WorkoutExercise> exercises,
  ) async {
    if (_isExerciseCompleted(exercise)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todas as series deste exercicio ja foram registradas.',
          ),
        ),
      );
      return;
    }

    final weight =
        double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;

    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe as repeticoes realizadas.')),
      );
      return;
    }

    _completedSets.add(
      CompletedSetInput(
        exercise: exercise,
        setNumber: _nextSetNumberFor(exercise),
        weight: weight,
        reps: reps,
      ),
    );

    setState(() {
      _repsController.clear();

      if (_isExerciseCompleted(exercise)) {
        for (final item in exercises) {
          if (!_isExerciseCompleted(item)) {
            _selectedExerciseId = item.id;
            _loadExerciseFields(item);
            break;
          }
        }
      }
    });

    await _saveDraft();
  }

  Future<void> _finishWorkout() async {
    setState(() => _saving = true);

    try {
      await _saveDraft();
      await _sessionService.finishWorkoutSession(
        workout: widget.workout,
        startedAt: _startedAt,
        completedSets: _completedSets,
      );
      await _homeWidgetService.syncFromAppState();
      await _draftService.clearDraft(workoutId: widget.workout.id);
      _sessionSaved = true;

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino salvo com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar treino: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutExercise>>(
      stream: _workoutService.watchWorkoutExercises(
        workoutId: widget.workout.id,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final exercises = snapshot.data!;

        if (exercises.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Treino')),
            body: const Center(
              child: Text('Este treino nao possui exercicios.'),
            ),
          );
        }

        if (!_draftLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_draftApplied) {
          _applyDraftIfAvailable(_pendingDraft, exercises);
        }

        final isWorkoutCompleted = _isWorkoutCompleted(exercises);

        if (_selectedExerciseId == null) {
          final initialExercise = _resolveSelectedExercise(exercises);
          _selectedExerciseId = initialExercise.id;
          _loadExerciseFields(initialExercise);
        }

        if (isWorkoutCompleted) {
          return Scaffold(
            appBar: AppBar(title: const Text('Finalizar treino')),
            body: SafeArea(
              minimum: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 72,
                      color: _accentColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Treino concluido!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_completedSets.length} series registradas',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _finishWorkout,
                        icon: const Icon(Icons.save),
                        label: _saving
                            ? const Text('Salvando...')
                            : const Text('Salvar treino'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final exercise = _resolveSelectedExercise(exercises);
        final currentSet = _nextSetNumberFor(exercise);
        final completedExercises = exercises.where(_isExerciseCompleted).length;
        final totalVolume = _completedSets.fold<double>(
          0,
          (sum, item) => sum + item.volume,
        );

        return Scaffold(
          appBar: AppBar(title: Text(widget.workout.name)),
          body: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ExerciseImage(imageAsset: exercise.imageAsset, height: 220),
                const SizedBox(height: 18),
                Text(
                  '$completedExercises de ${exercises.length} exercicios concluidos',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_exerciseSubtitle(exercise)} - Série $currentSet de ${exercise.sets}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ultima carga: ${exercise.currentWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    color: _panelColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _panelBorderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0x1F22C55E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: _accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selecione o exercicio',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Voce pode alternar livremente entre os exercicios do treino.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 144,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: exercises.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = exercises[index];
                            final completedSets = _completedSetsCountFor(item.id);
                            final isSelected = item.id == exercise.id;
                            final isCompleted = _isExerciseCompleted(item);
                            final progress = _progressFor(item);

                            return SizedBox(
                              width: 204,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => _selectExercise(item),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF22C55E),
                                              Color(0xFF16A34A),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0x8022C55E)
                                          : isCompleted
                                              ? const Color(0x8022C55E)
                                              : _panelBorderColor,
                                      width: 1.2,
                                    ),
                                    boxShadow: isSelected
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x3322C55E),
                                              blurRadius: 18,
                                              offset: Offset(0, 10),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: isSelected
                                                    ? const Color(0xFF052E16)
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isCompleted
                                                ? Icons.check_circle
                                                : isSelected
                                                    ? Icons.play_circle_fill
                                                    : Icons.radio_button_unchecked,
                                            size: 20,
                                            color: isSelected
                                                ? const Color(0xFF052E16)
                                                : isCompleted
                                                    ? _accentColor
                                                    : Colors.white38,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _exerciseSubtitle(item),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected
                                              ? const Color(0xCC052E16)
                                              : Colors.white70,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '$completedSets/${item.sets} series',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? const Color(0xFF052E16)
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: progress.clamp(0, 1),
                                          minHeight: 8,
                                          backgroundColor: isSelected
                                              ? const Color(0x55052E16)
                                              : const Color(0xFF0F172A),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            isSelected
                                                ? const Color(0xFF052E16)
                                                : _accentColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Carga usada',
                    suffixText: 'kg',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _repsController,
                  decoration: InputDecoration(
                    labelText: 'Repeticoes feitas',
                    hintText: exercise.targetReps,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _isExerciseCompleted(exercise)
                      ? null
                      : () => _completeSet(exercise, exercises),
                  icon: const Icon(Icons.check),
                  label: Text(
                    _isExerciseCompleted(exercise)
                        ? 'Exercicio concluido'
                        : 'Concluir serie',
                  ),
                ),
                const SizedBox(height: 18),
                RestTimer(
                  key: ValueKey(
                    '${exercise.id}-${_completedSetsCountFor(exercise.id)}',
                  ),
                  initialSeconds: exercise.restSeconds,
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Volume registrado ate agora: ${totalVolume.toStringAsFixed(0)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _exerciseSubtitle(WorkoutExercise exercise) {
    final parts = <String>[exercise.muscleGroup];

    if (exercise.muscleRegion.trim().isNotEmpty) {
      parts.add(exercise.muscleRegion.trim());
    }

    if (exercise.equipment.trim().isNotEmpty) {
      parts.add(exercise.equipment.trim());
    }

    return parts.join(' • ');
  }
}
