// lib/models/diet_plan.dart
import 'meal.dart';
import 'dart:convert';

class DietPlan {
  final int id;
  final String name;
  final bool isActive;
  final int targetCalories;
  final DateTime createdAt;
  final List<Meal>? meals;

  DietPlan({
    required this.id,
    required this.name,
    required this.isActive,
    required this.targetCalories,
    required this.createdAt,
    this.meals,
  });

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    List<Meal>? meals;

    final rawMeals = json['meals'];

    if (rawMeals is List) {
      meals = rawMeals
          .map((i) => Meal.fromJson(i as Map<String, dynamic>))
          .toList();
    } else if (rawMeals is String && rawMeals.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMeals);
        if (decoded is List) {
          meals = decoded
              .map((i) => Meal.fromJson(i as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // ignora se não for um JSON válido
      }
    } else {
      meals = null;
    }

    return DietPlan(
      id: json['id'],
      name: json['name'] ?? 'Plano',
      isActive: json['is_active'] ?? false,
      targetCalories: json['target_calories'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      meals: meals,
    );
  }
}
