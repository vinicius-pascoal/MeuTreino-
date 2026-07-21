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

  bool _loading = true;
  bool _saving = false;
  List<Workout> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
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

    setState(() {
      _workouts = workouts;
      _loading = false;
    });
  }

  Future<void> _savePlan() async {
    if (_selectedWorkoutIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um treino.')),
      );
      return;
    }

    if (_selectedWeekDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia esperado de treino.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _planService.savePlan(
        sequenceWorkoutIds: _selectedWorkoutIds,
        trainingWeekDays: _selectedWeekDays,
      );
      await _homeWidgetService.syncFromAppState();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino semanal salvo com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar treino semanal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
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
  }

  void _reorderWorkouts(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final movedWorkoutId = _selectedWorkoutIds.removeAt(oldIndex);
      _selectedWorkoutIds.insert(newIndex, movedWorkoutId);
    });
  }

  void _clearSequence() {
    setState(_selectedWorkoutIds.clear);
  }

  void _setWeekDays(List<int> days) {
    final normalizedDays = [...days]..sort();

    setState(() {
      _selectedWeekDays
        ..clear()
        ..addAll(normalizedDays);
    });
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

  bool get _isPlanReady {
    return _selectedWorkoutIds.isNotEmpty && _selectedWeekDays.isNotEmpty;
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
              isPlanReady: _isPlanReady,
              isSaving: _saving,
              dayShortLabelBuilder: _dayShortLabel,
              dayFullLabelBuilder: _dayFullLabel,
              onSavePlan: _savePlan,
              onToggleWorkout: _toggleWorkout,
              onReorderWorkouts: _reorderWorkouts,
              onClearSequence: _clearSequence,
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
  final bool isPlanReady;
  final bool isSaving;
  final String Function(int day) dayShortLabelBuilder;
  final String Function(int day) dayFullLabelBuilder;
  final VoidCallback onSavePlan;
  final ValueChanged<String> onToggleWorkout;
  final void Function(int oldIndex, int newIndex) onReorderWorkouts;
  final VoidCallback onClearSequence;
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
    required this.isPlanReady,
    required this.isSaving,
    required this.dayShortLabelBuilder,
    required this.dayFullLabelBuilder,
    required this.onSavePlan,
    required this.onToggleWorkout,
    required this.onReorderWorkouts,
    required this.onClearSequence,
    required this.onToggleWeekDay,
    required this.onSelectBusinessDays,
    required this.onSelectAllWeekDays,
    required this.onSelectWeekendDays,
    required this.onClearWeekDays,
  });

  @override
  Widget build(BuildContext context) {
    final orderedWorkouts = [
      ...selectedWorkouts,
      ...workouts.where((workout) => !selectedWorkoutIds.contains(workout.id)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
      children: [
        _PlanOverviewCard(
          selectedWorkoutCount: selectedWorkoutIds.length,
          selectedDayCount: selectedWeekDays.length,
          availableWorkoutCount: workouts.length,
          isPlanReady: isPlanReady,
          isSaving: isSaving,
          onSavePlan: onSavePlan,
          onClearSequence: selectedWorkoutIds.isEmpty ? null : onClearSequence,
        ),
        const SizedBox(height: 14),
        _CompactSectionTitle(
          icon: Icons.fitness_center_rounded,
          title: 'Treinos',
          subtitle: selectedWorkoutIds.isEmpty
              ? 'Toque para adicionar'
              : '${selectedWorkoutIds.length} na sequencia',
        ),
        const SizedBox(height: 8),
        if (workouts.isEmpty)
          const _EmptyWorkoutPoolCard()
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: orderedWorkouts.length,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 1.02).animate(animation),
                  child: child,
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              final selectedCount = selectedWorkoutIds.length;
              if (oldIndex >= selectedCount) return;

              var targetIndex = newIndex;
              if (targetIndex < 0) targetIndex = 0;
              if (targetIndex > selectedCount) {
                targetIndex = selectedCount;
              }

              onReorderWorkouts(oldIndex, targetIndex);
            },
            itemBuilder: (context, index) {
              final workout = orderedWorkouts[index];
              final selected = selectedWorkoutIds.contains(workout.id);
              final order = selected
                  ? selectedWorkoutIds.indexOf(workout.id) + 1
                  : null;

              return Padding(
                key: ValueKey(workout.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _WorkoutToggleCard(
                  workout: workout,
                  selected: selected,
                  order: order,
                  onToggle: () => onToggleWorkout(workout.id),
                  dragHandle: selected
                      ? ReorderableDragStartListener(
                          index: index,
                          child: const Tooltip(
                            message: 'Arrastar para reorganizar',
                            child: Icon(Icons.drag_indicator_rounded),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        const SizedBox(height: 12),
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
}

class _PlanOverviewCard extends StatelessWidget {
  final int selectedWorkoutCount;
  final int selectedDayCount;
  final int availableWorkoutCount;
  final bool isPlanReady;
  final bool isSaving;
  final VoidCallback onSavePlan;
  final VoidCallback? onClearSequence;

  const _PlanOverviewCard({
    required this.selectedWorkoutCount,
    required this.selectedDayCount,
    required this.availableWorkoutCount,
    required this.isPlanReady,
    required this.isSaving,
    required this.onSavePlan,
    required this.onClearSequence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestao da semana', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Ordem dos treinos e dias esperados.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(
                label: isPlanReady ? 'Pronto' : 'Incompleto',
                tone: isPlanReady
                    ? AppThemeColors.primaryStrong
                    : AppThemeColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OverviewMetric(
                label: 'Sequencia',
                value: '$selectedWorkoutCount',
                accent: AppThemeColors.primaryStrong,
              ),
              _OverviewMetric(
                label: 'Dias',
                value: '$selectedDayCount',
                accent: AppThemeColors.secondary,
              ),
              _OverviewMetric(
                label: 'Base',
                value: '$availableWorkoutCount',
                accent: AppThemeColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSavePlan,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(isSaving ? 'Salvando...' : 'Salvar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (onClearSequence != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Limpar sequencia',
                  child: IconButton.outlined(
                    onPressed: onClearSequence,
                    icon: const Icon(Icons.restart_alt_rounded),
                    style: IconButton.styleFrom(
                      fixedSize: const Size(44, 44),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CompactSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppThemeColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppThemeColors.primaryStrong),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
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
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemeColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color tone;

  const _StatusPill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: tone, fontWeight: FontWeight.w800, fontSize: 12),
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WeekDayPresetButton(
                  icon: Icons.work_history_outlined,
                  label: 'Seg-Sex',
                  onPressed: onSelectBusinessDays,
                ),
                _WeekDayPresetButton(
                  icon: Icons.beach_access_outlined,
                  label: 'Sab-Dom',
                  onPressed: onSelectWeekendDays,
                ),
                _WeekDayPresetButton(
                  icon: Icons.calendar_month_outlined,
                  label: 'Todos',
                  onPressed: onSelectAllWeekDays,
                ),
                _WeekDayPresetButton(
                  icon: Icons.layers_clear_rounded,
                  label: 'Limpar',
                  onPressed: onClearWeekDays,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final columns = constraints.maxWidth >= 560
                    ? 7
                    : constraints.maxWidth >= 360
                        ? 4
                        : 3;
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
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
                const SizedBox(width: 5),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 15,
                  color: selected
                      ? AppThemeColors.primaryStrong
                      : AppThemeColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
