// lib/screens/workout/add_edit_workout_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout.dart';
import '../../models/workout_set.dart';

class AddEditWorkoutSheet extends StatefulWidget {
  final Workout? initial;
  final DateTime defaultDate;

  const AddEditWorkoutSheet({
    super.key,
    this.initial,
    required this.defaultDate,
  });

  @override
  State<AddEditWorkoutSheet> createState() => _AddEditWorkoutSheetState();
}

class _AddEditWorkoutSheetState extends State<AddEditWorkoutSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(); // minutos

  // Base
  DateTime _date = DateTime.now();
  WorkoutModality _modality = WorkoutModality.bodybuilding;
  WorkoutStatus _status = WorkoutStatus.pending;

  // Musculação
  String _muscle = 'Peito';
  List<WorkoutSet> _sets = [const WorkoutSet(reps: 10, weight: 0)];

  // CrossFit
  String _wodType = 'for_time'; // for_time | amrap | emom
  final _timeCapCtrl = TextEditingController(text: '15'); // min
  final _roundsCtrl = TextEditingController(text: '3');
  List<WorkoutSet> _blocksCF = [
    const WorkoutSet(label: 'WOD Block', reps: 10, weight: 0, order: 1),
  ];

  // Hyrox
  List<WorkoutSet> _blocksHyrox = [
    const WorkoutSet(label: 'Run 1km', reps: 0, weight: 0, order: 1),
    const WorkoutSet(label: 'Sled Push', reps: 12, weight: 0, order: 2),
    const WorkoutSet(label: 'Sled Pull', reps: 12, weight: 0, order: 3),
    const WorkoutSet(label: 'Burpee Broad Jump', reps: 80, weight: 0, order: 4),
  ];

  @override
  void initState() {
    super.initState();
    _date = widget.initial?.plannedDate ?? widget.defaultDate;
    _titleCtrl.text = widget.initial?.title ?? '';
    _notesCtrl.text = widget.initial?.notes ?? '';
    _modality = widget.initial?.modality ?? WorkoutModality.bodybuilding;
    _status = widget.initial?.status ?? WorkoutStatus.pending;

    // musculação
    _muscle = widget.initial?.muscleGroup ?? 'Peito';
    _durationCtrl.text =
        (widget.initial?.plannedDuration?.inMinutes ?? 45).toString();
    _sets = widget.initial?.sets ?? [const WorkoutSet(reps: 10, weight: 0)];

    // crossfit (se vier)
    _wodType = widget.initial?.wodType ?? 'for_time';
    if ((widget.initial?.timeCapMinutes ?? 0) > 0) {
      _timeCapCtrl.text = widget.initial!.timeCapMinutes!.toString();
    }
    if ((widget.initial?.rounds ?? 0) > 0) {
      _roundsCtrl.text = widget.initial!.rounds!.toString();
    }

    // blocks: se o treino existente for crossfit/hyrox, usa seus sets como blocks
    if (widget.initial?.modality == WorkoutModality.crossfit) {
      _blocksCF =
          widget.initial!.sets.isNotEmpty ? widget.initial!.sets : _blocksCF;
    }
    if (widget.initial?.modality == WorkoutModality.hyrox) {
      _blocksHyrox =
          widget.initial!.sets.isNotEmpty ? widget.initial!.sets : _blocksHyrox;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _durationCtrl.dispose();
    _timeCapCtrl.dispose();
    _roundsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecionar data do treino',
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addSet() {
    setState(() => _sets.add(const WorkoutSet(reps: 10, weight: 0)));
  }

  void _removeSet(int i) => setState(() => _sets.removeAt(i));

  void _addBlockCF() {
    setState(() => _blocksCF.add(WorkoutSet(
          label: 'Novo bloco',
          reps: 10,
          weight: 0,
          order: _blocksCF.length + 1,
        )));
  }

  void _removeBlockCF(int i) => setState(() => _blocksCF.removeAt(i));

  void _addBlockHyrox() {
    setState(() => _blocksHyrox.add(WorkoutSet(
          label: 'Nova estação',
          reps: 10,
          weight: 0,
          order: _blocksHyrox.length + 1,
        )));
  }

  void _removeBlockHyrox(int i) => setState(() => _blocksHyrox.removeAt(i));

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um título para o treino.')),
      );
      return;
    }

    final minutes = int.tryParse(_durationCtrl.text) ?? 45;

    // dados comuns
    final id = widget.initial?.id ?? UniqueKey().toString();
    final title = _titleCtrl.text.trim();
    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    // por modalidade
    if (_modality == WorkoutModality.bodybuilding) {
      final w = Workout(
        id: id,
        title: title,
        modality: WorkoutModality.bodybuilding,
        muscleGroup: _muscle,
        plannedDate: _date,
        plannedDuration: Duration(minutes: minutes),
        sets: _sets,
        status: _status,
        notes: notes,
      );
      Navigator.of(context).pop(w);
      return;
    }

    if (_modality == WorkoutModality.crossfit) {
      final timeCap = int.tryParse(_timeCapCtrl.text);
      final rounds = int.tryParse(_roundsCtrl.text);
      final w = Workout(
        id: id,
        title: title,
        modality: WorkoutModality.crossfit,
        muscleGroup: 'Geral',
        plannedDate: _date,
        plannedDuration: Duration(minutes: minutes),
        sets: _blocksCF,
        status: _status,
        notes: notes,
        wodType: _wodType,
        timeCapMinutes: (timeCap != null && timeCap > 0) ? timeCap : null,
        rounds: (rounds != null && rounds > 0) ? rounds : null,
      );
      Navigator.of(context).pop(w);
      return;
    }

    // Hyrox
    final w = Workout(
      id: id,
      title: title,
      modality: WorkoutModality.hyrox,
      muscleGroup: 'Geral',
      plannedDate: _date,
      plannedDuration: Duration(minutes: minutes),
      sets: _blocksHyrox,
      status: _status,
      notes: notes,
    );
    Navigator.of(context).pop(w);
  }

  Widget _modalityChips() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Musculação'),
          selected: _modality == WorkoutModality.bodybuilding,
          onSelected: (_) =>
              setState(() => _modality = WorkoutModality.bodybuilding),
        ),
        ChoiceChip(
          label: const Text('CrossFit'),
          selected: _modality == WorkoutModality.crossfit,
          onSelected: (_) =>
              setState(() => _modality = WorkoutModality.crossfit),
        ),
        ChoiceChip(
          label: const Text('Hyrox'),
          selected: _modality == WorkoutModality.hyrox,
          onSelected: (_) => setState(() => _modality = WorkoutModality.hyrox),
        ),
      ],
    );
  }

  Widget _bodybuildingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _muscle,
          items: const [
            DropdownMenuItem(value: 'Peito', child: Text('Peito')),
            DropdownMenuItem(value: 'Costas', child: Text('Costas')),
            DropdownMenuItem(value: 'Pernas', child: Text('Pernas')),
            DropdownMenuItem(value: 'Ombros', child: Text('Ombros')),
            DropdownMenuItem(value: 'Braços', child: Text('Braços')),
            DropdownMenuItem(value: 'Core', child: Text('Core')),
          ],
          onChanged: (v) => setState(() => _muscle = v ?? 'Peito'),
          decoration: const InputDecoration(labelText: 'Grupo muscular'),
        ),
        const SizedBox(height: 12),
        const Text('Séries', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._sets.asMap().entries.map((e) {
          final i = e.key;
          final set = e.value;
          final repsCtrl = TextEditingController(text: '${set.reps}');
          final weightCtrl =
              TextEditingController(text: set.weight.toStringAsFixed(1));
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    onChanged: (v) {
                      final r = int.tryParse(v) ?? set.reps;
                      _sets[i] = set.copyWith(reps: r);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    onChanged: (v) {
                      final w =
                          double.tryParse(v.replaceAll(',', '.')) ?? set.weight;
                      _sets[i] = set.copyWith(weight: w);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => _removeSet(i),
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addSet,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar série'),
          ),
        ),
      ],
    );
  }

  Widget _crossfitForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _wodType,
          items: const [
            DropdownMenuItem(value: 'for_time', child: Text('For Time')),
            DropdownMenuItem(value: 'amrap', child: Text('AMRAP')),
            DropdownMenuItem(value: 'emom', child: Text('EMOM')),
          ],
          onChanged: (v) => setState(() => _wodType = v ?? 'for_time'),
          decoration: const InputDecoration(labelText: 'Tipo de WOD'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _timeCapCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Time cap (min)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _roundsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rounds'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Blocos do WOD',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._blocksCF.asMap().entries.map((e) {
          final i = e.key;
          final b = e.value;
          final labelCtrl = TextEditingController(text: b.label ?? 'Bloco');
          final repsCtrl = TextEditingController(text: '${b.reps}');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    onChanged: (v) => _blocksCF[i] = b.copyWith(label: v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    onChanged: (v) {
                      final r = int.tryParse(v) ?? b.reps;
                      _blocksCF[i] = b.copyWith(reps: r);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => _removeBlockCF(i),
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addBlockCF,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar bloco'),
          ),
        ),
      ],
    );
  }

  Widget _hyroxForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estações Hyrox',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._blocksHyrox.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final labelCtrl = TextEditingController(text: s.label ?? 'Estação');
          final repsCtrl = TextEditingController(text: '${s.reps}');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Estação'),
                    onChanged: (v) => _blocksHyrox[i] = s.copyWith(label: v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    onChanged: (v) {
                      final r = int.tryParse(v) ?? s.reps;
                      _blocksHyrox[i] = s.copyWith(reps: r);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => _removeBlockHyrox(i),
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addBlockHyrox,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar estação'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd/MM/yyyy');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initial == null ? 'Novo treino' : 'Editar treino',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Modalidade
              _modalityChips(),
              const SizedBox(height: 12),

              // Título + Duração + Data + Status
              TextField(
                controller: _titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Título do treino'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Duração (min)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Data'),
                        child: Text(df.format(_date)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Pendente'),
                    selected: _status == WorkoutStatus.pending,
                    onSelected: (_) =>
                        setState(() => _status = WorkoutStatus.pending),
                  ),
                  ChoiceChip(
                    label: const Text('Concluído'),
                    selected: _status == WorkoutStatus.completed,
                    onSelected: (_) =>
                        setState(() => _status = WorkoutStatus.completed),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Form específico por modalidade
              if (_modality == WorkoutModality.bodybuilding)
                _bodybuildingForm(),
              if (_modality == WorkoutModality.crossfit) _crossfitForm(),
              if (_modality == WorkoutModality.hyrox) _hyroxForm(),

              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Observações (opcional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar treino'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
