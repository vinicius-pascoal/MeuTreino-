import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/navigation/app_navigation_state_service.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
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

  void _moveWorkout(String workoutId, int offset) {
    final currentIndex = _selectedWorkoutIds.indexOf(workoutId);
    if (currentIndex < 0) return;

    final nextIndex = currentIndex + offset;
    if (nextIndex < 0 || nextIndex >= _selectedWorkoutIds.length) return;

    setState(() {
      final movedWorkoutId = _selectedWorkoutIds.removeAt(currentIndex);
      _selectedWorkoutIds.insert(nextIndex, movedWorkoutId);
    });
  }

  void _clearSequence() {
    setState(_selectedWorkoutIds.clear);
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

  Workout? _findWorkoutById(String workoutId) {
    for (final workout in _workouts) {
      if (workout.id == workoutId) {
        return workout;
      }
    }

    return null;
  }

  String _dayLabel(int day) {
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
      bottomAction: SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: _loading || _saving ? null : _savePlan,
          icon: const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Salvando...' : 'Salvar plano semanal'),
        ),
      ),
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
              dayLabelBuilder: _dayLabel,
              onToggleWorkout: _toggleWorkout,
              onMoveWorkoutUp: (workoutId) => _moveWorkout(workoutId, -1),
              onMoveWorkoutDown: (workoutId) => _moveWorkout(workoutId, 1),
              onClearSequence: _clearSequence,
              onToggleWeekDay: _toggleWeekDay,
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
  final String Function(int day) dayLabelBuilder;
  final ValueChanged<String> onToggleWorkout;
  final ValueChanged<String> onMoveWorkoutUp;
  final ValueChanged<String> onMoveWorkoutDown;
  final VoidCallback onClearSequence;
  final ValueChanged<int> onToggleWeekDay;

  const _WorkoutPlanBody({
    required this.workouts,
    required this.selectedWorkoutIds,
    required this.selectedWeekDays,
    required this.selectedWorkouts,
    required this.isPlanReady,
    required this.dayLabelBuilder,
    required this.onToggleWorkout,
    required this.onMoveWorkoutUp,
    required this.onMoveWorkoutDown,
    required this.onClearSequence,
    required this.onToggleWeekDay,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 228),
      children: [
        _PlanOverviewCard(
          selectedWorkoutCount: selectedWorkoutIds.length,
          selectedDayCount: selectedWeekDays.length,
          availableWorkoutCount: workouts.length,
          isPlanReady: isPlanReady,
          onClearSequence: selectedWorkoutIds.isEmpty ? null : onClearSequence,
        ),
        const SizedBox(height: 24),
        const AppSectionHeader(
          title: 'Sequencia ativa',
          subtitle:
              'Defina a ordem em que os treinos vao aparecer ao longo da semana.',
        ),
        const SizedBox(height: 12),
        if (selectedWorkouts.isEmpty)
          const _EmptySequenceCard()
        else
          ...selectedWorkouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectedWorkoutCard(
                order: index + 1,
                workout: workout,
                canMoveUp: index > 0,
                canMoveDown: index < selectedWorkouts.length - 1,
                onMoveUp: () => onMoveWorkoutUp(workout.id),
                onMoveDown: () => onMoveWorkoutDown(workout.id),
                onRemove: () => onToggleWorkout(workout.id),
              ),
            );
          }),
        const SizedBox(height: 24),
        const AppSectionHeader(
          title: 'Treinos disponiveis',
          subtitle:
              'Escolha quais treinos entram no ciclo semanal e adicione quando fizer sentido.',
        ),
        const SizedBox(height: 12),
        if (workouts.isEmpty)
          const _EmptyWorkoutPoolCard()
        else
          ...workouts.map((workout) {
            final selected = selectedWorkoutIds.contains(workout.id);
            final order = selected ? selectedWorkoutIds.indexOf(workout.id) + 1 : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WorkoutToggleCard(
                workout: workout,
                selected: selected,
                order: order,
                onToggle: () => onToggleWorkout(workout.id),
              ),
            );
          }),
        const SizedBox(height: 24),
        const AppSectionHeader(
          title: 'Dias esperados',
          subtitle:
              'Marque os dias em que a rotina deve esperar um treino para acompanhar melhor sua frequencia.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(7, (index) {
            final day = index + 1;
            final selected = selectedWeekDays.contains(day);

            return _WeekDayChip(
              label: dayLabelBuilder(day),
              selected: selected,
              onTap: () => onToggleWeekDay(day),
            );
          }),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'Resumo atual: ${selectedWorkoutIds.length} treinos na sequencia e ${selectedWeekDays.length} dias marcados na semana.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
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
  final VoidCallback? onClearSequence;

  const _PlanOverviewCard({
    required this.selectedWorkoutCount,
    required this.selectedDayCount,
    required this.availableWorkoutCount,
    required this.isPlanReady,
    required this.onClearSequence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gestao da semana',
                  style: theme.textTheme.labelMedium,
                ),
              ),
              _StatusPill(
                label: isPlanReady ? 'Pronto' : 'Incompleto',
                tone: isPlanReady
                    ? AppThemeColors.primaryStrong
                    : AppThemeColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Monte a ordem da rotina com mais clareza.',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha os treinos, organize a sequencia e marque os dias esperados sem sair do fluxo principal do app.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'Sequencia',
                  value: '$selectedWorkoutCount',
                  accent: AppThemeColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMetric(
                  label: 'Dias',
                  value: '$selectedDayCount',
                  accent: AppThemeColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMetric(
                  label: 'Base',
                  value: '$availableWorkoutCount',
                  accent: AppThemeColors.warning,
                ),
              ),
            ],
          ),
          if (onClearSequence != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClearSequence,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Limpar sequencia'),
              ),
            ),
          ],
        ],
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accent,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: tone, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptySequenceCard extends StatelessWidget {
  const _EmptySequenceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'Adicione treinos abaixo para montar a sequencia semanal. A ordem escolhida aqui sera a ordem sugerida no app.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SelectedWorkoutCard extends StatelessWidget {
  final int order;
  final Workout workout;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  const _SelectedWorkoutCard({
    required this.order,
    required this.workout,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final description = workout.description.trim().isEmpty
        ? 'Sem descricao definida'
        : workout.description.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppThemeColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$order',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppThemeColors.primaryStrong,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canMoveUp ? onMoveUp : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: const Text('Subir'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canMoveDown ? onMoveDown : null,
                    icon: const Icon(Icons.arrow_downward_rounded),
                    label: const Text('Descer'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(18),
        child: Text(
          'Voce ainda nao criou treinos suficientes para montar a semana. Cadastre alguns treinos e volte aqui para organizar a ordem.',
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

  const _WorkoutToggleCard({
    required this.workout,
    required this.selected,
    required this.order,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final description = workout.description.trim().isEmpty
        ? 'Sem descricao definida'
        : workout.description.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? AppThemeColors.secondary.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppThemeColors.secondary.withValues(alpha: 0.18)
                        : AppThemeColors.outline,
                  ),
                ),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: selected
                      ? AppThemeColors.secondary
                      : AppThemeColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workout.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (order != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Ordem $order',
                              style: const TextStyle(
                                color: AppThemeColors.primaryStrong,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selected ? 'Incluido na semana' : 'Toque para adicionar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? AppThemeColors.secondary
                            : AppThemeColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WeekDayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppThemeColors.primary.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppThemeColors.primary.withValues(alpha: 0.2)
                  : AppThemeColors.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppThemeColors.primaryStrong
                  : AppThemeColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
