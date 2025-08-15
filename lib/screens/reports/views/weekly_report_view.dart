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

  void _selectWeek() async {
    // Usamos o seletor de dia normal para escolher um dia da semana desejada
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedWeek,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Theme(
            data: AppTheme.darkTheme.copyWith(
              dialogBackgroundColor: AppTheme.glassColor.withOpacity(0.2),
            ),
            child: child!,
          ),
        );
      },
    );

    if (selectedDate != null) {
      _loadReportForWeek(selectedDate);
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
    return Column(
      children: [
        TextButton.icon(
          onPressed: _selectWeek,
          icon: const Icon(Icons.calendar_today_outlined,
              color: AppTheme.accentColor),
          label: Text(
            _formatWeekRange(_selectedWeek),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor),
          ),
        ),
        Expanded(
          child: FutureBuilder<MonthlyReport>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentColor));
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
                        backgroundColor: AppTheme.accentColor,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bar_chart, size: 80, color: AppTheme.secondaryTextColor),
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
        Text(label, style: const TextStyle(color: AppTheme.secondaryTextColor)),
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
