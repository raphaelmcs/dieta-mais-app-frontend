import 'meal.dart';

class DietPlan {
  final int id;
  final String name; // Nome do plano
  final bool isActive;
  final int targetCalories;
  final DateTime createdAt;
  final List<Meal>? meals; // Lista de refeições

  DietPlan({
    required this.id,
    required this.name,
    required this.isActive,
    required this.targetCalories,
    required this.createdAt,
    this.meals,
  });

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    return DietPlan(
      id: json['id'],
      name: json['name'] ?? 'Plano Importado', // Nome padrão
      isActive: json['is_active'] ?? false,
      targetCalories: json['target_calories'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      meals: json.containsKey('meals') && json['meals'] != null
          ? (json['meals'] as List).map((i) => Meal.fromJson(i)).toList()
          : null,
    );
  }
}
