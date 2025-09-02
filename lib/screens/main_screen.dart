// lib/screens/main_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/gradient_scaffold.dart';

// Modelos
import 'package:dieta_mais_app/models/dashboard_data.dart';
import 'package:dieta_mais_app/models/diet_plan.dart';

// Telas
import 'dashboard/dashboard_screen.dart';
import 'meal_plan_screen.dart';
import 'food/food_photo_screen.dart';
import 'reports_screen.dart';
// import 'profile_screen.dart'; // Perfil segue acessível pela Dashboard (canto superior direito), se a sua Dashboard já faz isso

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

  // Estado do Dashboard e dos Planos
  Future<DashboardData>? _dashboardDataFuture;
  Future<List<DietPlan>>? _plansFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final pagesCount = 4; // Dashboard, Plano, Foto do Prato, Relatórios
    _selectedIndex = widget.initialIndex.clamp(0, pagesCount - 1);
    _reloadData();
    _loadPlans();
  }

  // Recarrega dados do Dashboard
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

  // Recarrega lista de Planos
  void _loadPlans() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;
    setState(() {
      _plansFuture = _apiService.getDietPlans(token);
    });
  }

  // Ação central quando um plano é criado/alterado/ativado/excluído
  void _onDietPlanChanged() {
    _reloadData(); // Atualiza Dashboard
    _loadPlans(); // Atualiza lista de planos
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0; // volta para Dashboard
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) _reloadData(); // sempre recarrega o Dashboard ao entrar
    if (index == 1) _loadPlans(); // sempre recarrega os planos ao entrar
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> pages = <Widget>[
      // DASHBOARD
      DashboardScreen(
        key: ValueKey('dashboard-${_selectedDate.toIso8601String()}'),
        selectedDate: _selectedDate,
        onPlanCreated: _loadPlans,
        dashboardDataFuture: _dashboardDataFuture,
        onRefresh: _reloadData,
        onDateSelected: (date) => _reloadData(newDate: date),
      ),

      // PLANO ALIMENTAR
      MealPlanScreen(
        key: ValueKey('plans-${_plansFuture.hashCode}'),
        plansFuture: _plansFuture,
        onRefresh: _loadPlans,
        onDietPlanChanged: _onDietPlanChanged,
      ),

      // FOTO DO PRATO (substitui "Treino")
      const FoodPhotoScreen(),

      // RELATÓRIOS
      const ReportsScreen(),
    ];

    return GradientScaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
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
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: 'Resumo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Plano',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_enhance_outlined),
                  label: 'Foto',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Relatórios',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
