import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:ui';

import '../../../models/daily_summary.dart';
import '../../../models/macro_data.dart';
import '../../../screens/log_meal_screen.dart';
//import '../../../theme/app_theme.dart';

class ChartsPageView extends StatelessWidget {
  final PageController pageController;
  final DailySummary summary;
  final AnimationController buttonAnimationController;
  final VoidCallback onMealLogged;
  final DateTime selectedDate;

  const ChartsPageView({
    super.key,
    required this.pageController,
    required this.summary,
    required this.buttonAnimationController,
    required this.onMealLogged,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView(
            controller: pageController,
            children: [
              _buildChartPage(
                  context, 'Consumido', summary.consumed, summary.targets,
                  dietId: summary.dietId),
              _buildChartPage(
                  context, 'Restante', summary.remaining, summary.targets),
              _buildChartPage(
                  context, 'Metas', summary.targets, summary.targets),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: SmoothPageIndicator(
            controller: pageController,
            count: 3,
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: Theme.of(context).primaryColor,
              dotColor: Colors.white24,
            ),
          ),
        ),
      ],
    );
  }

  // Os métodos auxiliares agora recebem o 'context'
  Widget _buildChartPage(BuildContext context, String title, AverageData? data,
      AverageData? targets,
      {int? dietId}) {
    final theme = Theme.of(context);

    // Garante valores padrão caso os dados sejam nulos
    final safeTargets = targets ??
        AverageData(calories: 0, protein: 0, carbs: 0, fats: 0, hydrationMl: 0);
    final safeData = data ??
        AverageData(calories: 0, protein: 0, carbs: 0, fats: 0, hydrationMl: 0);

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: safeTargets.calories > 0
                    ? safeTargets.calories.toDouble()
                    : 2000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final style = TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14);
                        String labelText;
                        String valueText;
                        switch (value.toInt()) {
                          case 0:
                            labelText = 'Kcal';
                            valueText = '(${safeData.calories})';
                            break;
                          case 1:
                            labelText = 'Prot';
                            valueText = '(${safeData.protein}g)';
                            break;
                          case 2:
                            labelText = 'Carb';
                            valueText = '(${safeData.carbs}g)';
                            break;
                          case 3:
                            labelText = 'Gord';
                            valueText = '(${safeData.fats}g)';
                            break;
                          default:
                            labelText = '';
                            valueText = '';
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Column(
                            children: [
                              Text(labelText, style: style),
                              const SizedBox(height: 2),
                              Text(valueText,
                                  style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 12)),
                            ],
                          ),
                        );
                      },
                      reservedSize: 58,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _makeBarGroup(
                      0, safeData.calories.toDouble(), theme.primaryColor),
                  _makeBarGroup(1, safeData.protein.toDouble() * 4,
                      Colors.lightBlueAccent),
                  _makeBarGroup(
                      2, safeData.carbs.toDouble() * 4, Colors.orangeAccent),
                  _makeBarGroup(
                      3, safeData.fats.toDouble() * 9, Colors.pinkAccent),
                ],
              ),
            ),
          ),
        ),
        if (title == 'Consumido')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: GestureDetector(
              onTapDown: (_) => buttonAnimationController.forward(),
              onTapUp: (_) => buttonAnimationController.reverse(),
              onTapCancel: () => buttonAnimationController.reverse(),
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (dietId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Crie ou ative um plano alimentar para registrar refeições.'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                    return;
                  }
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (context) =>
                            LogMealScreen(dietId: dietId, date: selectedDate)),
                  );
                  if (result == true) {
                    onMealLogged();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  backgroundColor: theme.primaryColor.withOpacity(0.3),
                  foregroundColor: theme.textTheme.bodyLarge?.color,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Registrar Refeição'),
              ).animate(controller: buttonAnimationController).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(0.95, 0.95),
                    curve: Curves.easeOut,
                  ),
            ),
          ),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          // Em vez de uma cor sólida, usamos um gradiente para o efeito de vidro
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          width: 22,
          borderRadius: BorderRadius.circular(6),
          // Adicionamos uma borda sutil para definir a forma
          borderSide: BorderSide(color: color, width: 1),
        ),
      ],
    );
  }
}
