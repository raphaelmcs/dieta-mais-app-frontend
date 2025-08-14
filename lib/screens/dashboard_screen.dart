import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui';

import '../widgets/glass_dialog.dart';
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

  void _showUpdateGoalDialog(int currentGoal) {
    final goalController = TextEditingController(text: currentGoal.toString());
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            title: const Text('Alterar Meta de Hidratação'),
            content: TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nova meta em ml'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar')),
              TextButton(
                onPressed: () async {
                  final goal = int.tryParse(goalController.text);
                  if (goal != null && goal > 0) {
                    try {
                      final token = await _storage.read(key: 'auth_token');
                      if (token == null) return;
                      await _apiService.updateHydrationGoal(token, goal);
                      Navigator.of(context).pop();
                      // Recarrega os dados para mostrar a nova meta
                      setState(() {
                        _dashboardDataFuture =
                            _loadDashboardData(_selectedDate);
                      });
                    } catch (e) {
                      // Lógica para mostrar erro
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Erro ao salvar: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
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
    DateTime? tempSelectedDate = _selectedDate;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          content: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.glassColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1.5,
                  color: AppTheme.glassColor.withOpacity(0.3),
                ),
              ),
              // ***** A CORREÇÃO ESTÁ AQUI *****
              // Damos um tamanho fixo e seguro ao conteúdo do diálogo
              child: SizedBox(
                width: 300,
                height: 420,
                child: Theme(
                  data: AppTheme.darkTheme,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: CalendarDatePicker(
                          initialDate: _selectedDate,
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dashboardDataFuture = _loadDashboardData(picked);
      });
    }
  }

  LinearGradient _getHydrationGradient(double percent) {
    if (percent <= 0.33) {
      // De 0% a 33%, a barra é toda vermelha
      return const LinearGradient(
        colors: [Colors.redAccent, Colors.redAccent],
      );
    } else if (percent <= 0.66) {
      // De 34% a 66%, a barra é um gradiente de vermelho para laranja
      return const LinearGradient(
        colors: [Colors.redAccent, Colors.orangeAccent],
      );
    } else {
      // Acima de 66%, a barra é um gradiente completo de vermelho para azul
      return const LinearGradient(
        colors: [
          Colors.redAccent,
          Colors.orangeAccent,
          Colors.lightBlueAccent,
        ],
      );
    }
  }

  Widget _buildHydrationCard(HydrationData hydration) {
    double percent =
        (hydration.goal > 0) ? (hydration.consumed / hydration.goal) : 0.0;
    int surplus = hydration.consumed - hydration.goal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hidratação de Hoje',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => _showUpdateGoalDialog(hydration.goal),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${hydration.consumed} / ${hydration.goal} ml',
                          style: const TextStyle(
                              fontSize: 16, color: AppTheme.secondaryTextColor),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit_outlined,
                            size: 18, color: AppTheme.secondaryTextColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearPercentIndicator(
                lineHeight: 12.0,
                percent: percent.clamp(0.0, 1.0),
                barRadius: const Radius.circular(6),
                backgroundColor: Colors.white.withOpacity(0.1),
                linearGradient: _getHydrationGradient(percent),
              ),

              // ***** CONDIÇÃO ADICIONADA AQUI *****
              if (percent > 1.0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Você ultrapassou a meta em ${surplus} ml!',
                    style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddWaterDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Adicionar Água"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: Colors.lightBlueAccent.withOpacity(0.3),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ***** 3. MÉTODO PARA O DIÁLOGO DE ADICIONAR ÁGUA RESTAURADO *****
  void _showAddWaterDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              title: const Text('Adicionar Consumo de Água'),
              content: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Quantidade em ml'),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar')),
                TextButton(
                  onPressed: () async {
                    final amount = int.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      try {
                        final token = await _storage.read(key: 'auth_token');
                        if (token == null) return;
                        await _apiService.addHydrationLog(token, amount);
                        Navigator.of(context).pop();
                        setState(() {
                          _dashboardDataFuture =
                              _loadDashboardData(_selectedDate);
                        });
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Erro: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Registrar'),
                ),
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        leadingWidth: 150, // Aumenta o espaço para o leading
        leading: GestureDetector(
          onTap: () => _selectDate(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 8),
                // Exibe a data formatada
                Text(
                  DateFormat('dd/MM').format(_selectedDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        title: const Text(''),
        centerTitle: true,
        actions: [
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
            final todaysMeals = snapshot.data!.todaysMeals;

            return SingleChildScrollView(
              child: Column(children: [
                // ***** LAYOUT REORGANIZADO AQUI *****

                // 1. CARD DE HIDRATAÇÃO VEM PRIMEIRO
                _buildHydrationCard(summary.hydration),

                const SizedBox(height: 24), // Espaçamento

                // 2. CARROSSEL DE GRÁFICOS
                SizedBox(
                  height: 250,
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

                // 3. LISTA DE REFEIÇÕES
                Text(
                    "Refeições de ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTextColor)),
                const SizedBox(height: 8),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: todaysMeals.length,
                  itemBuilder: (context, index) {
                    final meal = todaysMeals[index];
                    return Dismissible(
                      key: Key(meal.id.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteMealLog(meal.id, index);
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
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
                                      SuggestionScreen(foodName: meal.foodName),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ]),
            );
          }
          return const Center(child: Text('Nenhum dado encontrado.'));
        },
      ),
    );
  }

  Widget _buildChartPage(String title, AverageData data, AverageData targets,
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
