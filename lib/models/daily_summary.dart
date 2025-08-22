import 'macro_data.dart';

class HydrationData {
  final int goal;
  final int consumed;
  final int remaining;
  HydrationData(
      {required this.goal, required this.consumed, required this.remaining});

  factory HydrationData.fromJson(Map<String, dynamic> json) {
    return HydrationData(
      goal: (json['goal'] as num).toInt(),
      consumed: (json['consumed'] as num).toInt(),
      remaining: (json['remaining'] as num).toInt(),
    );
  }
}

class DailySummary {
  final bool hasActiveDiet; // <-- NOVO
  final int? dietId; // <-- AGORA É NULÁVEL
  final AverageData targets;
  final AverageData consumed;
  final AverageData remaining;
  final HydrationData hydration;

  DailySummary({
    required this.hasActiveDiet, // <-- NOVO
    this.dietId, // <-- AGORA É NULÁVEL
    required this.targets,
    required this.consumed,
    required this.remaining,
    required this.hydration,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      hasActiveDiet: json['has_active_diet'] ?? false, // <-- NOVO
      dietId: json['diet_id'], // <-- AGORA É NULÁVEL
      targets: AverageData.fromJson(json['targets']),
      consumed: AverageData.fromJson(json['consumed']),
      remaining: AverageData.fromJson(json['remaining']),
      hydration: HydrationData.fromJson(json['hydration']),
    );
  }
}
