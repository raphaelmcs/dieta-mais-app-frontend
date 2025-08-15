class DailyCalorieLog {
  final int day;
  final int totalCalories;

  DailyCalorieLog({required this.day, required this.totalCalories});

  factory DailyCalorieLog.fromJson(Map<String, dynamic> json) {
    return DailyCalorieLog(
      day: (json['day'] as num).toInt(),
      totalCalories: (json['total_calories'] as num).toInt(),
    );
  }
}
