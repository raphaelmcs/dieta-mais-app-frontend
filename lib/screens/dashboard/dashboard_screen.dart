import 'package:dieta_mais_app/models/daily_summary.dart';
import 'package:dieta_mais_app/models/meal_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

// Imports dos novos widgets que criamos
import 'widgets/charts_pageview.dart';
import 'widgets/hydration_card.dart';
import 'widgets/meal_list_view.dart';

import '../../widgets/glass_dialog.dart'; // onde está o showGlassDialog
import '../../widgets/glassmorphic_container.dart'; // já usado pelo helper

import '../../screens/profile_screen.dart';
import '../login_screen.dart';
import '../../api/api_service.dart';
import '../../models/dashboard_data.dart';
import '../../models/recalculated_diet.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../log_meal_screen.dart';
import '../diet_plan_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Future<DashboardData>? dashboardDataFuture;
  final VoidCallback onRefresh;
  final VoidCallback onPlanCreated;
  final Function(DateTime) onDateSelected;
  final DateTime selectedDate;

  const DashboardScreen({
    super.key,
    required this.dashboardDataFuture,
    required this.onRefresh,
    required this.onPlanCreated,
    required this.onDateSelected,
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
  late final AnimationController _buttonAnimationController;
  Future<DashboardData>? _dashboardDataFuture;
  DateTime _selectedDate = DateTime.now();

  // Variáveis para a notificação de plano recalculado
  bool _hasNewRecalculatedPlan = false;
  int? _newPlanId;
  RecalculatedDiet? _lastRecalculationAnalysis;

  @override
  void initState() {
    super.initState();
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

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.dashboardDataFuture != widget.dashboardDataFuture) {
      _reloadData();
    }
  }

  // A lógica de carregar dados, recarregar, deletar, etc., continua aqui,
  // pois é o "cérebro" desta tela.
  Future<DashboardData> _loadDashboardData(DateTime date) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      _performLogout(context);
      throw Exception('Token não encontrado');
    }

    final results = await Future.wait([
      _apiService.getDailySummary(token, date),
      _apiService.getMealsForDate(token, date),
    ]);

    // A CORREÇÃO ESTÁ AQUI:
    return DashboardData(
      summary: results[0] as DailySummary, // Especificamos o tipo
      todaysMeals: results[1] as List<MealLog>, // Especificamos o tipo
    );
  }

  void _reloadData() {
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
    DateTime tempSelectedDate = _selectedDate;

    final picked = await showGlassDialog<DateTime>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecionar data',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              width: 320,
              height: 380,
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                onDateChanged: (date) => tempSelectedDate = date,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(tempSelectedDate),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dashboardDataFuture = _loadDashboardData(picked);
      });
    }
  }

  void _handleAddWater(DailySummary summary) async {
    // Se não tem plano ativo e a meta é 0, peça para definir a meta primeiro (uma única vez)
    if ((summary.hasActiveDiet == false) && (summary.hydration.goal == 0)) {
      final shouldSetGoal = await showGlassDialog<bool>(
        context: context,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Definir meta de hidratação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              const Text(
                'Você ainda não tem um plano ativo. '
                'Para acompanhar seu progresso de água, defina uma meta diária (em ml).',
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('Depois'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    child: const Text('Definir agora'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (shouldSetGoal == true) {
        // Abre o diálogo de meta já existente
        _showUpdateGoalDialog(2000); // sugestão inicial de 2000 ml
        return;
      }
      // Mesmo que escolha "Depois", ainda pode registrar água
      _showAddWaterDialog();
      return;
    }

    // Caso normal
    _showAddWaterDialog();
  }

// A lógica de Recálculo agora recebe os dados necessários como parâmetros
  Future<void> _handleOffPlanMeal(DailySummary summary) async {
    if (summary.dietId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Você precisa de um plano ativo para usar esta função.')),
      );
      return;
    }

    final mealWasLogged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            LogMealScreen(dietId: summary.dietId!, date: _selectedDate),
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
            content: Text('Aguarde, o Dieta+ está recalculando seu dia...')),
      );

      final result = await _apiService.recalculateDiet(token);

      if (mounted) {
        setState(() {
          _hasNewRecalculatedPlan = true;
          _newPlanId = result.newDietId;
          _lastRecalculationAnalysis = result.analysis;
        });

        // ***** A CORREÇÃO ESTÁ AQUI *****
        // Em vez de chamar apenas onRefresh, chamamos a função que atualiza TUDO.
        widget.onPlanCreated();
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

  // ***** 3. MÉTODO PARA O DIÁLOGO DE ADICIONAR ÁGUA RESTAURADO *****
  void _showAddWaterDialog() {
    final amountController = TextEditingController();
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    showGlassDialog<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
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
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade em ml'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      Navigator.of(context)
                          .pop(); // fecha o dialog antes da chamada
                      try {
                        final token = await _storage.read(key: 'auth_token');
                        if (token == null) return;
                        await _apiService.addHydrationLog(
                          token: token,
                          amount: amount,
                          consumedAt: _selectedDate,
                        );
                        _reloadData();
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
          ],
        ),
      ),
    );
  }

  void _showUpdateGoalDialog(int currentGoal) {
    final goalController = TextEditingController(text: currentGoal.toString());

    showGlassDialog<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alterar Meta de Hidratação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nova meta em ml'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final goal = int.tryParse(goalController.text);
                    if (goal != null && goal > 0) {
                      try {
                        final token = await _storage.read(key: 'auth_token');
                        if (token == null) return;
                        await _apiService.updateHydrationGoal(token, goal);
                        if (mounted) Navigator.of(context).pop();
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(
        leadingWidth: 150,
        leading: GestureDetector(
          onTap: () => _selectDate(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 8),
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
          if (_hasNewRecalculatedPlan)
            IconButton(
              icon: const Icon(Icons.notifications_active,
                  color: Colors.yellowAccent),
              onPressed: _showRecalculatedPlanDialog,
            ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.2),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reloadData(),
        child: FutureBuilder<DashboardData>(
          future: _dashboardDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            if (snapshot.hasData) {
              final summary = snapshot.data!.summary;
              final todaysMeals = snapshot.data!.todaysMeals;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 1. CHAMA O WIDGET DO CARD DE HIDRATAÇÃO
                    HydrationCard(
                      hydration: summary.hydration,
                      onAddWater: () => _handleAddWater(summary), // <--- aqui
                      onUpdateGoal: () =>
                          _showUpdateGoalDialog(summary.hydration.goal),
                      gradient: _getHydrationGradient(
                        (summary.hydration.goal > 0)
                            ? (summary.hydration.consumed /
                                summary.hydration.goal)
                            : 0.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 2. CHAMA O WIDGET DO CARROSSEL DE GRÁFICOS
                    ChartsPageView(
                      pageController: _pageController,
                      summary: summary,
                      buttonAnimationController: _buttonAnimationController,
                      onMealLogged: _reloadData,
                      selectedDate: _selectedDate,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Refeições de ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 8),
                    // 3. CHAMA O WIDGET DA LISTA DE REFEIÇÕES
                    MealListView(
                      meals: todaysMeals,
                      onDelete: _deleteMealLog,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextButton.icon(
                        onPressed: () => _handleOffPlanMeal(summary),
                        icon: const Icon(Icons.warning_amber_rounded, size: 20),
                        label: const Text('Refeição fora do plano?'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.yellow[700],
                        ),
                      ),
                    )
                  ],
                ),
              );
            }
            return const Center(child: Text('Nenhum dado encontrado.'));
          },
        ),
      ),
    );
  }
}
