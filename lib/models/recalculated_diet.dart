import 'package:dieta_mais_app/models/meal.dart';

import 'diet_plan.dart'; // Reutilizaremos o modelo Meal

class RecalculatedDiet {
  final String analysis;
  final List<Meal> remainingMeals;

  RecalculatedDiet({required this.analysis, required this.remainingMeals});

  factory RecalculatedDiet.fromJson(Map<String, dynamic> json) {
    var mealList = json['remaining_meals'] as List? ?? [];
    List<Meal> meals = mealList.map((i) => Meal.fromJson(i)).toList();

    return RecalculatedDiet(
      analysis: json['analysis'] ?? 'Não foi possível gerar uma análise.',
      remainingMeals: meals,
    );
  }
}
