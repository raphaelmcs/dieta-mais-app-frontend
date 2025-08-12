import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
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

// Helper class para conter todos os dados do dashboard
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
  DateTime _selectedDate = DateTime.now();

  // Variável de estado para a lista de refeições, para permitir a remoção instantânea
  List<MealLog> _mealsForSelectedDay = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    _dashboardDataFuture = _loadDashboardData(_selectedDate);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<DashboardData> _loadDashboardData(DateTime date) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      // Usando um Future para navegar após o build para evitar erros de estado
      Future.microtask(() => _performLogout(context));
      throw Exception('Token de autenticação não encontrado.');
    }
    final results = await Future.wait([
      _apiService.getDailySummary(token, date),
      _apiService.getMealsForDate(token, date),
    ]);
    final data = DashboardData(
      summary: results[0] as DailySummary,
      todaysMeals: results[1] as List<MealLog>,
    );
    // Atualiza a lista de estado sempre que novos dados são carregados
    setState(() {
      _mealsForSelectedDay = data.todaysMeals;
    });
    return data;
  }

  Future<void> _deleteMealLog(int mealLogId, int index) async {
    // Remove o item da lista local imediatamente para uma resposta visual rápida
    setState(() {
      _mealsForSelectedDay.removeAt(index);
    });
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token não encontrado');
      await _apiService.deleteMealLog(token, mealLogId);

      // Recarrega os dados do dashboard em segundo plano para atualizar os totais dos gráficos
      _loadDashboardData(_selectedDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao remover refeição: $e'),
            backgroundColor: Colors.red),
      );
      // Se der erro, recarrega a lista para reverter a remoção visual
      setState(() {
        _dashboardDataFuture = _loadDashboardData(_selectedDate);
      });
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        // O BackdropFilter envolve tudo para criar o desfoque do fundo do app
        return BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 8, sigmaY: 8), // Desfoque mais pronunciado
          // O Dialog em si é colocado dentro de um Container com nosso estilo de vidro
          child: Dialog(
            backgroundColor:
                Colors.transparent, // Fundo do Dialog base é transparente
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                // Este container cria a aparência do vidro
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.glassColor.withOpacity(0.25),
                      AppTheme.glassColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    width: 1.5,
                    color: AppTheme.glassColor.withOpacity(0.3),
                  ),
                ),
                // O tema interno controla apenas as cores do conteúdo do calendário
                child: Theme(
                  data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.accentColor,
                        onPrimary: Colors.black,
                        surface: Colors
                            .transparent, // Cor de fundo dos botões OK/Cancel
                        onSurface:
                            AppTheme.primaryTextColor, // Cor do texto dos dias
                      ),
                      textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.accentColor)),
                      datePickerTheme: DatePickerThemeData(
                        // Estilo para o texto auxiliar ("Selecione a data")
                        headerHelpStyle: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryTextColor.withOpacity(0.8),
                        ),
                        // Estilo para o texto principal ("seg., 11 de ago.")
                        headerHeadlineStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTextColor,
                        ),
                      )),
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dashboardDataFuture = _loadDashboardData(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: () => _selectDate(context),
        ),
        title: const Text(''),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _performLogout(context)),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() =>
                  _dashboardDataFuture = _loadDashboardData(_selectedDate))),
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
                Text(
                    "Refeições de ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTextColor)),
                const SizedBox(height: 8),
                Expanded(
                  child: _mealsForSelectedDay.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma refeição registrada para este dia.',
                            style: TextStyle(
                                color: AppTheme.secondaryTextColor,
                                fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _mealsForSelectedDay.length,
                          itemBuilder: (context, index) {
                            final meal = _mealsForSelectedDay[index];
                            return Dismissible(
                              key: Key(meal.id.toString()),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                _deleteMealLog(meal.id, index);
                              },
                              background: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete_forever,
                                    color: Colors.white),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: GlassmorphicContainer(
                                  borderRadius: 12,
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 0, horizontal: 16),
                                    title: Text(meal.foodName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(meal.quantity),
                                    trailing: Text('${meal.calories} kcal',
                                        style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold)),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SuggestionScreen(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
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
                          _dashboardDataFuture =
                              _loadDashboardData(_selectedDate);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
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
