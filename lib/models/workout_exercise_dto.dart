// lib/models/workout_exercise_dto.dart

class WorkoutExerciseDto {
  final int id;
  final String name;
  final String kind; // 'strength' | 'skill' | etc.
  final int? defaultReps;
  final double? defaultWeight;
  final Map<String, dynamic>? meta;

  WorkoutExerciseDto({
    required this.id,
    required this.name,
    required this.kind,
    this.defaultReps,
    this.defaultWeight,
    this.meta,
  });

  static int? _asIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _asDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  factory WorkoutExerciseDto.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseDto(
      id: (json['id'] is String)
          ? int.tryParse(json['id']) ?? 0
          : (json['id'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      kind: (json['kind'] ?? '').toString(),
      defaultReps: _asIntNullable(json['default_reps'] ?? json['defaultReps']),
      defaultWeight:
          _asDoubleNullable(json['default_weight'] ?? json['defaultWeight']),
      meta: (json['meta'] is Map<String, dynamic>)
          ? json['meta'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        if (defaultReps != null) 'default_reps': defaultReps,
        if (defaultWeight != null) 'default_weight': defaultWeight,
        if (meta != null) 'meta': meta,
      };
}
