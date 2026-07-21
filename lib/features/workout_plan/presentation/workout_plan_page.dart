import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/navigation/app_navigation_state_service.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../home_widgets/data/app_home_widget_service.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';
import '../data/workout_plan_service.dart';
import '../models/workout_plan.dart';

class WorkoutPlanPage extends StatefulWidget {
  const WorkoutPlanPage({super.key});

  @override
  State<WorkoutPlanPage> createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  final _workoutService = WorkoutService();
  final _planService = WorkoutPlanService();
  final _homeWidgetService = AppHomeWidgetService();
  final _navigationStateService = AppNavigationStateService();

  final List<String> _selectedWorkoutIds = [];
  final List<int> _selectedWeekDays = [1, 2, 3, 4, 5];

  Timer? _autoSaveDebounce;
  String? _lastSavedPlanSignature;
  bool _saveAgainAfterCurrent = false;
  bool _loading = true;
  bool _saving = false;
  List<Workout> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    final results = await Future.wait([
      _workoutService.getWorkoutsOnce(),
      _planService.getPlanOnce(),
    ]);
    final workouts = results[0] as List<Workout>;
    final existingPlan = results[1] as WorkoutPlan?;
    final availableWorkoutIds = workouts.map((workout) => workout.id).toSet();

    _selectedWorkoutIds
      ..clear()
      ..addAll(existingPlan?.sequenceWorkoutIds ?? const <String>[])
      ..retainWhere(availableWorkoutIds.contains);
    _selectedWeekDays
      ..clear()
      ..addAll(
        existingPlan?.trainingWeekDays.isNotEmpty == true
            ? existingPlan!.trainingWeekDays
            : const [1, 2, 3, 4, 5],
      );
    _lastSavedPlanSignature = _currentPlanSignature;

    setState(() {
      _workouts = workouts;
      _loading = false;
    });
  }

  String get _currentPlanSignature {
    return '${_selectedWorkoutIds.join('|')}::${_selectedWeekDays.join('|')}';
  }

  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();

    _autoSaveDebounce = Timer(const Duration(milliseconds: 650), () {
      _persistPlan();
    });
  }

  Future<void> _persistPlan() async {
    final signature = _currentPlanSignature;

    if (signature == _lastSavedPlanSignature) {
      return;
    }

    if (_saving) {
      _saveAgainAfterCurrent = true;
      return;
    }

    final sequenceWorkoutIds = List<String>.from(_selectedWorkoutIds);
    final trainingWeekDays = List<int>.from(_selectedWeekDays);

    setState(() {
      _saving = true;
    });

    try {
      await _planService.savePlan(
        sequenceWorkoutIds: sequenceWorkoutIds,
        trainingWeekDays: trainingWeekDays,
      );
      await _homeWidgetService.syncFromAppState();
      _lastSavedPlanSignature = signature;

      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }

      if (mounted && _saveAgainAfterCurrent) {
        _saveAgainAfterCurrent = false;
        _scheduleAutoSave();
      } else {
        _saveAgainAfterCurrent = false;
      }
    }
  }

  Future<void> _navigateFromNavbar(int index) async {
    await _navigationStateService.saveSelectedTab(index);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  void _toggleWorkout(String workoutId) {
    setState(() {
      if (_selectedWorkoutIds.contains(workoutId)) {
        _selectedWorkoutIds.remove(workoutId);
      } else {
        _selectedWorkoutIds.add(workoutId);
      }
    });
    _scheduleAutoSave();
  }

  void _reorderWorkouts(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final movedWorkoutId = _selectedWorkoutIds.removeAt(oldIndex);
      _selectedWorkoutIds.insert(newIndex, movedWorkoutId);
    });
    _scheduleAutoSave();
  }

  void _setWeekDays(List<int> days) {
    final normalizedDays = [...days]..sort();

    setState(() {
      _selectedWeekDays
        ..clear()
        ..addAll(normalizedDays);
    });
    _scheduleAutoSave();
  }

  void _toggleWeekDay(int day) {
    setState(() {
      if (_selectedWeekDays.contains(day)) {
        _selectedWeekDays.remove(day);
      } else {
        _selectedWeekDays.add(day);
        _selectedWeekDays.sort();
      }
    });
    _scheduleAutoSave();
  }

  void _selectBusinessDays() {
    _setWeekDays(const [1, 2, 3, 4, 5]);
  }

  void _selectAllWeekDays() {
    _setWeekDays(const [1, 2, 3, 4, 5, 6, 7]);
  }

  void _selectWeekendDays() {
    _setWeekDays(const [6, 7]);
  }

  void _clearWeekDays() {
    _setWeekDays(const []);
  }

  Workout? _findWorkoutById(String workoutId) {
    for (final workout in _workouts) {
      if (workout.id == workoutId) {
        return workout;
      }
    }

    return null;
  }

  String _dayShortLabel(int day) {
    switch (day) {
      case 1:
        return 'Seg';
      case 2:
        return 'Ter';
      case 3:
        return 'Qua';
      case 4:
        return 'Qui';
      case 5:
        return 'Sex';
      case 6:
        return 'Sab';
      case 7:
        return 'Dom';
      default:
        return '-';
    }
  }

  String _dayFullLabel(int day) {
    switch (day) {
      case 1:
        return 'Segunda';
      case 2:
        return 'Terca';
      case 3:
        return 'Quarta';
      case 4:
        return 'Quinta';
      case 5:
        return 'Sexta';
      case 6:
        return 'Sabado';
      case 7:
        return 'Domingo';
      default:
        return '-';
    }
  }

  List<Workout> get _selectedWorkouts {
    return _selectedWorkoutIds
        .map(_findWorkoutById)
        .whereType<Workout>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Treino semanal',
      currentIndex: 3,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onItemSelected: _navigateFromNavbar,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _WorkoutPlanBody(
              workouts: _workouts,
              selectedWorkoutIds: _selectedWorkoutIds,
              selectedWeekDays: _selectedWeekDays,
              selectedWorkouts: _selectedWorkouts,
              dayShortLabelBuilder: _dayShortLabel,
              dayFullLabelBuilder: _dayFullLabel,
              onToggleWorkout: _toggleWorkout,
              onReorderWorkouts: _reorderWorkouts,
              onToggleWeekDay: _toggleWeekDay,
              onSelectBusinessDays: _selectBusinessDays,
              onSelectAllWeekDays: _selectAllWeekDays,
              onSelectWeekendDays: _selectWeekendDays,
              onClearWeekDays: _clearWeekDays,
            ),
    );
  }
}

