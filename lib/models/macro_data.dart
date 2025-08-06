class MacroData {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  MacroData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  // Factory constructor to create a MacroData instance from a map (JSON)
  factory MacroData.fromJson(Map<String, dynamic> json) {
    return MacroData(
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num).toInt(),
      carbs: (json['carbs'] as num).toInt(),
      fats: (json['fats'] as num).toInt(),
    );
  }
}
