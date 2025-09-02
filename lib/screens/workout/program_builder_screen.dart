// lib/screens/workout/program_builder_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glassmorphic_container.dart';

import '../../models/workout_exercise_dto.dart';
import '../../models/program_dtos.dart'; // <- use os DTOs daqui

class ProgramBuilderScreen extends StatefulWidget {
  final String initialModality; // 'bodybuilding' | 'crossfit' | 'hyrox'
  const ProgramBuilderScreen(
      {super.key, this.initialModality = 'bodybuilding'});

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();

  final _nameCtrl = TextEditingController(text: 'Série ABC');
  final _weeksCtrl = TextEditingController(text: '8');

  String _modality = 'bodybuilding';

  // blocos do programa (A/B/C/...)
  final List<_BlockVM> _blocks = [
    _BlockVM(code: 'A', title: 'Peito + Tríceps'),
    _BlockVM(code: 'B', title: 'Costas + Bíceps'),
    _BlockVM(code: 'C', title: 'Ombros + Pernas'),
  ];

  // catálogo carregado
  bool _loading = false;
  List<WorkoutExerciseDto> _catalog = [];

  // ativação
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _modality = widget.initialModality;
    _loadCatalog();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weeksCtrl.dispose();
    for (final b in _blocks) {
      b.titleCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;
      // carrega todos exercícios da modalidade (para CrossFit/Hyrox você pode manter a mesma lógica)
      final list = await _api.getExercisesByModality(token, _modality);
      if (!mounted) return;
      setState(() => _catalog = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar catálogo: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _addBlock() {
    final code = String.fromCharCode('A'.codeUnitAt(0) + _blocks.length);
    setState(() => _blocks.add(_BlockVM(code: code, title: '')));
  }

  void _removeBlock(int i) {
    setState(() => _blocks.removeAt(i));
  }

  Future<void> _pickExerciseForBlock(int blockIndex) async {
    final ex = await showModalBottomSheet<WorkoutExerciseDto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExercisePickerSheet(
        modality: _modality,
        catalog: _catalog,
        onSearch: (q) => _catalog
            .where((e) => e.name.toLowerCase().contains(q.toLowerCase()))
            .toList(),
      ),
    );
    if (ex == null) return;

    // configurar sets/reps/peso
    final cfg = await showDialog<_ExerciseCfg>(
      context: context,
      builder: (_) => _ExerciseCfgDialog(exercise: ex),
    );
    if (cfg == null) return;

    setState(() {
      _blocks[blockIndex].exercises.add(cfg);
      // reordena
      for (var i = 0; i < _blocks[blockIndex].exercises.length; i++) {
        _blocks[blockIndex].exercises[i] =
            _blocks[blockIndex].exercises[i].copyWith(order: i + 1);
      }
    });
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome para a série.')),
      );
      return;
    }
    if (_blocks.isEmpty || _blocks.any((b) => b.exercises.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione exercícios aos blocos.')),
      );
      return;
    }

    final weeks = int.tryParse(_weeksCtrl.text) ?? 8;

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      // monta payload
      final blocks = _blocks
          .map((b) => ProgramBlockInput(
                code: b.code,
                title: b.title.isEmpty ? null : b.title,
                exercises: b.exercises
                    .map((x) => ProgramBlockExerciseInput(
                          exerciseId: x.exercise.id,
                          order: x.order ?? 1,
                          sets: x.sets,
                          reps: x.reps,
                          weight: x.weight,
                        ))
                    .toList(),
              ))
          .toList();

      // cria
      final program = await _api.createProgram(
        token: token,
        name: _nameCtrl.text.trim(),
        modality: _modality,
        blocks: blocks,
      );

