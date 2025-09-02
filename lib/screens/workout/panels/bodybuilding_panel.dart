import 'package:flutter/material.dart';
import '../../../models/workout_exercise_dto.dart';
import '../widgets/exercise_list.dart';

class BodybuildingPanel extends StatelessWidget {
  final List<WorkoutExerciseDto> exercises;
  final VoidCallback onCreateWorkout;
  final void Function(WorkoutExerciseDto ex) onPickExercise;

  const BodybuildingPanel({
    super.key,
    required this.exercises,
    required this.onCreateWorkout,
    required this.onPickExercise,
  });

  @override
  Widget build(BuildContext context) {
    return ExerciseList(
      title: 'Exercícios de Musculação',
      exercises: exercises,
      onTap: onPickExercise,
      buttonLabel: 'Novo treino de musculação',
      onButtonPressed: onCreateWorkout,
    );
  }
}
