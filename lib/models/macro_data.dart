// lib/models/macro_data.dart

// Renomeado para AverageData para melhor semântica
class AverageData {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int hydrationMl; // <-- NOVO CAMPO

  AverageData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.hydrationMl, // <-- NOVO CAMPO
  });

  factory AverageData.fromJson(Map<String, dynamic> json) {
    return AverageData(
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num).toInt(),
      carbs: (json['carbs'] as num).toInt(),
      fats: (json['fats'] as num).toInt(),
      hydrationMl:
          (json['hydration_ml'] as num? ?? 0).toInt(), // <-- NOVO CAMPO
    );
  }
}
