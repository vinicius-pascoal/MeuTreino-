import 'package:flutter/material.dart';

import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/exercise_image.dart';
import '../data/exercise_library_service.dart';
import '../models/exercise.dart';

enum _ExerciseTypeFilter { all, compound, isolation }

class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({super.key});

  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  final _service = ExerciseLibraryService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  _ExerciseTypeFilter _selectedType = _ExerciseTypeFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters {
    return _searchQuery.trim().isNotEmpty ||
        _selectedMuscleGroup != null ||
        _selectedEquipment != null ||
        _selectedType != _ExerciseTypeFilter.all;
  }

  int get _activeFilterCount {
    var count = 0;

    if (_selectedMuscleGroup != null) count++;
    if (_selectedEquipment != null) count++;
    if (_selectedType != _ExerciseTypeFilter.all) count++;

    return count;
  }

  Future<void> _seedLibrary() async {
    await _service.seedDefaultExercises();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biblioteca inicial criada/atualizada.')),
    );
  }

  Future<void> _openFiltersSheet(List<Exercise> exercises) async {
    final muscleGroups = _collectOptions(
      exercises.map((exercise) => exercise.muscleGroup),
    );
    final equipments = _collectOptions(
      exercises.map((exercise) => exercise.equipment),
    );

    var tempMuscleGroup = _selectedMuscleGroup;
    var tempEquipment = _selectedEquipment;
    var tempType = _selectedType;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1B2D),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtros da biblioteca',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Refine a busca por grupo muscular, equipamento e tipo.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      const _FilterSectionTitle('Tipo'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTypeChip(
                            label: 'Todos',
                            value: _ExerciseTypeFilter.all,
                            selectedValue: tempType,
                            onSelected: (value) {
                              setSheetState(() => tempType = value);
                            },
                          ),
                          _buildTypeChip(
                            label: 'Compostos',
                            value: _ExerciseTypeFilter.compound,
                            selectedValue: tempType,
                            onSelected: (value) {
                              setSheetState(() => tempType = value);
                            },
                          ),
                          _buildTypeChip(
                            label: 'Isolados',
                            value: _ExerciseTypeFilter.isolation,
                            selectedValue: tempType,
                            onSelected: (value) {
                              setSheetState(() => tempType = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _FilterSectionTitle('Grupo muscular'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: muscleGroups
                            .map(
                              (group) => FilterChip(
                                label: Text(group),
                                selected: tempMuscleGroup == group,
                                onSelected: (_) {
                                  setSheetState(() {
                                    tempMuscleGroup = tempMuscleGroup == group
                                        ? null
                                        : group;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      const _FilterSectionTitle('Equipamento'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: equipments
                            .map(
                              (equipment) => FilterChip(
                                label: Text(equipment),
                                selected: tempEquipment == equipment,
                                onSelected: (_) {
                                  setSheetState(() {
                                    tempEquipment =
                                        tempEquipment == equipment
                                        ? null
                                        : equipment;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempMuscleGroup = null;
                                  tempEquipment = null;
                                  tempType = _ExerciseTypeFilter.all;
                                });
                              },
                              child: const Text('Limpar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedMuscleGroup = tempMuscleGroup;
                                  _selectedEquipment = tempEquipment;
                                  _selectedType = tempType;
                                });
                                Navigator.of(sheetContext).pop();
                              },
                              child: const Text('Aplicar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<String> _collectOptions(Iterable<String> values) {
    final options = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return options;
  }

  List<Exercise> _applyFilters(List<Exercise> exercises) {
    final query = _normalize(_searchQuery);

    return exercises.where((exercise) {
      if (_selectedMuscleGroup != null &&
          exercise.muscleGroup != _selectedMuscleGroup) {
        return false;
      }

      if (_selectedEquipment != null &&
          exercise.equipment != _selectedEquipment) {
        return false;
      }

      if (_selectedType == _ExerciseTypeFilter.compound &&
          !exercise.isCompound) {
        return false;
      }

      if (_selectedType == _ExerciseTypeFilter.isolation &&
          exercise.isCompound) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final haystack = _normalize(
        [
          exercise.name,
          exercise.muscleGroup,
          exercise.muscleRegion,
          exercise.movementPattern,
          exercise.equipment,
          exercise.instructions,
        ].join(' '),
      );

      return haystack.contains(query);
    }).toList();
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _selectedType = _ExerciseTypeFilter.all;
    });
  }

  String _exerciseSubtitle(Exercise exercise) {
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

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Biblioteca de exercicios',
      currentIndex: 4,
      actions: [
        IconButton(
          tooltip: 'Popular biblioteca',
          onPressed: _seedLibrary,
          icon: const Icon(Icons.cloud_sync),
        ),
      ],
      body: StreamBuilder<List<Exercise>>(
        stream: _service.watchExercises(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = snapshot.data!;

          if (exercises.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 56,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum exercicio cadastrado.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _seedLibrary,
                      icon: const Icon(Icons.add),
                      label: const Text('Criar biblioteca inicial'),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredExercises = _applyFilters(exercises);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar por nome, grupo, movimento ou equipamento',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchQuery.trim().isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar busca',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              height: 56,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _openFiltersSheet(exercises),
                                icon: const Icon(Icons.tune_rounded),
                                label: const Text('Filtros'),
                              ),
                            ),
                            if (_activeFilterCount > 0)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF052E16),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          '${filteredExercises.length} de ${exercises.length} exercicios',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: _clearAllFilters,
                            child: const Text('Limpar tudo'),
                          ),
                      ],
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_searchQuery.trim().isNotEmpty)
                              InputChip(
                                label: Text('Busca: ${_searchQuery.trim()}'),
                                onDeleted: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            if (_selectedMuscleGroup != null)
                              InputChip(
                                label: Text(_selectedMuscleGroup!),
                                onDeleted: () {
                                  setState(() => _selectedMuscleGroup = null);
                                },
                              ),
                            if (_selectedEquipment != null)
                              InputChip(
                                label: Text(_selectedEquipment!),
                                onDeleted: () {
                                  setState(() => _selectedEquipment = null);
                                },
                              ),
                            if (_selectedType != _ExerciseTypeFilter.all)
                              InputChip(
                                label: Text(
                                  _selectedType == _ExerciseTypeFilter.compound
                                      ? 'Compostos'
                                      : 'Isolados',
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _selectedType = _ExerciseTypeFilter.all;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (filteredExercises.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.white60,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Nenhum exercicio encontrado com os filtros atuais.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tente ajustar a busca ou remover alguns filtros.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              else
                ...filteredExercises.map(
                  (exercise) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExerciseImage(
                            imageAsset: exercise.imageAsset,
                            height: 180,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _exerciseSubtitle(exercise),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _LibraryTag(
                                      label: exercise.isCompound
                                          ? 'Composto'
                                          : 'Isolado',
                                      tone: exercise.isCompound
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFF38BDF8),
                                    ),
                                    if (exercise.movementPattern.trim().isNotEmpty)
                                      _LibraryTag(
                                        label: exercise.movementPattern.trim(),
                                        tone: const Color(0xFFF59E0B),
                                      ),
                                  ],
                                ),
                                if (exercise.instructions.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    exercise.instructions,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required _ExerciseTypeFilter value,
    required _ExerciseTypeFilter selectedValue,
    required ValueChanged<_ExerciseTypeFilter> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: value == selectedValue,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  final String title;

  const _FilterSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _LibraryTag extends StatelessWidget {
  final String label;
  final Color tone;

  const _LibraryTag({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: tone, fontWeight: FontWeight.w700),
      ),
    );
  }
}
