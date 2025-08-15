class MonthlyAverage {
  final int month;
  final int averageCalories;
  final int averageProtein;
  final int averageCarbs;
  final int averageFats;
  final int averageHydration;

  MonthlyAverage({
    required this.month,
    required this.averageCalories,
    required this.averageProtein,
    required this.averageCarbs,
    required this.averageFats,
    required this.averageHydration,
  });

  factory MonthlyAverage.fromJson(Map<String, dynamic> json) {
    return MonthlyAverage(
      month: (json['month'] as num).toInt(),
      averageCalories: (json['average_calories'] as num).toInt(),
      averageProtein: (json['average_protein'] as num).toInt(),
      averageCarbs: (json['average_carbs'] as num).toInt(),
      averageFats: (json['average_fats'] as num).toInt(),
      averageHydration: (json['average_hydration'] as num? ?? 0).toInt(),
    );
  }
}
