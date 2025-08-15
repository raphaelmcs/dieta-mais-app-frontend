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
              backgroundColor: AppTheme.glassColor.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: AppTheme.glassColor.withOpacity(0.2)),
              ),
              title: const Text("Selecione o Ano"),
              content: SizedBox(
                width: 300,
                height: 300,
                child: Theme(
                  data: AppTheme.darkTheme.copyWith(
                    dialogBackgroundColor: Colors.transparent,
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
    return Column(
      children: [
        TextButton.icon(
          onPressed: _selectYear,
          icon: const Icon(Icons.calendar_month_outlined,
              color: AppTheme.accentColor),
          label: Text(
            _selectedYear.toString(),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<MonthlyAverage>>(
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
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final reportData = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  // GRÁFICO DE BARRAS ANUAL
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
                        leftTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14);
                              // Mapeia o número do mês para a inicial
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
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (value) => const FlLine(
                            color: AppTheme.secondaryTextColor,
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
                              color: AppTheme.accentColor,
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.show_chart, size: 80, color: AppTheme.secondaryTextColor),
          SizedBox(height: 16),
          Text('Nenhum dado encontrado para este ano.',
              style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
