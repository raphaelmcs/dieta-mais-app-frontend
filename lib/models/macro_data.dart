// lib/models/macro_data.dart

class AverageData {
  final int calories; // kcal
  final int protein; // g
  final int carbs; // g
  final int fats; // g
  final int hydrationMl; // ml

  AverageData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.hydrationMl,
  });

  // Conversor robusto p/ int
  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory AverageData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AverageData(
          calories: 0, protein: 0, carbs: 0, fats: 0, hydrationMl: 0);
    }

    // Aceita variações comuns vindas do backend
    final calories = _asInt(json['calories'] ?? json['kcal']);
    final protein = _asInt(json['protein'] ?? json['proteins']);
    final carbs =
        _asInt(json['carbs'] ?? json['carbohydrates'] ?? json['carb']);
    final fats = _asInt(json['fats'] ?? json['fats']);
    final hydrationMl = _asInt(json['hydration_ml'] ??
        json['hydrationMl'] ??
        json['water_ml'] ??
        json['water']);

    return AverageData(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      hydrationMl: hydrationMl,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'hydration_ml': hydrationMl,
      };
}
