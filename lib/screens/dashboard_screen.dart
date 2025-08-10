import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

import 'login_screen.dart';
import 'log_meal_screen.dart';
import 'suggestion_screen.dart';
import '../api/api_service.dart';
import '../models/daily_summary.dart';
import '../models/macro_data.dart';
import '../models/meal_log.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glassmorphic_container.dart';

class DashboardData {
  final DailySummary summary;
  final List<MealLog> todaysMeals;
  DashboardData({required this.summary, required this.todaysMeals});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final _pageController = PageController();
  Future<DashboardData>? _dashboardDataFuture;
  List<MealLog> _todaysMeals = [];

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _loadDashboardData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<DashboardData> _loadDashboardData() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      _performLogout(context);
      throw Exception('Token de autenticação não encontrado.');
    }
    final results = await Future.wait([
      _apiService.getDailySummary(token),
      _apiService.getTodaysMeals(token),
    ]);
    final data = DashboardData(
      summary: results[0] as DailySummary,
      todaysMeals: results[1] as List<MealLog>,
    );
    _todaysMeals = data.todaysMeals;
    return data;
  }

  Future<void> _deleteMealLog(int mealLogId, int index) async {
    setState(() {
      _todaysMeals.removeAt(index);
    });
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token não encontrado');
      await _apiService.deleteMealLog(token, mealLogId);
      setState(() {
        _dashboardDataFuture = _loadDashboardData();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao remover refeição: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    await _storage.delete(key: 'auth_token');
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // A chamada correta usa argumentos NOMEADOS: appBar: e body:
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _performLogout(context)),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  setState(() => _dashboardDataFuture = _loadDashboardData())),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final summary = snapshot.data!.summary;
            if (_todaysMeals.isEmpty &&
                snapshot.connectionState != ConnectionState.waiting) {
              _todaysMeals = snapshot.data!.todaysMeals;
            }

            return Column(
              children: [
                SizedBox(
                  height: 350,
                  child: PageView(
                    controller: _pageController,
                    children: [
                      _buildChartPage(
                          'Consumido', summary.consumed, summary.targets,
                          dietId: summary.dietId),
                      _buildChartPage(
                          'Restante', summary.remaining, summary.targets),
                      _buildChartPage(
                          'Metas', summary.targets, summary.targets),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: AppTheme.accentColor,
                      dotColor: Colors.white24,
                    ),
                  ),
                ),
                const Text("Refeições de Hoje",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTextColor)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _todaysMeals.length,
                    itemBuilder: (context, index) {
                      final meal = _todaysMeals[index];
                      return Dismissible(
                        key: Key(meal.id.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteMealLog(meal.id, index);
                        },
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete_forever,
                              color: Colors.white),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: GlassmorphicContainer(
                            borderRadius: 12,
                            child: ListTile(
                              // ***** ALTERAÇÃO 2: Ativando o modo "denso" para diminuir a altura *****
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 16),
                              title: Text(meal.foodName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(meal.quantity),
                              trailing: Text(
                                '${meal.calories} kcal',
                                // ***** ALTERAÇÃO 3: Trocando a cor para um tom de laranja *****
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 250, 219, 172),
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SuggestionScreen(
                                        foodName: meal.foodName),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Nenhum dado encontrado.'));
        },
      ),
    );
  }

  Widget _buildChartPage(String title, MacroData data, MacroData targets,
      {int? dietId}) {
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
                maxY: targets.calories > 0 ? targets.calories.toDouble() : 2000,
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
                        const style = TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14);
                        String labelText;
                        String valueText;
                        switch (value.toInt()) {
                          case 0:
                            labelText = 'Kcal';
                            valueText = '(${data.calories})';
                            break;
                          case 1:
                            labelText = 'Prot';
                            valueText = '(${data.protein}g)';
                            break;
                          case 2:
                            labelText = 'Carb';
                            valueText = '(${data.carbs}g)';
                            break;
                          case 3:
                            labelText = 'Gord';
                            valueText = '(${data.fats}g)';
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
                                  style: const TextStyle(
                                      color: AppTheme.secondaryTextColor,
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
                      0, data.calories.toDouble(), AppTheme.accentColor),
                  _makeBarGroup(
                      1, data.protein.toDouble() * 4, Colors.lightBlueAccent),
                  _makeBarGroup(
                      2, data.carbs.toDouble() * 4, Colors.orangeAccent),
                  _makeBarGroup(3, data.fats.toDouble() * 9, Colors.pinkAccent),
                ],
              ),
            ),
          ),
        ),
        if (title == 'Consumido')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            // ClipRRect garante que o efeito de vidro tenha as bordas arredondadas
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30), // Borda bem arredondada
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      width: 1.5,
                      color: AppTheme.glassColor.withOpacity(0.2),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (context) =>
                                LogMealScreen(dietId: dietId!)),
                      );
                      if (result == true) {
                        setState(() {
                          _dashboardDataFuture = _loadDashboardData();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.transparent, // Deixa o botão transparente
                      shadowColor:
                          Colors.transparent, // Remove a sombra do botão
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                    ),
                    icon:
                        const Icon(Icons.add, color: AppTheme.primaryTextColor),
                    label: const Text('Registrar Refeição'),
                  ),
                ),
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
          color: color,
          width: 22,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}
