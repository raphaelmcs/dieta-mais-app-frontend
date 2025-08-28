// lib/screens/workout/widgets/modality_picker.dart
import 'package:flutter/material.dart';

class ModalityPicker extends StatelessWidget {
  final String? selectedSlug; // bodybuilding|crossfit|hyrox
  final ValueChanged<String> onSelected;

  const ModalityPicker({
    super.key,
    required this.selectedSlug,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      {
        'slug': 'bodybuilding',
        'label': 'Musculação',
        'icon': Icons.fitness_center
      },
      {'slug': 'crossfit', 'label': 'CrossFit', 'icon': Icons.flash_on},
      {'slug': 'hyrox', 'label': 'Hyrox', 'icon': Icons.directions_run},
    ];

    return Wrap(
      spacing: 12,
      children: items.map((m) {
        final sel = m['slug'] == selectedSlug;
        return ChoiceChip(
          label: Text(m['label'] as String),
          selected: sel,
          avatar: Icon(m['icon'] as IconData, size: 18),
          onSelected: (_) => onSelected(m['slug'] as String),
        );
      }).toList(),
    );
  }
}
