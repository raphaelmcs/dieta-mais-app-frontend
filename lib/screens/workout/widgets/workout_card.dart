// lib/screens/workout/widgets/workout_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/workout.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glassmorphic_container.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  String _modalityLabel(WorkoutModality m) {
    switch (m) {
      case WorkoutModality.bodybuilding:
        return 'Musculação';
      case WorkoutModality.crossfit:
        return 'CrossFit';
      case WorkoutModality.hyrox:
        return 'Hyrox';
    }
  }

  IconData _modalityIcon(WorkoutModality m) {
    switch (m) {
      case WorkoutModality.bodybuilding:
        return Icons.fitness_center;
      case WorkoutModality.crossfit:
        return Icons.flash_on;
      case WorkoutModality.hyrox:
        return Icons.directions_run;
    }
  }

  Color _statusColor(BuildContext context) {
    return workout.isCompleted
        ? Colors.greenAccent.withOpacity(.9)
        : Theme.of(context).primaryColor.withOpacity(.9);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd/MM');

    return GlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone da modalidade
            Container(
              decoration: BoxDecoration(
                color: AppThemes.glassColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                _modalityIcon(workout.modality),
                size: 24,
                color: theme.primaryColor,
              ),
            ),

            const SizedBox(width: 12),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + status chip
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workout.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(context).withOpacity(.15),
                          border: Border.all(
                              color: _statusColor(context), width: 1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          workout.isCompleted ? 'Concluído' : 'Pendente',
                          style: TextStyle(
                            color: _statusColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Linha de infos
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _InfoPill(
                        icon: Icons.event,
                        label: df.format(workout.plannedDate),
                      ),
                      _InfoPill(
                        icon: Icons.timer_outlined,
                        label:
                            '${(workout.plannedDuration?.inMinutes ?? 0)} min',
                      ),
                      _InfoPill(
                        icon: Icons.category_outlined,
                        label: _modalityLabel(workout.modality),
                      ),
                      if (workout.modality == WorkoutModality.bodybuilding &&
                          (workout.muscleGroup?.isNotEmpty ?? false))
                        _InfoPill(
                          icon: Icons.fiber_manual_record,
                          label: workout.muscleGroup!,
                        ),
                      if (workout.modality == WorkoutModality.crossfit &&
                          (workout.wodType?.isNotEmpty ?? false))
                        _InfoPill(
                          icon: Icons.fitness_center_outlined,
                          label: workout.wodType!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Sets / blocos (resumo curto)
                  if (workout.sets.isNotEmpty)
                    Text(
                      _buildSetsPreview(),
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),

                  if ((workout.notes?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 6),
                    Text(
                      workout.notes!,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Ações
            Column(
              children: [
                IconButton(
                  tooltip: workout.isCompleted
                      ? 'Marcar como pendente'
                      : 'Marcar como concluído',
                  icon: Icon(
                    workout.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: workout.isCompleted
                        ? Colors.greenAccent
                        : theme.primaryColor,
                  ),
                  onPressed: onToggleComplete,
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Excluir',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _buildSetsPreview() {
    // Mostra um resumo compacto dos sets/blocos
    // Ex.: “3x (10 reps • 20kg)” ou lista de labels no CrossFit/Hyrox
    final hasLabels = workout.sets.any((s) => (s.label?.isNotEmpty ?? false));

    if (hasLabels) {
      // CrossFit/Hyrox: exibir por label
      return workout.sets
          .map((s) {
            final pieces = <String>[];
            if ((s.label?.isNotEmpty ?? false)) pieces.add(s.label!);
            if (s.reps > 0) pieces.add('${s.reps} reps');
            if (s.weight > 0) pieces.add('${s.weight.toStringAsFixed(1)}kg');
            return pieces.join(' • ');
          })
          .take(3)
          .join('  ·  ');
    }

    // Musculação: agrupar por “reps x weight”
    final parts = workout.sets.map((s) {
      final w = s.weight > 0 ? ' • ${s.weight.toStringAsFixed(1)}kg' : '';
      return '${s.reps} reps$w';
    }).toList();

    return parts.take(3).join('  ·  ');
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppThemes.glassColor.withOpacity(0.2),
        border: Border.all(
          color: AppThemes.glassColor.withOpacity(0.25),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
