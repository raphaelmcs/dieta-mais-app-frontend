import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/meal_log.dart';
import '../../../screens/suggestion_screen.dart';
import '../../../widgets/glassmorphic_container.dart';

class MealListView extends StatelessWidget {
  final List<MealLog> meals;
  final Function(int) onDelete;

  const MealListView({
    super.key,
    required this.meals,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Dismissible(
          key: Key(meal.id.toString()),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => onDelete(meal.id),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_forever, color: Colors.white),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: GlassmorphicContainer(
              borderRadius: 12,
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                title: Text(meal.foodName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(meal.quantity),
                trailing: Text('${meal.calories} kcal',
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          SuggestionScreen(foodName: meal.foodName),
                    ),
                  );
                },
              ),
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5, end: 0);
      },
    );
  }
}
