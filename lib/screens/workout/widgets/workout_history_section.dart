// lib/screens/workout/widgets/workout_history_section.dart
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../widgets/glassmorphic_container.dart';

class WorkoutHistorySection extends StatelessWidget {
  final List<Workout> history;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const WorkoutHistorySection({
    super.key,
    required this.history,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggleExpanded,
            child: Row(
              children: [
                const Text('Histórico recente',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (expanded)
            ...history.take(8).map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GlassmorphicContainer(
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent.shade200,
                      ),
                      title: Text(w.title),
                      subtitle: Text(
                          '${w.muscleGroup} • ${w.plannedDate.day.toString().padLeft(2, '0')}/${w.plannedDate.month.toString().padLeft(2, '0')}'),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
