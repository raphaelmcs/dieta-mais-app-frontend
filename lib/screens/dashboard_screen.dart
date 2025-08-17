import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'login_screen.dart';
import 'log_meal_screen.dart';
import 'suggestion_screen.dart';
import '../api/api_service.dart';
import '../models/daily_summary.dart';
import '../models/macro_data.dart';
import '../models/meal_log.dart';
import '../theme/app_theme.dart';
//import '../providers/theme_provider.dart';
import '../models/recalculated_diet.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glassmorphic_container.dart';
import '../models/dashboard_data.dart';
import '../models/recalculation_result.dart';
import 'diet_plan_detail_screen.dart';

// Helper class para conter todos os dados do dashboard
/* class DashboardData {
  final DailySummary summary;
  final List<MealLog> todaysMeals;
  DashboardData({required this.summary, required this.todaysMeals});
}
 */
// O Dashboard agora é um StatelessWidget que recebe os dados de fora
class DashboardScreen extends StatefulWidget {
  final Future<DashboardData>? dashboardDataFuture;
  final VoidCallback onRefresh;
  final Function(DateTime) onSelectDate;
  final DateTime selectedDate;

  const DashboardScreen({
    super.key,
    required this.dashboardDataFuture,
    required this.onRefresh,
    required this.onSelectDate,
    required this.selectedDate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final _pageController = PageController();
  Future<DashboardData>? _dashboardDataFuture;
  DateTime _selectedDate = DateTime.now();
  late final AnimationController _buttonAnimationController;

  bool _hasNewRecalculatedPlan = false;
  int? _newPlanId;
  RecalculatedDiet? _lastRecalculationAnalysis; // Guarda a análise da IA

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    _dashboardDataFuture = _loadDashboardData(_selectedDate);
    _buttonAnimationController =
        AnimationController(vsync: this, duration: 150.ms);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<DashboardData> _loadDashboardData(DateTime date) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      Future.microtask(() => _performLogout(context));
      throw Exception('Token de autenticação não encontrado.');
    }
    final results = await Future.wait([
      _apiService.getDailySummary(token, date),
      _apiService.getMealsForDate(token, date),
    ]);
    return DashboardData(
      summary: results[0] as DailySummary,
      todaysMeals: results[1] as List<MealLog>,
    );
  }

  Future<void> _reloadData() async {
    setState(() {
      _dashboardDataFuture = _loadDashboardData(_selectedDate);
    });
  }

  Future<void> _deleteMealLog(int mealLogId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token não encontrado');
      await _apiService.deleteMealLog(token, mealLogId);
      _reloadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao remover refeição: $e'),
              backgroundColor: Colors.red),
        );
      }
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

