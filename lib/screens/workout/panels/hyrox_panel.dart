import 'package:flutter/material.dart';
import '../../../models/workout_exercise_dto.dart';
import '../widgets/exercise_list.dart';

class HyroxPanel extends StatelessWidget {
  final List<WorkoutExerciseDto> exercises;
  final VoidCallback onCreateWorkout;
  final void Function(WorkoutExerciseDto ex) onPickExercise;

  const HyroxPanel({
    super.key,
    required this.exercises,
    required this.onCreateWorkout,
    required this.onPickExercise,
  });

  @override
  Widget build(BuildContext context) {
    return ExerciseList(
      title: 'Estações Hyrox',
      exercises: exercises,
      onTap: onPickExercise,
      buttonLabel: 'Novo treino Hyrox',
      onButtonPressed: onCreateWorkout,
    );
  }
}
