import 'macro_data.dart';

class DailySummary {
  final int dietId;
  final MacroData targets;
  final MacroData consumed;
  final MacroData remaining;

  DailySummary({
    required this.dietId,
    required this.targets,
    required this.consumed,
    required this.remaining,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      dietId: json['diet_id'],
      targets: MacroData.fromJson(json['targets']),
      consumed: MacroData.fromJson(json['consumed']),
      remaining: MacroData.fromJson(json['remaining']),
    );
  }
}
