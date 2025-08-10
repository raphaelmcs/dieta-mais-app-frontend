import 'food.dart';

class Meal {
  final String name;
  final String? time;
  final List<Food> foods;

  Meal({required this.name, this.time, required this.foods});

  factory Meal.fromJson(Map<String, dynamic> json) {
    var foodList = json['foods'] as List;
    List<Food> foods = foodList.map((i) => Food.fromJson(i)).toList();

    return Meal(
      name: json['name'] ?? 'Refeição sem nome',
      time: json['time'],
      foods: foods,
    );
  }
}
