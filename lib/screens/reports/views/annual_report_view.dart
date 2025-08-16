import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

import 'package:dieta_mais_app/api/api_service.dart';
import 'package:dieta_mais_app/models/monthly_average.dart';
import 'package:dieta_mais_app/theme/app_theme.dart';

class AnnualReportView extends StatefulWidget {
  const AnnualReportView({super.key});
  @override
  State<AnnualReportView> createState() => _AnnualReportViewState();
}

class _AnnualReportViewState extends State<AnnualReportView> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  int _selectedYear = DateTime.now().year;
  Future<List<MonthlyAverage>>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReportForYear(_selectedYear);
  }

  void _loadReportForYear(int year) {
    setState(() {
      _selectedYear = year;
      _reportFuture = _fetchReport(year);
    });
  }

  Future<List<MonthlyAverage>> _fetchReport(int year) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('Token não encontrado');
    return _apiService.getAnnualReport(token, year);
  }

  void _selectYear() async {
    // Usamos o YearPicker que já vem com o Flutter
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              backgroundColor: AppThemes.glassColor.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: AppThemes.glassColor.withOpacity(0.2)),
              ),
              title: const Text("Selecione o Ano"),
              content: SizedBox(
                width: 300,
                height: 300,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppThemes.auroraPurpura.themeData
                              .primaryColor, // Mantém a cor de destaque
                        ),
                  ),
                  child: YearPicker(
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    selectedDate: DateTime(_selectedYear),
                    onChanged: (DateTime dateTime) {
                      Navigator.pop(context, dateTime);
                    },
                  ),
                ),
              ),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pega o tema ativo para usar suas cores
    final theme = Theme.of(context);

    return Column(
      children: [
        TextButton.icon(
          onPressed: _selectYear,
          icon: Icon(Icons.calendar_month_outlined, color: theme.primaryColor),
          label: Text(
            _selectedYear.toString(),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<MonthlyAverage>>(
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
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final reportData = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: const SideTitles(
                              showTitles: true, reservedSize: 40),
                          axisNameWidget: Text("Média de Kcal",
                              style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color)),
                          axisNameSize: 24,
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // 'const' removido
                              final style = TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14);
                              const months = [
                                'Jan',
                                'Fev',
                                'Mar',
                                'Abr',
                                'Mai',
                                'Jun',
                                'Jul',
                                'Ago',
                                'Set',
                                'Out',
                                'Nov',
                                'Dez'
                              ];
                              return SideTitleWidget(
                                  meta: meta,
                                  child: Text(months[value.toInt() - 1],
                                      style: style));
                            },
                            reservedSize: 38,
                          ),
                          axisNameWidget: Text("Mês",
                              style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color)),
                          axisNameSize: 24,
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.unselectedWidgetColor,
                            strokeWidth: 0.5),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: reportData.map((monthlyData) {
                        return BarChartGroupData(
                          x: monthlyData.month,
                          barRods: [
                            BarChartRodData(
                              toY: monthlyData.averageCalories.toDouble(),
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor.withOpacity(0.8),
                                  theme.primaryColor.withOpacity(0.4),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                  color: theme.primaryColor, width: 1),
                            )
                          ],
                        );
                      }).toList(),
                    ),
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

  Widget _buildEmptyState() {
    // Pega o tema ativo do contexto
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Usa a cor de ícone do tema
          Icon(Icons.show_chart,
              size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Nenhum dado encontrado para este ano.',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
