// lib/models/workout.dart
import 'workout_set.dart';

/// Status do treino
enum WorkoutStatus { pending, completed }

extension WorkoutStatusX on WorkoutStatus {
  String get value => this == WorkoutStatus.completed ? 'completed' : 'pending';
  static WorkoutStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'completed':
        return WorkoutStatus.completed;
      default:
        return WorkoutStatus.pending;
    }
  }
}

/// Modalidade do treino
enum WorkoutModality { bodybuilding, crossfit, hyrox }

extension WorkoutModalityX on WorkoutModality {
  String get value => switch (this) {
        WorkoutModality.bodybuilding => 'bodybuilding',
        WorkoutModality.crossfit => 'crossfit',
        WorkoutModality.hyrox => 'hyrox',
      };

  static WorkoutModality parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'crossfit':
        return WorkoutModality.crossfit;
      case 'hyrox':
        return WorkoutModality.hyrox;
      default:
        return WorkoutModality.bodybuilding;
    }
  }
}

class Workout {
  final String id;
  final String title;
  final WorkoutModality modality; // NEW
  final String muscleGroup; // para musculação; pode ser "Geral" nas demais
  final DateTime plannedDate;
  final Duration? plannedDuration;
  final List<WorkoutSet>
      sets; // usamos para Musculação e como "blocos" p/ CrossFit/Hyrox
  final WorkoutStatus status;
  final String? notes;

  // CrossFit
  final String? wodType; // "for_time", "amrap", "emom"
  final int? timeCapMinutes; // cap em min
  final int? rounds; // rounds planejados (se aplicável)

  const Workout({
    required this.id,
    required this.title,
    this.modality = WorkoutModality.bodybuilding,
    required this.muscleGroup,
    required this.plannedDate,
    this.plannedDuration,
    this.sets = const [],
    this.status = WorkoutStatus.pending,
    this.notes,
    this.wodType,
    this.timeCapMinutes,
    this.rounds,
  });

  bool get isCompleted => status == WorkoutStatus.completed;

  bool isForDate(DateTime d) =>
      plannedDate.year == d.year &&
      plannedDate.month == d.month &&
      plannedDate.day == d.day;

  Workout copyWith({
    String? id,
    String? title,
    WorkoutModality? modality,
    String? muscleGroup,
    DateTime? plannedDate,
    Duration? plannedDuration,
    List<WorkoutSet>? sets,
    WorkoutStatus? status,
    String? notes,
    String? wodType,
    int? timeCapMinutes,
    int? rounds,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      modality: modality ?? this.modality,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      plannedDate: plannedDate ?? this.plannedDate,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      sets: sets ?? this.sets,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      wodType: wodType ?? this.wodType,
      timeCapMinutes: timeCapMinutes ?? this.timeCapMinutes,
      rounds: rounds ?? this.rounds,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.parse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    return DateTime.now();
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    final minutes = _asInt(json['planned_duration_minutes']);
    final seconds = _asInt(json['planned_duration']);
    final duration = minutes > 0
        ? Duration(minutes: minutes)
        : (seconds > 0 ? Duration(seconds: seconds) : null);

    final rawSets = (json['sets'] as List?) ?? const [];
    final sets = rawSets
        .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
        .toList();

    return Workout(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Treino').toString(),
      modality: WorkoutModalityX.parse(json['modality'] as String?),
      muscleGroup:
          (json['muscle_group'] ?? json['muscleGroup'] ?? 'Geral').toString(),
      plannedDate: _parseDate(
          json['planned_date'] ?? json['plannedDate'] ?? json['date']),
      plannedDuration: duration,
      sets: sets,
      status: WorkoutStatusX.parse(json['status'] as String?),
      notes: json['notes']?.toString(),
      wodType: json['wod_type']?.toString(),
      timeCapMinutes: _asInt(json['time_cap_minutes']),
      rounds: _asInt(json['rounds']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'modality': modality.value,
        'muscle_group': muscleGroup,
        'planned_date':
            '${plannedDate.year.toString().padLeft(4, '0')}-${plannedDate.month.toString().padLeft(2, '0')}-${plannedDate.day.toString().padLeft(2, '0')}',
        if (plannedDuration != null)
          'planned_duration_minutes': plannedDuration!.inMinutes,
        'sets': sets.map((s) => s.toJson()).toList(),
        'status': status.value,
        if (notes != null) 'notes': notes,
        if (wodType != null) 'wod_type': wodType,
        if (timeCapMinutes != null) 'time_cap_minutes': timeCapMinutes,
        if (rounds != null) 'rounds': rounds,
      };
}
