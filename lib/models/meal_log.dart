class MealLog {
  final int id;
  final String foodName;
  final String quantity;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  MealLog({
    required this.id,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  // Factory constructor para criar um MealLog a partir de um JSON
  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'],
      foodName: json['food_name'] ?? 'N/A',
      quantity: json['quantity'] ?? '0g',
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num).toInt(),
      carbs: (json['carbs'] as num).toInt(),
      fats: (json['fats'] as num).toInt(),
    );
  }
}
