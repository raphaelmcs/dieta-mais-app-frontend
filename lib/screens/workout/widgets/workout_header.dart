// lib/screens/workout/widgets/workout_header.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkoutHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final double weeklyProgress; // 0..1
  const WorkoutHeader({
    super.key,
    required this.selectedDate,
    required this.onPickDate,
    required this.weeklyProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dd = DateFormat('dd/MM').format(selectedDate);
    final ww = NumberFormat.percentPattern('pt_BR').format(weeklyProgress);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20),
                const SizedBox(width: 8),
                Text(dd, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Semana: $ww',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: weeklyProgress.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
