import 'package:flutter/material.dart';

import '../../../core/widgets/app_page_scaffold.dart';
import '../data/workout_automation_service.dart';

class AutoWorkoutPage extends StatefulWidget {
  const AutoWorkoutPage({super.key});

  @override
  State<AutoWorkoutPage> createState() => _AutoWorkoutPageState();
}

class _AutoWorkoutPageState extends State<AutoWorkoutPage> {
  final _automationService = WorkoutAutomationService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repsController = TextEditingController(text: '8-10');
  final _weightController = TextEditingController(text: '0');

  final List<String> _availableGroups = const [
    'Peito',
    'Costas',
    'Ombro',
    'B\u00edceps',
    'Tr\u00edceps',
    'Pernas',
    'Abd\u00f4men',
  ];

  final List<String> _selectedGroups = [];
  final Map<String, int> _exercisesPerGroup = {};

  int _sets = 3;
  int _restSeconds = 90;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _toggleGroup(String group) {
    setState(() {
      if (_selectedGroups.contains(group)) {
        _selectedGroups.remove(group);
        _exercisesPerGroup.remove(group);
      } else {
        _selectedGroups.add(group);
        _exercisesPerGroup[group] = _exercisesPerGroup[group] ?? 2;
      }
    });
  }

  void _updateGroupExerciseCount(String group, int value) {
    setState(() {
      _exercisesPerGroup[group] = value;
    });
  }

