// lib/screens/workout/panels/crossfit_panel.dart
import 'package:flutter/material.dart';
import '../widgets/exercise_list.dart';

class CrossfitPanel extends StatelessWidget {
  final List<Map<String, dynamic>> exercises;
  final VoidCallback onCreateWorkout;
  final void Function(Map<String, dynamic> exercise)? onPickExercise;

  const CrossfitPanel({
    super.key,
    required this.exercises,
    required this.onCreateWorkout,
    this.onPickExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Blocos / Movimentos CrossFit',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ExerciseList(exercises: exercises, onTap: onPickExercise),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onCreateWorkout,
          icon: const Icon(Icons.add),
          label: const Text('Novo WOD'),
        ),
      ],
    );
  }
}
