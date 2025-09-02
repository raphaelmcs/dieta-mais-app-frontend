// lib/models/workout_item.dart
import 'workout_exercise_dto.dart';

enum WorkoutItemStatus { pending, completed }

class WorkoutItem {
  final WorkoutExerciseDto exercise;
  final int reps;
  final double weight;
  final int order;
  final String? notes;
  final WorkoutItemStatus status;

  const WorkoutItem({
    required this.exercise,
    this.reps = 0,
    this.weight = 0,
    required this.order,
    this.notes,
    this.status = WorkoutItemStatus.pending,
  });

  WorkoutItem copyWith({
    WorkoutExerciseDto? exercise,
    int? reps,
    double? weight,
    int? order,
    String? notes,
    WorkoutItemStatus? status,
  }) {
    return WorkoutItem(
      exercise: exercise ?? this.exercise,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  factory WorkoutItem.fromJson(Map<String, dynamic> json) {
    return WorkoutItem(
      exercise:
          WorkoutExerciseDto.fromJson(json['exercise'] as Map<String, dynamic>),
      reps: (json['reps'] ?? 0) is int
          ? json['reps'] as int
          : int.tryParse(json['reps'].toString()) ?? 0,
      weight: (json['weight'] ?? 0) is double
          ? json['weight'] as double
          : double.tryParse(json['weight'].toString()) ?? 0,
      order: (json['order'] ?? 1) as int,
      notes: json['notes'] as String?,
      status: (json['status'] == 'completed')
          ? WorkoutItemStatus.completed
          : WorkoutItemStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'reps': reps,
      'weight': weight,
      'order': order,
      'notes': notes,
      'status': status == WorkoutItemStatus.completed ? 'completed' : 'pending',
    };
  }

  /// Payload simplificado para API (usa exercise_id)
  Map<String, dynamic> toApiJson() {
    return {
      'exercise_id': exercise.id,
      'reps': reps,
      'weight': weight,
      'order': order,
      'notes': notes,
      'status': status == WorkoutItemStatus.completed ? 'completed' : 'pending',
    };
  }

  /// Rótulo amigável para chips/itens na UI
  String displayLabel() {
    final parts = <String>[exercise.name];
    if (reps > 0) parts.add('x$reps');
    if (weight > 0) parts.add('${weight.toStringAsFixed(1)}kg');
    return parts.join(' • ');
  }
}
