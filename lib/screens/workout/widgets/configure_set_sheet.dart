// lib/screens/workout/widgets/configure_set_sheet.dart
import 'package:flutter/material.dart';
import '../../../models/workout_exercise_dto.dart';
import '../../../models/workout_item.dart';

class ConfigureSetSheet extends StatefulWidget {
  final WorkoutExerciseDto exercise;
  final int order;
  final WorkoutItem? initial;

  const ConfigureSetSheet({
    super.key,
    required this.exercise,
    required this.order,
    this.initial,
  });

  @override
  State<ConfigureSetSheet> createState() => _ConfigureSetSheetState();
}

class _ConfigureSetSheetState extends State<ConfigureSetSheet> {
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final initReps = widget.initial?.reps ?? widget.exercise.defaultReps ?? 10;
    final initWeight =
        widget.initial?.weight ?? widget.exercise.defaultWeight ?? 0.0;

    _repsCtrl = TextEditingController(text: '$initReps');
    _weightCtrl = TextEditingController(text: initWeight.toStringAsFixed(1));
    _notesCtrl = TextEditingController(text: widget.initial?.notes ?? '');
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final reps = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final weight =
        double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

    final item = WorkoutItem(
      exercise: widget.exercise,
      reps: reps,
      weight: weight,
      order: widget.order,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      status: WorkoutItemStatus.pending,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exercise.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
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
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Adicionar à série'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
