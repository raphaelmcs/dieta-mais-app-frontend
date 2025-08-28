import 'dart:ui';
import 'package:dieta_mais_app/models/dashboard_data.dart';
import 'package:dieta_mais_app/models/diet_plan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/gradient_scaffold.dart';
import 'dashboard/dashboard_screen.dart';
import 'meal_plan_screen.dart';
import 'workout/workout_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  // O estado do Dashboard e dos Planos vive aqui
  Future<DashboardData>? _dashboardDataFuture;
  Future<List<DietPlan>>? _plansFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final pagesCount = 4;
    _selectedIndex = widget.initialIndex.clamp(0, pagesCount - 1);
    _reloadData();
    _loadPlans();
  }

  // Função para recarregar os dados do Dashboard
  void _reloadData({DateTime? newDate}) async {
    if (newDate != null) {
      setState(() {
        _selectedDate = newDate;
      });
    }
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;
    setState(() {
      _dashboardDataFuture = _apiService.getDashboardData(token, _selectedDate);
    });
  }

  // Função para recarregar a lista de Planos
  void _loadPlans() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;
    setState(() {
      _plansFuture = _apiService.getDietPlans(token);
    });
  }

  // Função central para quando um plano é alterado
  void _onDietPlanChanged() {
    _reloadData(); // Recarrega o Dashboard
    _loadPlans(); // Recarrega a lista de planos
    // Se o usuário não estiver no Dashboard, o leva para lá
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) _reloadData(); // Sempre recarrega o dashboard ao entrar
    if (index == 1) _loadPlans(); // Sempre recarrega os planos ao entrar
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> widgetOptions = <Widget>[
      DashboardScreen(
        key: ValueKey('dashboard-${_selectedDate.toIso8601String()}'),
        selectedDate: _selectedDate,
        onPlanCreated: _loadPlans,
        dashboardDataFuture: _dashboardDataFuture,
        onRefresh: _reloadData,
        onDateSelected: (date) => _reloadData(newDate: date),
      ),
      MealPlanScreen(
        key: ValueKey('plans-${_plansFuture.hashCode}'),
        plansFuture: _plansFuture,
        onRefresh: _loadPlans,
        onDietPlanChanged: _onDietPlanChanged,
      ),
      const WorkoutScreen(), // <-- nova aba Treino
      const ReportsScreen(),
      //const ProfileScreen(),
    ];

    return GradientScaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppThemes.glassColor.withOpacity(0.15),
              border: Border(
                top: BorderSide(
                  color: AppThemes.glassColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: theme.primaryColor,
              unselectedItemColor: theme.unselectedWidgetColor,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_filled), label: 'Resumo'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.restaurant_menu), label: 'Plano'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center),
                    label: 'Treino'), // <-- novo
                BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart), label: 'Relatórios'),
                /*  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline), label: 'Perfil'), */
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            ),
          ),
        ),
      ),
    );
  }
}
