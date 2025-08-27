// lib/models/daily_summary.dart
import 'macro_data.dart';

class HydrationData {
  final int goal;
  final int consumed;
  final int remaining;

  HydrationData({
    required this.goal,
    required this.consumed,
    required this.remaining,
  });

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory HydrationData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return HydrationData(goal: 0, consumed: 0, remaining: 0);
    }
    // aceita aliases comuns: water_ml, hydration, etc.
    final goal      = _asInt(json['goal'] ?? json['target'] ?? json['goal_ml']);
    final consumed  = _asInt(json['consumed'] ?? json['intake'] ?? json['water_ml']);
    final remaining = _asInt(json['remaining'] ?? (goal - consumed));
    return HydrationData(goal: goal, consumed: consumed, remaining: remaining);
  }
}

class DailySummary {
  final bool hasActiveDiet;    // pode vir como has_active_diet
  final int? dietId;           // pode vir diet_id
  final AverageData targets;
  final AverageData consumed;
  final AverageData remaining;
  final HydrationData hydration;

  DailySummary({
    required this.hasActiveDiet,
    required this.dietId,
    required this.targets,
    required this.consumed,
    required this.remaining,
    required this.hydration,
  });

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    // torna robusto contra nulos/ausentes
    final targets   = AverageData.fromJson(json['targets']   as Map<String, dynamic>?);
    final consumed  = AverageData.fromJson(json['consumed']  as Map<String, dynamic>?);
    final remaining = AverageData.fromJson(json['remaining'] as Map<String, dynamic>?);

    return DailySummary(
      hasActiveDiet: _asBool(json['has_active_diet'] ?? json['hasActiveDiet']),
      dietId: (json['diet_id'] ?? json['dietId']) as int?, // null se não vier
      targets: targets,
      consumed: consumed,
      remaining: remaining,
      hydration: HydrationData.fromJson(json['hydration'] as Map<String, dynamic>?),
    );
  }
}
