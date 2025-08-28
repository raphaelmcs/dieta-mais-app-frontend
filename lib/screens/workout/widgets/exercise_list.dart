// lib/screens/workout/widgets/exercise_list.dart
import 'package:flutter/material.dart';

class ExerciseList extends StatelessWidget {
  final List<Map<String, dynamic>> exercises; // id, name, kind, defaults...
  final void Function(Map<String, dynamic> exercise)? onTap;

  const ExerciseList({super.key, required this.exercises, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Center(child: Text('Nenhum exercício cadastrado.'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const Divider(height: 8),
      itemBuilder: (_, i) {
        final e = exercises[i];
        final kind = e['kind'] ?? '';
        final rep = e['default_reps'];
        final w = e['default_weight'];

        final subtitle = [
          if (kind.toString().isNotEmpty) 'Tipo: $kind',
          if (rep != null) 'Reps: $rep',
          if (w != null) 'Peso: ${w.toString()}kg',
        ].join(' • ');

        return ListTile(
          title: Text(e['name']),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap == null ? null : () => onTap!(e),
        );
      },
    );
  }
}
