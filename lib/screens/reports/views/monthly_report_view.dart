import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';

import 'package:dieta_mais_app/models/macro_data.dart';
import 'package:dieta_mais_app/models/monthly_report.dart';
import 'package:dieta_mais_app/models/daily_calorie_log.dart';
import 'package:dieta_mais_app/models/daily_hydration_log.dart';
import 'package:dieta_mais_app/api/api_service.dart';
import 'package:dieta_mais_app/theme/app_theme.dart';
import 'package:dieta_mais_app/widgets/glassmorphic_container.dart';

class MonthlyReportFullData {
  final MonthlyReport report;
  final List<DailyCalorieLog> chartData;
  final List<DailyHydrationLog> hydrationChartData;
  MonthlyReportFullData(
      {required this.report,
      required this.chartData,
      required this.hydrationChartData});
}

class MonthlyReportView extends StatefulWidget {
  const MonthlyReportView({super.key});
  @override
  State<MonthlyReportView> createState() => _MonthlyReportViewState();
}

class _MonthlyReportViewState extends State<MonthlyReportView> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Future<MonthlyReportFullData>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReportForMonth(_selectedMonth);
  }

  void _loadReportForMonth(DateTime month) {
    setState(() {
      _selectedMonth = month;
      _reportFuture = _fetchReport(month.year, month.month);
    });
  }

  Future<MonthlyReportFullData> _fetchReport(int year, int month) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('Token não encontrado');

    // Busca os três relatórios em paralelo
    final results = await Future.wait([
      _apiService.getMonthlyReport(token, year, month),
      _apiService.getMonthlyChartData(token, year, month),
      _apiService.getMonthlyHydrationChartData(
          token, year, month), // Nova chamada
    ]);

    return MonthlyReportFullData(
      report: results[0] as MonthlyReport,
      chartData: results[1] as List<DailyCalorieLog>,
      hydrationChartData: results[2] as List<DailyHydrationLog>, // Novo dado
    );
  }

  void _selectMonth() async {
    final selectedDate = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      _loadReportForMonth(selectedDate);
    }
  }

  // 2. NOVA FUNÇÃO PARA COMPARTILHAR
  void _shareReport(MonthlyReport report) {
    final monthName = DateFormat.yMMMM('pt_BR').format(_selectedMonth);
    final macros = report.averageMacros;

    final textToShare = """
    Meu Relatório de ${monthName} no Dieta+ App!

    📊 Médias Diárias:
    - Calorias: ${macros.calories} kcal
    - Proteínas: ${macros.protein} g
    - Carboidratos: ${macros.carbs} g
    - Gorduras: ${macros.fats} g
    - Hidratação: ${macros.hydrationMl} ml

    💡 Análise da IA:
    ${report.aiAnalysis.analysis}
    """;

    Share.share(textToShare, subject: 'Meu Relatório Mensal - Dieta+ App');
  }

  @override
  Widget build(BuildContext context) {
    // Pega o tema ativo para usar suas cores
    final theme = Theme.of(context);

    return Column(
      children: [
        TextButton.icon(
          onPressed: _selectMonth,
          icon: Icon(Icons.calendar_month_outlined, color: theme.primaryColor),
          label: Text(
            DateFormat.yMMMM('pt_BR').format(_selectedMonth),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor),
          ),
        ),
        Expanded(
          child: FutureBuilder<MonthlyReportFullData>(
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
                final report = snapshot.data!.report;
                final chartData = snapshot.data!.chartData;
                final hydrationChartData = snapshot.data!.hydrationChartData;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Flutuação de Calorias'),
                      _buildLineChart(chartData, theme.primaryColor,
                          yAxisTitle: 'Kcal'),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Flutuação de Hidratação'),
                      _buildLineChart(
                          hydrationChartData, Colors.lightBlueAccent,
                          yAxisTitle: 'ml', isHydration: true),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Resumo do Mês'),
                      GlassmorphicContainer(
                          child: _buildMacrosGrid(report.averageMacros)),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Top 5 Alimentos Consumidos'),
                      GlassmorphicContainer(
                          child: _buildTopFoodsList(report.topFoods)),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Análise Dieta+'),
/*                       GlassmorphicContainer(
                          child: _buildAiAnalysis(report.aiAnalysis)), */
                    ],
                  ),
                );
              }
              return _buildEmptyState();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<dynamic> chartData, Color color,
      {required String yAxisTitle, bool isHydration = false}) {
    final theme = Theme.of(context);
    List<FlSpot> spots = chartData.map((d) {
      final yValue =
          isHydration ? d.totalMl.toDouble() : d.totalCalories.toDouble();
      return FlSpot(d.day.toDouble(), yValue);
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: const SideTitles(showTitles: true, reservedSize: 40),
              axisNameWidget: Text(yAxisTitle,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color)),
              axisNameSize: 24,
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              axisNameWidget: Text("Dia do Mês",
                  style: TextStyle(color: theme.textTheme.bodySmall?.color)),
              axisNameSize: 24,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border:
                Border.all(color: theme.unselectedWidgetColor.withOpacity(0.5)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart,
              size: 80, color: Theme.of(context).unselectedWidgetColor),
          const SizedBox(height: 16),
          const Text('Nenhum dado encontrado para este mês.',
              style: TextStyle(fontSize: 18)),
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
                TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildTopFoodsList(Map<String, int> topFoods) {
    if (topFoods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14.0),
        child: Text('Nenhum alimento registrado este mês.'),
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
