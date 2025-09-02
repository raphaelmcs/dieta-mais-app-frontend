// lib/models/program_dtos.dart
class ProgramDto {
  final int id;
  final String name;

  /// slug: 'bodybuilding' | 'crossfit' | 'hyrox'
  final String modality;
  final bool isActive;

  ProgramDto({
    required this.id,
    required this.name,
    required this.modality,
    required this.isActive,
  });

  static String _slugFrom(dynamic modalityField, dynamic modalityIdField) {
    // 1) se vier como objeto {slug: ...}
    if (modalityField is Map && modalityField['slug'] != null) {
      return modalityField['slug'] as String;
    }
    // 2) se vier como string
    if (modalityField is String && modalityField.isNotEmpty) {
      return modalityField;
    }
    // 3) se vier apenas modality_id (índice do catálogo)
    if (modalityIdField is int) {
      switch (modalityIdField) {
        case 1:
          return 'bodybuilding';
        case 2:
          return 'crossfit';
        case 3:
          return 'hyrox';
      }
    }
    return ''; // desconhecido
  }

  factory ProgramDto.fromJson(Map<String, dynamic> json) {
    final modalitySlug = _slugFrom(json['modality'], json['modality_id']);
    return ProgramDto(
      id: json['id'] as int,
      name: json['name'] as String,
      modality: modalitySlug,
      isActive: (json['is_active'] ?? false) as bool,
    );
  }
}

/// ---- Inputs para criação/edição de programa ----

class ProgramBlockExerciseInput {
  final int exerciseId;
  final int order;
  final int sets;
  final int? reps;
  final double? weight;

  ProgramBlockExerciseInput({
    required this.exerciseId,
    required this.order,
    required this.sets,
    this.reps,
    this.weight,
  });

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'order': order,
        'sets': sets,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
      };
}

class ProgramBlockInput {
  final String code; // "A", "B", "C", ...
  final String? title;
  final List<ProgramBlockExerciseInput> exercises;

  ProgramBlockInput({
    required this.code,
    this.title,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        if (title != null && title!.isNotEmpty) 'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}