  Future<void> _generateWorkout() async {
    setState(() => _loading = true);

    try {
      await _automationService.generateWorkout(
        name: _nameController.text,
        description: _descriptionController.text,
        muscleGroups: _selectedGroups,
        exercisesPerGroup: {
          for (final group in _selectedGroups) group: _exercisesPerGroup[group] ?? 2,
        },
        sets: _sets,
        targetReps: _repsController.text.trim(),
        restSeconds: _restSeconds,
        currentWeight:
            double.tryParse(
              _weightController.text.trim().replaceAll(',', '.'),
            ) ??
            0,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino automatico criado com sucesso.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar treino: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _suggestedName() {
    if (_selectedGroups.isEmpty) return '';

    return 'Treino ${_selectedGroups.join(", ")}';
  }

  void _useSuggestedName() {
    final suggestion = _suggestedName();

    if (suggestion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um grupo muscular.'),
        ),
      );
      return;
    }

    setState(() {
      _nameController.text = suggestion;
      _descriptionController.text =
          'Treino gerado automaticamente para ${_selectedGroups.join(", ")}.';
    });
  }

  int get _estimatedExerciseCount {
    return _selectedGroups.fold<int>(
      0,
      (sum, group) => sum + (_exercisesPerGroup[group] ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Montar treino automatico',
      currentIndex: 4,
      bottomAction: SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: _loading ? null : _generateWorkout,
          icon: const Icon(Icons.auto_awesome),
          label: _loading
              ? const Text('Gerando treino...')
              : const Text('Gerar treino'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 118),
        children: [
          _AutomationSummaryCard(
            selectedGroups: _selectedGroups.length,
            estimatedExercises: _estimatedExerciseCount,
          ),
          const SizedBox(height: 10),
          _MuscleGroupsCard(
            availableGroups: _availableGroups,
            selectedGroups: _selectedGroups,
            exercisesPerGroup: _exercisesPerGroup,
            onToggleGroup: _toggleGroup,
            onGroupCountChanged: _updateGroupExerciseCount,
          ),
          const SizedBox(height: 10),
          _WorkoutIdentityCard(
            nameController: _nameController,
            descriptionController: _descriptionController,
            onUseSuggestedName: _useSuggestedName,
          ),
          const SizedBox(height: 10),
          _ExerciseDefaultsCard(
            sets: _sets,
            restSeconds: _restSeconds,
            repsController: _repsController,
            weightController: _weightController,
            onSetsChanged: (value) {
              setState(() {
                _sets = value;
              });
            },
            onRestChanged: (value) {
              setState(() {
                _restSeconds = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _AutomationSummaryCard extends StatelessWidget {
  final int selectedGroups;
  final int estimatedExercises;

  const _AutomationSummaryCard({
    required this.selectedGroups,
    required this.estimatedExercises,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedGroups > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2940), Color(0xFF101827)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF243041)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF86EFAC),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Treino automatico',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSelection
                      ? '$selectedGroups grupos - ate $estimatedExercises exercicios'
                      : 'Selecione os grupos e ajuste os padroes.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupsCard extends StatelessWidget {
  final List<String> availableGroups;
  final List<String> selectedGroups;
  final Map<String, int> exercisesPerGroup;
  final ValueChanged<String> onToggleGroup;
  final void Function(String group, int value) onGroupCountChanged;

  const _MuscleGroupsCard({
    required this.availableGroups,
    required this.selectedGroups,
    required this.exercisesPerGroup,
    required this.onToggleGroup,
    required this.onGroupCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CompactSectionHeader(
              icon: Icons.sports_gymnastics_rounded,
              title: 'Grupos musculares',
              subtitle: 'Toque para incluir no treino',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableGroups.map((group) {
                final selected = selectedGroups.contains(group);

                return FilterChip(
                  label: Text(group),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onToggleGroup(group),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (selectedGroups.isEmpty)
              const _MutedHint(
                icon: Icons.touch_app_rounded,
                text: 'Escolha ao menos um grupo para liberar as quantidades.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedGroups.map((group) {
                  return _GroupQuantityPill(
                    group: group,
                    value: exercisesPerGroup[group] ?? 2,
                    onChanged: (value) => onGroupCountChanged(group, value),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutIdentityCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final VoidCallback onUseSuggestedName;

  const _WorkoutIdentityCard({
    required this.nameController,
    required this.descriptionController,
    required this.onUseSuggestedName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: _CompactSectionHeader(
                    icon: Icons.edit_note_rounded,
                    title: 'Identificacao',
                    subtitle: 'Nome e descricao do treino',
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onUseSuggestedName,
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                  label: const Text('Sugerir'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DenseTextField(
              controller: nameController,
              label: 'Nome',
              hint: 'Ex: Costas e biceps',
            ),
            const SizedBox(height: 10),
            _DenseTextField(
              controller: descriptionController,
              label: 'Descricao',
              hint: 'Treino gerado automaticamente',
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDefaultsCard extends StatelessWidget {
  final int sets;
  final int restSeconds;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final ValueChanged<int> onSetsChanged;
  final ValueChanged<int> onRestChanged;

  const _ExerciseDefaultsCard({
    required this.sets,
    required this.restSeconds,
    required this.repsController,
    required this.weightController,
    required this.onSetsChanged,
    required this.onRestChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CompactSectionHeader(
              icon: Icons.tune_rounded,
              title: 'Padroes dos exercicios',
              subtitle: 'Series, descanso, reps e carga',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 10) / 2;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _CompactNumberSelector(
                        title: 'Series',
                        value: sets,
                        min: 1,
                        max: 6,
                        onChanged: onSetsChanged,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _CompactNumberSelector(
                        title: 'Descanso',
                        value: restSeconds,
                        min: 30,
                        max: 180,
                        step: 15,
                        suffix: 's',
                        onChanged: onRestChanged,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _DenseTextField(
                        controller: repsController,
                        label: 'Reps',
                        hint: '8-10',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _DenseTextField(
                        controller: weightController,
                        label: 'Carga',
                        suffix: 'kg',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CompactSectionHeader({
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
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF86EFAC)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MutedHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MutedHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white60),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupQuantityPill extends StatelessWidget {
  final String group;
  final int value;
  final ValueChanged<int> onChanged;

  const _GroupQuantityPill({
    required this.group,
    required this.value,
    required this.onChanged,
  });

  void _decrease() {
    if (value <= 1) return;
    onChanged(value - 1);
  }

  void _increase() {
    if (value >= 8) return;
    onChanged(value + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 7, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            group,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(width: 8),
          _MiniStepButton(
            icon: Icons.remove_rounded,
            onPressed: value <= 1 ? null : _decrease,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Text(
              '$value',
              style: const TextStyle(
                color: Color(0xFF86EFAC),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _MiniStepButton(
            icon: Icons.add_rounded,
            onPressed: value >= 8 ? null : _increase,
          ),
        ],
      ),
    );
  }
}

class _CompactNumberSelector extends StatelessWidget {
  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _CompactNumberSelector({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    this.suffix = '',
    required this.onChanged,
  });

  void _decrease() {
    final nextValue = value - step;

    if (nextValue < min) return;

    onChanged(nextValue);
  }

  void _increase() {
    final nextValue = value + step;

    if (nextValue > max) return;

    onChanged(nextValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          _MiniStepButton(
            icon: Icons.remove_rounded,
            onPressed: value <= min ? null : _decrease,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value$suffix',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF86EFAC),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _MiniStepButton(
            icon: Icons.add_rounded,
            onPressed: value >= max ? null : _increase,
          ),
        ],
      ),
    );
  }
}

class _MiniStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _MiniStepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      ),
    );
  }
}

class _DenseTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final TextInputType? keyboardType;

  const _DenseTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }
}
