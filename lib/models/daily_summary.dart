import 'macro_data.dart';

class DailySummary {
  final MacroData targets;
  final MacroData consumed;
  final MacroData remaining;

  DailySummary({
    required this.targets,
    required this.consumed,
    required this.remaining,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      targets: MacroData.fromJson(json['targets']),
      consumed: MacroData.fromJson(json['consumed']),
      remaining: MacroData.fromJson(json['remaining']),
    );
  }
}
