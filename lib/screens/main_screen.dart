import 'dart:ui'; // Import necessário para o ImageFilter
import 'package:dieta_mais_app/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'meal_plan_screen.dart';
import 'profile_screen.dart';
// import 'reports_screen.dart'; // Futura tela de relatórios
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    MealPlanScreen(),
    ReportsScreen(), // Placeholder
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o GradientScaffold para ter o fundo correto
    return GradientScaffold(
      // O body do nosso scaffold principal é a tela selecionada
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      // E aqui está a nossa barra de navegação customizada
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassColor.withOpacity(0.15),
              border: Border(
                top: BorderSide(
                  color: AppTheme.glassColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color.fromARGB(255, 179, 117, 92),
              unselectedItemColor: AppTheme.secondaryTextColor,
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
              type: BottomNavigationBarType
                  .fixed, // Garante que todos os itens apareçam
            ),
          ),
        ),
      ),
    );
  }
}
