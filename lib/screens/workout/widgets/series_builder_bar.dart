// lib/screens/workout/widgets/series_builder_bar.dart
import 'package:flutter/material.dart';
import '../../../models/workout_item.dart';

class SeriesBuilderBar extends StatelessWidget {
  final List<WorkoutItem> items;
  final VoidCallback onSave;
  final VoidCallback onClear;
  final void Function(int index) onRemoveAt;
  final void Function(int index) onEditAt;

  const SeriesBuilderBar({
    super.key,
    required this.items,
    required this.onSave,
    required this.onClear,
    required this.onRemoveAt,
    required this.onEditAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.85),
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final it = items[i];
                return GestureDetector(
                  onTap: () => onEditAt(i),
                  onLongPress: () => onRemoveAt(i),
                  child: Chip(
                    label: Text(
                      it.displayLabel(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: items.isEmpty ? null : onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar série do dia'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