class _WorkoutPlanBody extends StatelessWidget {
  final List<Workout> workouts;
  final List<String> selectedWorkoutIds;
  final List<int> selectedWeekDays;
  final List<Workout> selectedWorkouts;
  final String Function(int day) dayShortLabelBuilder;
  final String Function(int day) dayFullLabelBuilder;
  final ValueChanged<String> onToggleWorkout;
  final void Function(int oldIndex, int newIndex) onReorderWorkouts;
  final ValueChanged<int> onToggleWeekDay;
  final VoidCallback onSelectBusinessDays;
  final VoidCallback onSelectAllWeekDays;
  final VoidCallback onSelectWeekendDays;
  final VoidCallback onClearWeekDays;

  const _WorkoutPlanBody({
    required this.workouts,
    required this.selectedWorkoutIds,
    required this.selectedWeekDays,
    required this.selectedWorkouts,
    required this.dayShortLabelBuilder,
    required this.dayFullLabelBuilder,
    required this.onToggleWorkout,
    required this.onReorderWorkouts,
    required this.onToggleWeekDay,
    required this.onSelectBusinessDays,
    required this.onSelectAllWeekDays,
    required this.onSelectWeekendDays,
    required this.onClearWeekDays,
  });

  @override
  Widget build(BuildContext context) {
    final availableWorkouts = workouts
        .where((workout) => !selectedWorkoutIds.contains(workout.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
      children: [
        if (workouts.isEmpty)
          const _EmptyWorkoutPoolCard()
        else
          _WorkoutSequenceCard(
            selectedWorkoutIds: selectedWorkoutIds,
            selectedWorkouts: selectedWorkouts,
            availableCount: availableWorkouts.length,
            onAddPressed: availableWorkouts.isEmpty
                ? null
                : () => _showAddWorkoutSheet(context),
            onToggleWorkout: onToggleWorkout,
            onReorderWorkouts: onReorderWorkouts,
          ),
        const SizedBox(height: 10),
        _WeekDaySelectorCard(
          selectedWeekDays: selectedWeekDays,
          dayShortLabelBuilder: dayShortLabelBuilder,
          dayFullLabelBuilder: dayFullLabelBuilder,
          onToggleWeekDay: onToggleWeekDay,
          onSelectBusinessDays: onSelectBusinessDays,
          onSelectAllWeekDays: onSelectAllWeekDays,
          onSelectWeekendDays: onSelectWeekendDays,
          onClearWeekDays: onClearWeekDays,
        ),
      ],
    );
  }

  void _showAddWorkoutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final availableWorkouts = workouts
                .where((workout) => !selectedWorkoutIds.contains(workout.id))
                .toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  decoration: BoxDecoration(
                    color: AppThemeColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppThemeColors.outlineStrong),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.68,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppThemeColors.outlineStrong,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Adicionar treinos',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${availableWorkouts.length} disponivel(is)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppThemeColors.textMuted,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Fechar',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (availableWorkouts.isEmpty)
                          const _AllWorkoutsAddedCard()
                        else
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: availableWorkouts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final workout = availableWorkouts[index];

                                return _WorkoutToggleCard(
                                  workout: workout,
                                  selected: false,
                                  order: null,
                                  onToggle: () {
                                    onToggleWorkout(workout.id);
                                    setSheetState(() {});
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
          },
        );
      },
    );
  }
}

