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
  final int dietId;
  final AverageData targets;
  final AverageData consumed;
  final AverageData remaining;
  final HydrationData hydration; // <-- ADICIONE

  DailySummary({
    required this.dietId,
    required this.targets,
    required this.consumed,
    required this.remaining,
    required this.hydration, // <-- ADICIONE
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      dietId: json['diet_id'],
      targets: AverageData.fromJson(json['targets']),
      consumed: AverageData.fromJson(json['consumed']),
      remaining: AverageData.fromJson(json['remaining']),
      hydration: HydrationData.fromJson(json['hydration']), // <-- ADICIONE
    );
  }
}
