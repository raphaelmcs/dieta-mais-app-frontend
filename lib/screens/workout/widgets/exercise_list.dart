import 'package:flutter/material.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../models/workout_exercise_dto.dart';

class ExerciseList extends StatelessWidget {
  final String title;
  final List<WorkoutExerciseDto> exercises;
  final void Function(WorkoutExerciseDto ex) onTap;

  /// Botão opcional de ação (ex.: “Novo WOD”)
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const ExerciseList({
    super.key,
    required this.title,
    required this.exercises,
    required this.onTap,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        GlassmorphicContainer(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final ex = exercises[i];
              final subtitle = _buildSubtitle(ex);
              return ListTile(
                title: Text(ex.name),
                subtitle: subtitle == null ? null : Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTap(ex),
              );
            },
          ),
        ),
        if (buttonLabel != null && onButtonPressed != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonLabel!),
            ),
          ),
        ],
      ],
    );
  }

  String? _buildSubtitle(WorkoutExerciseDto ex) {
    final parts = <String>[];
    if (ex.kind != null && ex.kind!.isNotEmpty) parts.add('Tipo: ${ex.kind}');
    if (ex.defaultReps != null) parts.add('Reps: ${ex.defaultReps}');
    if (ex.defaultWeight != null) {
      parts.add('Peso: ${ex.defaultWeight!.toStringAsFixed(1)} kg');
    }
    return parts.isEmpty ? null : parts.join(' • ');
  }
}
