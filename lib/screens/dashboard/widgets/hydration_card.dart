import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../models/daily_summary.dart';
//import '../../../theme/app_theme.dart';
import '../../../widgets/glassmorphic_container.dart';

class HydrationCard extends StatelessWidget {
  final HydrationData hydration;
  final VoidCallback onAddWater;
  final VoidCallback onUpdateGoal;
  final LinearGradient gradient;

  const HydrationCard({
    super.key,
    required this.hydration,
    required this.onAddWater,
    required this.onUpdateGoal,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double percent =
        (hydration.goal > 0) ? (hydration.consumed / hydration.goal) : 0.0;
    int surplus = hydration.consumed - hydration.goal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hidratação',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: onUpdateGoal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${hydration.consumed} / ${hydration.goal} ml',
                          style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodySmall?.color),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit_outlined,
                            size: 18, color: theme.textTheme.bodySmall?.color),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearPercentIndicator(
                lineHeight: 12.0,
                percent: percent.clamp(0.0, 1.0),
                barRadius: const Radius.circular(6),
                backgroundColor: Colors.white.withOpacity(0.1),
                linearGradient: gradient,
              ),
              if (percent > 1.0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Você ultrapassou a meta em $surplus ml!',
                    style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onAddWater,
                icon: const Icon(Icons.add),
                label: const Text("Adicionar Água"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: Colors.lightBlueAccent.withOpacity(0.3),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
