import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';

import 'package:dieta_mais_app/models/macro_data.dart';
import 'package:dieta_mais_app/models/monthly_report.dart'; // Reutilizamos o mesmo modelo
import 'package:dieta_mais_app/api/api_service.dart';
import 'package:dieta_mais_app/theme/app_theme.dart';
import 'package:dieta_mais_app/widgets/glassmorphic_container.dart';

class WeeklyReportView extends StatefulWidget {
  const WeeklyReportView({super.key});

  @override
  State<WeeklyReportView> createState() => _WeeklyReportViewState();
}

class _WeeklyReportViewState extends State<WeeklyReportView> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  // O estado agora controla a semana selecionada (representada por qualquer dia dela)
  DateTime _selectedWeek = DateTime.now();
  Future<MonthlyReport>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReportForWeek(_selectedWeek);
  }

  void _loadReportForWeek(DateTime dateInWeek) {
    setState(() {
      _selectedWeek = dateInWeek;
      _reportFuture = _fetchReport(dateInWeek);
    });
  }

  Future<MonthlyReport> _fetchReport(DateTime date) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('Token não encontrado');
    return _apiService.getWeeklyReport(token, date);
  }

  Future<void> _selectWeek() async {
    DateTime? tempSelectedDate = _selectedWeek;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.all(24),
          content: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppThemes.glassColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1.5,
                  color: AppThemes.glassColor.withOpacity(0.3),
                ),
              ),
              // ***** A CORREÇÃO ESTÁ AQUI *****
              // Damos um tamanho fixo e seguro ao conteúdo do diálogo
              child: SizedBox(
                width: 300,
                height: 420,
                child: Theme(
                  data: Theme.of(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: CalendarDatePicker(
                          initialDate: _selectedWeek,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          onDateChanged: (DateTime date) {
                            tempSelectedDate = date;
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text('CANCELAR'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop(tempSelectedDate);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      _loadReportForWeek(picked);
    }
  }

  // Helper para formatar o intervalo da semana
  String _formatWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${DateFormat.d('pt_BR').format(startOfWeek)} - ${DateFormat.d('pt_BR').format(endOfWeek)} de ${DateFormat.MMM('pt_BR').format(endOfWeek)}';
  }

  void _shareReport(MonthlyReport report) {
    final weekRange = _formatWeekRange(_selectedWeek);
    final macros = report.averageMacros;

    final textToShare = """
    Meu Relatório Semanal no Dieta+ App (${weekRange})!

    📊 Médias Diárias:
    - Calorias: ${macros.calories} kcal
    - Proteínas: ${macros.protein} g
    - Carboidratos: ${macros.carbs} g
    - Gorduras: ${macros.fats} g
    - Hidratação: ${macros.hydrationMl} ml

    💡 Análise da IA:
    ${report.aiAnalysis.analysis}
    """;

    Share.share(textToShare, subject: 'Meu Relatório Semanal - Dieta+ App');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextButton.icon(
          onPressed: _selectWeek,
          icon: Icon(Icons.calendar_today_outlined, color: theme.primaryColor),
          label: Text(
            _formatWeekRange(_selectedWeek),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor),
          ),
        ),
        Expanded(
          child: FutureBuilder<MonthlyReport>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child:
                        CircularProgressIndicator(color: theme.primaryColor));
              }
              if (snapshot.hasError) {
                return _buildEmptyState();
              }
              if (snapshot.hasData) {
                final report = snapshot.data!;
                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Médias Diárias (Semana)'),
                          GlassmorphicContainer(
                              child: _buildMacrosGrid(report.averageMacros)),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Top 5 Alimentos Consumidos'),
                          GlassmorphicContainer(
                              child: _buildTopFoodsList(report.topFoods)),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Análise Dieta+'),
                          GlassmorphicContainer(
                              child: _buildAiAnalysis(report.aiAnalysis)),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () => _shareReport(report),
                        backgroundColor: theme.primaryColor,
                        child: const Icon(Icons.share,
                            color: Color.fromARGB(255, 250, 122, 36)),
                      ),
                    ),
                  ],
                );
              }
              return _buildEmptyState();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart,
              size: 80, color: Theme.of(context).unselectedWidgetColor),
          SizedBox(height: 16),
          Text('Nenhum dado encontrado para esta semana',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildMacrosGrid(AverageData data) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      children: [
        _macroTile('Calorias', '${data.calories} kcal'),
        _macroTile('Proteínas', '${data.protein} g'),
        _macroTile('Carboidratos', '${data.carbs} g'),
        _macroTile('Gorduras', '${data.fats} g'),
        _macroTile('Hidratação', '${data.hydrationMl} ml'),
      ],
    );
  }

  Widget _macroTile(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))
      ],
    );
  }

  Widget _buildTopFoodsList(Map<String, int> topFoods) {
    if (topFoods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14.0),
        child: Text('Nenhum alimento registrado esta semana.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: topFoods.entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Text(entry.key,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis)),
                      Text('${entry.value}x',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAiAnalysis(AiAnalysis analysis) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(analysis.analysis,
              style:
                  const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
          const SizedBox(height: 14),
          const Text('Sugestões:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...analysis.suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('• $suggestion'),
              )),
        ],
      ),
    );
  }
}
