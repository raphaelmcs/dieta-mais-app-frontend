// lib/models/workout_set.dart

class WorkoutSet {
  final String? label; // Ex.: "WOD A", "Sled Push", "Corrida 1km"
  final int reps; // reps totais (quando fizer sentido)
  final double weight; // kg (se aplicável)
  final int order;

  const WorkoutSet({
    this.label,
    required this.reps,
    required this.weight,
    this.order = 1,
  });

  WorkoutSet copyWith({
    String? label,
    int? reps,
    double? weight,
    int? order,
  }) {
    return WorkoutSet(
      label: label ?? this.label,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      order: order ?? this.order,
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double _asDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
      return 0.0;
    }

    return WorkoutSet(
      label: json['label']?.toString(),
      reps: _asInt(json['reps']),
      weight: _asDouble(json['weight']),
      order: _asInt(json['order'] ?? 1),
    );
  }

  Map<String, dynamic> toJson() => {
        if (label != null) 'label': label,
        'reps': reps,
        'weight': weight,
        'order': order,
      };
}
