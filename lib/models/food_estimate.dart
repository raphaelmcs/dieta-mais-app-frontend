class FoodItemEstimate {
  final String label;
  final double confidence; // 0..1
  final int portionGrams; // g
  final int calories; // kcal
  final double? proteinG; // g
  final double? carbsG; // g
  final double? fatsG; // g

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

  factory FoodItemEstimate.fromJson(Map<String, dynamic> json) {
    final portion = (json['portion_grams'] ?? 0) as int;
    final kcal = (json['calories'] ?? 0) as int;

    // evitar divisão por zero
    final double d = portion > 0 ? portion.toDouble() : 1.0;

    final double? p = (json['protein_g'] != null)
        ? (json['protein_g'] as num).toDouble()
        : null;
    final double? c =
        (json['carbs_g'] != null) ? (json['carbs_g'] as num).toDouble() : null;
    final double? f =
        (json['fats_g'] != null) ? (json['fats_g'] as num).toDouble() : null;

    return FoodItemEstimate(
      label: json['label'] ?? 'Item',
      confidence: (json['confidence'] ?? 0).toDouble(),
      portionGrams: portion,
      calories: kcal,
      proteinG: p,
      carbsG: c,
      fatsG: f,
      kcalPerGram: kcal / d,
      proteinPerGram: p != null ? p / d : null,
      carbsPerGram: c != null ? c / d : null,
      fatsPerGram: f != null ? f / d : null,
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

    // recalcula densidades se alterarmos porção/calorias/macros
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

  FoodEstimate(
      {this.imageUrl, required this.items, required this.totalCalories});

  factory FoodEstimate.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => FoodItemEstimate.fromJson(e as Map<String, dynamic>))
        .toList();

    return FoodEstimate(
      imageUrl: data['image_url'] as String?,
      items: items,
      totalCalories: data['total_calories'] ?? 0,
    );
  }

  Map<String, dynamic> toJson({DateTime? takenAt}) => {
        'image_url': imageUrl,
        'items': items.map((e) => e.toJson()).toList(),
        'total_calories': totalCalories,
        if (takenAt != null) 'taken_at': takenAt.toIso8601String(),
      };

  Map<String, dynamic> toMealLogPayload({DateTime? consumedAt, int? dietId}) =>
      {
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

  FoodEstimate copyWith({List<FoodItemEstimate>? items, int? totalCalories}) {
    return FoodEstimate(
      imageUrl: imageUrl,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
    );
  }
}