class _EmptyWorkoutPoolCard extends StatelessWidget {
  const _EmptyWorkoutPoolCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Crie treinos para organizar a semana.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _WorkoutSequenceCard extends StatelessWidget {
  final List<String> selectedWorkoutIds;
  final List<Workout> selectedWorkouts;
  final int availableCount;
  final VoidCallback? onAddPressed;
  final ValueChanged<String> onToggleWorkout;
  final void Function(int oldIndex, int newIndex) onReorderWorkouts;

  const _WorkoutSequenceCard({
    required this.selectedWorkoutIds,
    required this.selectedWorkouts,
    required this.availableCount,
    required this.onAddPressed,
    required this.onToggleWorkout,
    required this.onReorderWorkouts,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = selectedWorkoutIds.isEmpty
        ? '$availableCount disponivel(is)'
        : '${selectedWorkoutIds.length} na sequencia';
    final sequenceCanScroll = selectedWorkouts.length > 4;
    final sequenceListHeight = sequenceCanScroll
        ? 296.0
        : selectedWorkouts.length * 72.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppThemeColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    size: 18,
                    color: AppThemeColors.primaryStrong,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Treinos', style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: availableCount == 0
                      ? 'Todos os treinos adicionados'
                      : 'Adicionar treino',
                  child: IconButton.filledTonal(
                    onPressed: onAddPressed,
                    icon: Icon(
                      availableCount == 0
                          ? Icons.check_circle_outline_rounded
                          : Icons.add_rounded,
                    ),
                    style: IconButton.styleFrom(
                      fixedSize: const Size(40, 40),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (selectedWorkouts.isEmpty)
              const _EmptySelectedSequenceCard()
            else
              SizedBox(
                height: sequenceListHeight,
                child: SingleChildScrollView(
                  physics: sequenceCanScroll
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    itemCount: selectedWorkouts.length,
                    physics: const NeverScrollableScrollPhysics(),
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1.02).animate(
                            animation,
                          ),
                          child: child,
                        ),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      var targetIndex = newIndex;
                      if (targetIndex < 0) targetIndex = 0;
                      if (targetIndex > selectedWorkoutIds.length) {
                        targetIndex = selectedWorkoutIds.length;
                      }

                      onReorderWorkouts(oldIndex, targetIndex);
                    },
                    itemBuilder: (context, index) {
                      final workout = selectedWorkouts[index];

                      return Padding(
                        key: ValueKey(workout.id),
                        padding: EdgeInsets.only(
                          bottom: index == selectedWorkouts.length - 1 ? 0 : 8,
                        ),
                        child: _WorkoutToggleCard(
                          workout: workout,
                          selected: true,
                          order: index + 1,
                          onToggle: () => onToggleWorkout(workout.id),
                          dragHandle: ReorderableDragStartListener(
                            index: index,
                            child: const Tooltip(
                              message: 'Arrastar para reorganizar',
                              child: Icon(Icons.drag_indicator_rounded),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptySelectedSequenceCard extends StatelessWidget {
  const _EmptySelectedSequenceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.playlist_add_rounded,
            color: AppThemeColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhum treino na sequencia semanal.',
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

class _AllWorkoutsAddedCard extends StatelessWidget {
  const _AllWorkoutsAddedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppThemeColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemeColors.secondary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        'Todos os treinos disponiveis ja estao na semana.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppThemeColors.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkoutToggleCard extends StatelessWidget {
  final Workout workout;
  final bool selected;
  final int? order;
  final VoidCallback onToggle;
  final Widget? dragHandle;

  const _WorkoutToggleCard({
    required this.workout,
    required this.selected,
    required this.order,
    required this.onToggle,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final description = workout.description.trim().isEmpty
        ? 'Sem descricao definida'
        : workout.description.trim();
    final actionIcon = selected ? Icons.remove_rounded : Icons.add_rounded;
    final actionMessage = selected ? 'Remover da semana' : 'Adicionar na semana';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? AppThemeColors.secondary.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppThemeColors.secondary.withValues(alpha: 0.18)
                        : AppThemeColors.outline,
                  ),
                ),
                child: Center(
                  child: Text(
                    order != null ? '$order' : '+',
                    style: TextStyle(
                      color: selected
                          ? AppThemeColors.secondary
                          : AppThemeColors.textMuted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemeColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (dragHandle != null) ...[
                const SizedBox(width: 6),
                SizedBox(width: 34, height: 34, child: dragHandle!),
              ],
              const SizedBox(width: 4),
              Tooltip(
                message: actionMessage,
                child: IconButton(
                  onPressed: onToggle,
                  icon: Icon(actionIcon),
                  color: selected
                      ? AppThemeColors.secondary
                      : AppThemeColors.primaryStrong,
                  style: IconButton.styleFrom(
                    fixedSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekDaySelectorCard extends StatelessWidget {
  final List<int> selectedWeekDays;
  final String Function(int day) dayShortLabelBuilder;
  final String Function(int day) dayFullLabelBuilder;
  final ValueChanged<int> onToggleWeekDay;
  final VoidCallback onSelectBusinessDays;
  final VoidCallback onSelectAllWeekDays;
  final VoidCallback onSelectWeekendDays;
  final VoidCallback onClearWeekDays;

  const _WeekDaySelectorCard({
    required this.selectedWeekDays,
    required this.dayShortLabelBuilder,
    required this.dayFullLabelBuilder,
    required this.onToggleWeekDay,
    required this.onSelectBusinessDays,
    required this.onSelectAllWeekDays,
    required this.onSelectWeekendDays,
    required this.onClearWeekDays,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLabels = selectedWeekDays.map(dayShortLabelBuilder).join(' | ');
    final summary = selectedWeekDays.isEmpty
        ? 'Nenhum dia marcado'
        : selectedLabels;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppThemeColors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: AppThemeColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dias esperados',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${selectedWeekDays.length}/7',
                    style: const TextStyle(
                      color: AppThemeColors.primaryStrong,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _WeekDayPresetButton(
                    icon: Icons.work_history_outlined,
                    label: 'Seg-Sex',
                    onPressed: onSelectBusinessDays,
                  ),
                  const SizedBox(width: 6),
                  _WeekDayPresetButton(
                    icon: Icons.beach_access_outlined,
                    label: 'Fim',
                    onPressed: onSelectWeekendDays,
                  ),
                  const SizedBox(width: 6),
                  _WeekDayPresetButton(
                    icon: Icons.calendar_month_outlined,
                    label: 'Todos',
                    onPressed: onSelectAllWeekDays,
                  ),
                  const SizedBox(width: 6),
                  _WeekDayPresetButton(
                    icon: Icons.layers_clear_rounded,
                    label: 'Limpar',
                    onPressed: onClearWeekDays,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 6.0;
                final columns = constraints.maxWidth >= 320 ? 7 : 4;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final selected = selectedWeekDays.contains(day);

                    return SizedBox(
                      width: itemWidth,
                      child: _WeekDayTile(
                        shortLabel: dayShortLabelBuilder(day),
                        label: dayFullLabelBuilder(day),
                        selected: selected,
                        onTap: () => onToggleWeekDay(day),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayPresetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _WeekDayPresetButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WeekDayTile extends StatelessWidget {
  final String shortLabel;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WeekDayTile({
    required this.shortLabel,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppThemeColors.primary.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppThemeColors.primary.withValues(alpha: 0.26)
                    : AppThemeColors.outline,
              ),
            ),
            child: Center(
              child: Text(
                shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppThemeColors.primaryStrong
                      : AppThemeColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
