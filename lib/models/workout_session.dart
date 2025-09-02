// lib/models/workout_session.dart
import 'workout_item.dart';

class WorkoutSession {
  final int? id;
  final String name;
  final String modality; // 'bodybuilding' | 'crossfit' | 'hyrox'
  final DateTime plannedDate;
  final List<WorkoutItem> items;

  const WorkoutSession({
    this.id,
    required this.name,
    required this.modality,
    required this.plannedDate,
    required this.items,
  });

  WorkoutSession copyWith({
    int? id,
    String? name,
    String? modality,
    DateTime? plannedDate,
    List<WorkoutItem>? items,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      modality: modality ?? this.modality,
      plannedDate: plannedDate ?? this.plannedDate,
      items: items ?? this.items,
    );
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as int?,
      name: json['name'] as String,
      modality: json['modality'] as String,
      plannedDate: DateTime.parse(json['planned_date'] as String),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => WorkoutItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'modality': modality,
      'planned_date': '${plannedDate.year.toString().padLeft(4, '0')}-'
          '${plannedDate.month.toString().padLeft(2, '0')}-'
          '${plannedDate.day.toString().padLeft(2, '0')}',
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  /// Payload para criar/atualizar sessão no backend
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'modality': modality,
      'planned_date': '${plannedDate.year.toString().padLeft(4, '0')}-'
          '${plannedDate.month.toString().padLeft(2, '0')}-'
          '${plannedDate.day.toString().padLeft(2, '0')}',
      'items': items.map((e) => e.toApiJson()).toList(),
    };
  }
}
