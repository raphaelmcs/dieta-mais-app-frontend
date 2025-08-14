import 'macro_data.dart';

class AiAnalysis {
  final String analysis;
  final List<String> suggestions;

  AiAnalysis({required this.analysis, required this.suggestions});

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      analysis: json['analysis'] ?? 'Nenhuma análise disponível.',
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}

class MonthlyReport {
  final AverageData averageMacros;
  final Map<String, int> topFoods;
  final AiAnalysis aiAnalysis;

  MonthlyReport({
    required this.averageMacros,
    required this.topFoods,
    required this.aiAnalysis,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      averageMacros: AverageData.fromJson(json['average_data']),
      topFoods: Map<String, int>.from(json['top_foods']),
      aiAnalysis: AiAnalysis.fromJson(json['ai_analysis']),
    );
  }
}
