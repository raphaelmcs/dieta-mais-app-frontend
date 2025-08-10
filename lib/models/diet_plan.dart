import 'meal.dart';

class DietPlan {
  final int id;
  final List<Meal> meals;

  DietPlan({required this.id, required this.meals});

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    var mealList = json['meals'] as List;
    List<Meal> meals = mealList.map((i) => Meal.fromJson(i)).toList();

    return DietPlan(
      id: json['id'],
      meals: meals,
    );
  }
}
