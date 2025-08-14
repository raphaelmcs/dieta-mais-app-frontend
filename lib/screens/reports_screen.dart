import 'package:dieta_mais_app/models/macro_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'dart:ui';

import '../api/api_service.dart';
import '../models/monthly_report.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glassmorphic_container.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Future<MonthlyReport>? _reportFuture;

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

  Future<MonthlyReport> _fetchReport(int year, int month) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('Token não encontrado');
    return _apiService.getMonthlyReport(token, year, month);
  }

  void _selectMonth() async {
    final selectedDate = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      // A estilização é feita pelo tema global
    );

    if (selectedDate != null) {
      _loadReportForMonth(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Relatórios Mensais'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _selectMonth, // Chamada correta, sem passar 'context'
          ),
        ],
      ),
      body: FutureBuilder<MonthlyReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor));
          }
          if (snapshot.hasError) {
            return _buildEmptyState();
          }
          if (snapshot.hasData) {
            final report = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                      'Médias Diárias (${DateFormat.yMMMM('pt_BR').format(_selectedMonth)})'),
                  GlassmorphicContainer(
                    child: _buildMacrosGrid(report.averageMacros),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Top 5 Alimentos Consumidos'),
                  GlassmorphicContainer(
                    child: _buildTopFoodsList(report.topFoods),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Análise Dieta+'),
                  GlassmorphicContainer(
                    child: _buildAiAnalysis(report.aiAnalysis),
                  ),
                ],
              ),
            );
          }
          return _buildEmptyState();
        },
      ),
    );
  }

  // ... Os outros métodos (_buildSectionTitle, _buildEmptyState, etc.) continuam aqui ...
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
          Text('Nenhum dado encontrado para este mês.',
              style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildMacrosGrid(AverageData data) {
    // <-- MUDANÇA AQUI
    return GridView.count(
      crossAxisCount: 3, // Agora com 3 colunas para um layout melhor
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      children: [
        _macroTile('Calorias', '${data.calories} kcal'),
        _macroTile('Proteínas', '${data.protein} g'),
        _macroTile('Carboidratos', '${data.carbs} g'),
        _macroTile('Gorduras', '${data.fats} g'),
        // NOVO TILE DE HIDRATAÇÃO
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
