// lib/models/preset_meal.dart
import 'food_estimate.dart';

class PresetMeal {
  final String id;           // ex.: timestamp string
  final String name;         // nome dado pelo usuário
  final FoodEstimate estimate;
  final DateTime createdAt;

  PresetMeal({
    required this.id,
    required this.name,
    required this.estimate,
    required this.createdAt,
  });

  factory PresetMeal.fromJson(Map<String, dynamic> json) {
    return PresetMeal(
      id: json['id'] as String,
      name: json['name'] as String,
      estimate: FoodEstimate.fromJson(json['estimate'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'estimate': estimate.toJson(),
        'created_at': createdAt.toIso8601String(),
      };
}
