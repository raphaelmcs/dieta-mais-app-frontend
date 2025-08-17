import 'recalculated_diet.dart';

class RecalculationResult {
  final int newDietId;
  final RecalculatedDiet analysis;

  RecalculationResult({required this.newDietId, required this.analysis});

  factory RecalculationResult.fromJson(Map<String, dynamic> json) {
    return RecalculationResult(
      newDietId: json['new_diet_id'],
      analysis: RecalculatedDiet.fromJson(json['ai_analysis']),
    );
  }
}
