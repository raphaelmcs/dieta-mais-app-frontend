import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'dashboard_screen.dart';
import 'meal_plan_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import '../api/api_service.dart';
import '../models/dashboard_data.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/gradient_scaffold.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  // A lógica de dados do Dashboard agora vive aqui!
  Future<DashboardData>? _dashboardDataFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;
    setState(() {
      _dashboardDataFuture = _apiService.getDashboardData(token, _selectedDate);
    });
  }

  void _onDateSelected(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _reloadData();
    });
  }

  void _onItemTapped(int index) {
    // Se o usuário clicar na aba "Resumo", recarrega os dados
    if (index == 0) {
      _reloadData();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onDietActivated() {
    // Apenas recarrega os dados do dashboard em segundo plano para quando o usuário voltar lá.
    // A linha que mudava de aba foi removida.
    _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> widgetOptions = <Widget>[
      DashboardScreen(
        dashboardDataFuture: _dashboardDataFuture,
        onRefresh: _reloadData,
        onSelectDate: (date) async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            locale: const Locale('pt', 'BR'),
          );
          if (picked != null) {
            _onDateSelected(picked);
          }
        },
        selectedDate: _selectedDate,
      ),
      MealPlanScreen(onDietActivated: _onDietActivated),
      const ReportsScreen(),
      const ProfileScreen(),
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
                  icon: Icon(Icons.home_filled),
                  label: 'Resumo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Plano',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Relatórios',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Perfil',
                ),
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