      // ativa (gera sessões no calendário)
      await _api.activateProgram(
        token: token,
        id: program.id,
        startDate: _startDate,
        weeks: weeks,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Série criada e ativada!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Data inicial da série',
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd/MM/yyyy');

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Criar série (ABC/ABCD)'),
        actions: [
          IconButton(
            tooltip: 'Salvar e ativar',
            icon: const Icon(Icons.check),
            onPressed: _submit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Modalidade (genérico: você pode montar programas também para CrossFit/Hyrox)
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Musculação'),
                selected: _modality == 'bodybuilding',
                onSelected: (_) {
                  setState(() => _modality = 'bodybuilding');
                  _loadCatalog();
                },
              ),
              ChoiceChip(
                label: const Text('CrossFit'),
                selected: _modality == 'crossfit',
                onSelected: (_) {
                  setState(() => _modality = 'crossfit');
                  _loadCatalog();
                },
              ),
              ChoiceChip(
                label: const Text('Hyrox'),
                selected: _modality == 'hyrox',
                onSelected: (_) {
                  setState(() => _modality = 'hyrox');
                  _loadCatalog();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome da série'),
          ),
          const SizedBox(height: 16),

          // Blocos
          Row(
            children: [
              Text(
                'Blocos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addBlock,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar bloco'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),

          ..._blocks.asMap().entries.map((e) {
            final i = e.key;
            final b = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassmorphicContainer(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Bloco ${b.code}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _removeBlock(i),
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                          ),
                        ],
                      ),
                      TextField(
                        controller: b.titleCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Título (opcional)'),
                        onChanged: (v) => b.title = v,
                      ),
                      const SizedBox(height: 8),
                      // exercícios do bloco
                      ...b.exercises.asMap().entries.map((ee) {
                        final j = ee.key;
                        final x = ee.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(x.exercise.name),
                          subtitle: Text(
                            'Séries ${x.sets}'
                            '${x.reps != null ? ' • Reps ${x.reps}' : ''}'
                            '${x.weight != null ? ' • ${x.weight!.toStringAsFixed(1)}kg' : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () =>
                                setState(() => b.exercises.removeAt(j)),
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _pickExerciseForBlock(i),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar exercício'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          // Ativação
          Text(
            'Ativação',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickStartDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Início'),
                    child: Text(df.format(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weeksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Semanas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Salvar série e ativar'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======= VMs/Widgets auxiliares =======

class _BlockVM {
  final String code;
  String title;
  final TextEditingController titleCtrl;
  final List<_ExerciseCfg> exercises;

  _BlockVM({
    required this.code,
    this.title = '',
    List<_ExerciseCfg>? exercises,
  })  : titleCtrl = TextEditingController(text: title),
        exercises = exercises ?? [];
}

class _ExerciseCfg {
  final WorkoutExerciseDto exercise;
  final int sets;
  final int? reps;
  final double? weight;
  final int? order;

  _ExerciseCfg({
    required this.exercise,
    required this.sets,
    this.reps,
    this.weight,
    this.order,
  });

  _ExerciseCfg copyWith({int? order}) => _ExerciseCfg(
        exercise: exercise,
        sets: sets,
        reps: reps,
        weight: weight,
        order: order ?? this.order,
      );
}

class _ExercisePickerSheet extends StatefulWidget {
  final String modality;
  final List<WorkoutExerciseDto> catalog;
  final List<WorkoutExerciseDto> Function(String query) onSearch;

  const _ExercisePickerSheet({
    super.key,
    required this.modality,
    required this.catalog,
    required this.onSearch,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _q.text.isEmpty ? widget.catalog : widget.onSearch(_q.text);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.black.withOpacity(0.2),
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _q,
                    decoration: const InputDecoration(
                      hintText: 'Buscar exercício...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final ex = results[i];
                        return ListTile(
                          title: Text(ex.name),
                          subtitle: Text(
                            '${ex.kind ?? '-'}'
                            '${ex.defaultReps != null ? ' • Reps ${ex.defaultReps}' : ''}'
                            '${ex.defaultWeight != null ? ' • ${ex.defaultWeight!.toStringAsFixed(1)}kg' : ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pop(ex),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseCfgDialog extends StatefulWidget {
  final WorkoutExerciseDto exercise;
  const _ExerciseCfgDialog({super.key, required this.exercise});

  @override
  State<_ExerciseCfgDialog> createState() => _ExerciseCfgDialogState();
}

class _ExerciseCfgDialogState extends State<_ExerciseCfgDialog> {
  final _sets = TextEditingController(text: '3');
  late final TextEditingController _reps;
  late final TextEditingController _weight;

  @override
  void initState() {
    super.initState();
    _reps = TextEditingController(text: '${widget.exercise.defaultReps ?? 10}');
    _weight = TextEditingController(
      text: (widget.exercise.defaultWeight ?? 0.0).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.exercise.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sets,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Séries'),
          ),
          TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Reps (opcional)'),
          ),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Peso (kg) (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final cfg = _ExerciseCfg(
              exercise: widget.exercise,
              sets: int.tryParse(_sets.text) ?? 3,
              reps: int.tryParse(_reps.text),
              weight: double.tryParse(_weight.text.replaceAll(',', '.')),
              order: null,
            );
            Navigator.pop(context, cfg);
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
