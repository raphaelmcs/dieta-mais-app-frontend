// lib/screens/workout/panels/bodybuilding_panel.dart
import 'package:flutter/material.dart';
import '../widgets/exercise_list.dart';

class BodybuildingPanel extends StatelessWidget {
  final List<Map<String, dynamic>> exercises;
  final VoidCallback onCreateWorkout; // abre Add/Edit
  final void Function(Map<String, dynamic> exercise)? onPickExercise;

  const BodybuildingPanel({
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
        const Text('Exercícios de Musculação',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ExerciseList(exercises: exercises, onTap: onPickExercise),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onCreateWorkout,
          icon: const Icon(Icons.add),
          label: const Text('Novo treino de musculação'),
        ),
      ],
    );
  }
}