// A lógica de Recálculo agora recebe os dados necessários como parâmetros
  Future<void> _handleOffPlanMeal(DailySummary summary) async {
    final mealWasLogged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            LogMealScreen(dietId: summary.dietId!, date: widget.selectedDate),
      ),
    );
    if (mealWasLogged == true && mounted) {
      final wantsToRecalculate = await _showRecalculationConfirmationDialog();
      if (wantsToRecalculate == true) {
        _triggerRecalculation();
      }
    }
  }

  // MÉTODO QUE MOSTRA A CONFIRMAÇÃO
  Future<bool?> _showRecalculationConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      // Torna a barreira semi-transparente para o desfoque ser visível
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        // Adiciona o BackdropFilter para embaçar o fundo
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            // Opcional: ajusta a cor de fundo do AlertDialog para combinar
            backgroundColor: AppThemes.glassColor.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: AppThemes.glassColor.withOpacity(0.2)),
            ),
            title: const Text('Ajustar o Dia?'),
            content: const Text(
                'Percebemos uma refeição não planejada. Deseja que o Dieta+ ajuste as refeições restantes do seu dia para compensar?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Não')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sim, ajustar!')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerRecalculation() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token não encontrado');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aguarde, a Dieta+ está recalculando seu dia...')),
      );

      // A API agora retorna o ID e a análise
      final result = await _apiService.recalculateDiet(token);

      if (mounted) {
        // Guarda os resultados no estado
        setState(() {
          _hasNewRecalculatedPlan = true;
          _newPlanId = result.newDietId;
          _lastRecalculationAnalysis = result.analysis;
        });

        widget.onRefresh(); // Recarrega os dados do dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRecalculatedPlanDialog() {
    if (_lastRecalculationAnalysis == null || _newPlanId == null) return;

    final plan = _lastRecalculationAnalysis!;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: AppThemes.glassColor.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: AppThemes.glassColor.withOpacity(0.2)),
            ),
            title: const Text('Plano Ajustado pela Dieta+'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.analysis,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const Divider(height: 24),
                  const Text('Refeições Restantes Sugeridas:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...plan.remainingMeals.map((meal) => Text('• ${meal.name}')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
              // BOTÃO PARA VER O PLANO COMPLETO
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) =>
                          DietPlanDetailScreen(dietPlanId: _newPlanId!),
                    ),
                  )
                      .then((_) {
                    // Reseta o estado da notificação
                    setState(() {
                      _hasNewRecalculatedPlan = false;
                      _newPlanId = null;
                      _lastRecalculationAnalysis = null;
                    });
                  });
                },
                child: const Text('Ver Plano Detalhado'),
              ),
            ],
          ),
        );
      },
    );
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
    final theme = Theme.of(context);
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
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: theme.textTheme.bodySmall?.color,
                        ),
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
    // Formata a data selecionada para um formato legível
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: const Color(0xFF2c2c2e).withOpacity(0.95),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            // Título do diálogo agora inclui a data
            title: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge,
                children: <TextSpan>[
                  const TextSpan(text: 'Adicionar Água\n'),
                  TextSpan(
                    text: 'em $formattedDate',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).unselectedWidgetColor,
                    ),
                  ),
                ],
              ),
            ),
            content: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade em ml'),
            ),
            actions: [
              TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(), // Usa o context do dialog
                  child: const Text('Cancelar')),
              TextButton(
                onPressed: () async {
                  final amount = int.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    // Fecha o diálogo ANTES de fazer a chamada de API
                    Navigator.of(context).pop();
                    try {
                      final token = await _storage.read(key: 'auth_token');
                      if (token == null) return;
                      await _apiService.addHydrationLog(
                        token: token,
                        amount: amount,
                        consumedAt: _selectedDate, // <-- PASSA A DATA
                      );
                      _reloadData(); // Recarrega os dados
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
          ),
        );
      },
    );
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
                      _reloadData();
                    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //final themeProvider = Provider.of<ThemeProvider>(context);
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
          // O ÍCONE AGORA CHAMA O DIÁLOGO DE ANÁLISE
          if (_hasNewRecalculatedPlan)
            IconButton(
              icon: const Icon(Icons.notifications_active,
                  color: Colors.yellowAccent),
              onPressed: _showRecalculatedPlanDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onRefresh,
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final summary = snapshot.data!.summary;
            final todaysMeals = snapshot.data!.todaysMeals;

            return RefreshIndicator(
              onRefresh: _reloadData,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Garante que o scroll sempre funcione
                child: Column(children: [
                  _buildHydrationCard(summary.hydration),
                  const SizedBox(height: 24),
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
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: theme.primaryColor,
                        dotColor: Colors.white24,
                      ),
                    ),
                  ),
                  Text(
                    "Refeições de ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color),
                  ),
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
                          _deleteMealLog(meal.id);
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
                                    builder: (context) => SuggestionScreen(
                                        foodName: meal.foodName),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                          .animate() // <-- Adiciona o gatilho da animação
                          .fadeIn(duration: 500.ms) // Efeito de fade-in
                          .slideY(
                              begin: 0.5,
                              end: 0); // Efeito de deslizar de baixo para cima
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: TextButton.icon(
                      // A CHAMADA AGORA É FEITA AQUI, COM OS DADOS JÁ CARREGADOS
                      onPressed: () => _handleOffPlanMeal(summary),
                      icon: const Icon(Icons.warning_amber_rounded, size: 20),
                      label: const Text('Refeição fora do plano?'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.yellow[700],
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  )
                ]),
              ),
            );
          }
          return const Center(child: Text('Nenhum dado encontrado.'));
        },
      ),
    );
  }

  Widget _buildChartPage(String title, AverageData data, AverageData targets,
      {int? dietId}) {
    final theme = Theme.of(context);
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
                        final style = TextStyle(
                            color: theme.textTheme.bodySmall?.color,
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
                      0, data.calories.toDouble(), theme.primaryColor),
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
            child: GestureDetector(
              onTapDown: (_) => _buttonAnimationController
                  .forward(), // Inicia a animação ao pressionar
              onTapUp: (_) => _buttonAnimationController
                  .reverse(), // Reverte a animação ao soltar
              onTapCancel: () => _buttonAnimationController
                  .reverse(), // Reverte se o toque for cancelado
              child: ElevatedButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (context) => LogMealScreen(
                            dietId: dietId!,
                            date: _selectedDate)), // <-- PASSA A DATA
                  );
                  if (result == true) {
                    _reloadData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  // Usando a cor de acento do tema ativo
                  backgroundColor: theme.primaryColor.withOpacity(0.3),
                  foregroundColor: theme.textTheme.bodyLarge?.color,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Registrar Refeição'),
              ).animate(controller: _buttonAnimationController).scale(
                    begin: const Offset(1, 1), // Tamanho inicial (100%)
                    end: const Offset(0.95, 0.95), // Tamanho final (95%)
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
