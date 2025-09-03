// lib/models/food_estimate.dart

class FoodItemEstimate {
  final String label;
  final double confidence; // 0..1
  final int portionGrams;  // g
  final int calories;      // kcal
  final double? proteinG;  // g
  final double? carbsG;    // g
  final double? fatsG;     // g

  // densidades calculadas no client (não vêm do backend)
  final double kcalPerGram;
  final double? proteinPerGram;
  final double? carbsPerGram;
  final double? fatsPerGram;

  FoodItemEstimate({
    required this.label,
    required this.confidence,
    required this.portionGrams,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatsG,
    required this.kcalPerGram,
    this.proteinPerGram,
    this.carbsPerGram,
    this.fatsPerGram,
  });

  /// Helpers de parse defensivo
  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? fallback;
    return fallback;
  }

  factory FoodItemEstimate.fromJson(Map<String, dynamic> json) {
    final int portion = _asInt(json['portion_grams'], fallback: 0);
    final int kcal = _asInt(json['calories'], fallback: 0);
    final double d = portion > 0 ? portion.toDouble() : 1.0;

    final double? p = json.containsKey('protein_g')
        ? _asDouble(json['protein_g'])
        : null;
    final double? c = json.containsKey('carbs_g')
        ? _asDouble(json['carbs_g'])
        : null;
    final double? f = json.containsKey('fats_g')
        ? _asDouble(json['fats_g'])
        : null;

    return FoodItemEstimate(
      label: (json['label'] ?? 'Item').toString(),
      confidence: _asDouble(json['confidence'], fallback: 0.0).clamp(0.0, 1.0),
      portionGrams: portion,
      calories: kcal,
      proteinG: p,
      carbsG: c,
      fatsG: f,
      kcalPerGram: kcal / d,
      proteinPerGram: p != null ? (p / d) : null,
      carbsPerGram: c != null ? (c / d) : null,
      fatsPerGram: f != null ? (f / d) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'portion_grams': portionGrams,
        'calories': calories,
        if (proteinG != null) 'protein_g': proteinG,
        if (carbsG != null) 'carbs_g': carbsG,
        if (fatsG != null) 'fats_g': fatsG,
      };

  FoodItemEstimate copyWith({
    int? portionGrams,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatsG,
  }) {
    final newPortion = portionGrams ?? this.portionGrams;
    final double d = newPortion > 0 ? newPortion.toDouble() : 1.0;

    final int newCalories = calories ?? this.calories;
    final double? newProteinG = proteinG ?? this.proteinG;
    final double? newCarbsG = carbsG ?? this.carbsG;
    final double? newFatsG = fatsG ?? this.fatsG;

    return FoodItemEstimate(
      label: label,
      confidence: confidence,
      portionGrams: newPortion,
      calories: newCalories,
      proteinG: newProteinG,
      carbsG: newCarbsG,
      fatsG: newFatsG,
      kcalPerGram: newCalories / d,
      proteinPerGram: newProteinG != null ? newProteinG / d : null,
      carbsPerGram: newCarbsG != null ? newCarbsG / d : null,
      fatsPerGram: newFatsG != null ? newFatsG / d : null,
    );
  }
}

class FoodEstimate {
  final String? imageUrl;
  final List<FoodItemEstimate> items;
  final int totalCalories;

  FoodEstimate({
    this.imageUrl,
    required this.items,
    required this.totalCalories,
  });

  /// Aceita tanto `{ "data": {...} }` quanto `{ ... }`
  factory FoodEstimate.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> root =
        (json['data'] is Map<String, dynamic>) ? (json['data'] as Map<String, dynamic>) : json;

    final List<dynamic> rawItems = (root['items'] as List<dynamic>?) ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => FoodItemEstimate.fromJson(e))
        .toList();

    final int total = FoodItemEstimate._asInt(root['total_calories'], fallback: 0);

    return FoodEstimate(
      imageUrl: root['image_url'] as String?,
      items: items,
      totalCalories: total,
    );
  }

  Map<String, dynamic> toJson({DateTime? takenAt}) => {
        'image_url': imageUrl,
        'items': items.map((e) => e.toJson()).toList(),
        'total_calories': totalCalories,
        if (takenAt != null) 'taken_at': takenAt.toIso8601String(),
      };

  Map<String, dynamic> toMealLogPayload({DateTime? consumedAt, int? dietId}) => {
        if (dietId != null) 'diet_id': dietId,
        if (consumedAt != null) 'consumed_at': consumedAt.toIso8601String(),
        'items': items
            .map((e) => {
                  'label': e.label,
                  'portion_grams': e.portionGrams,
                  'calories': e.calories,
                  if (e.proteinG != null) 'protein_g': e.proteinG,
                  if (e.carbsG != null) 'carbs_g': e.carbsG,
                  if (e.fatsG != null) 'fats_g': e.fatsG,
                })
            .toList(),
      };

  FoodEstimate copyWith({
    List<FoodItemEstimate>? items,
    int? totalCalories,
    String? imageUrl,
  }) {
    return FoodEstimate(
      imageUrl: imageUrl ?? this.imageUrl,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
    );
  }
}
