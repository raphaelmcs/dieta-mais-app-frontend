import 'dart:ui'; // 1. Importa o dart:ui para o ImageFilter
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../theme/app_theme.dart';
import 'meal_plan_screen.dart';
import 'profile_screen.dart';

// Importe os placeholders para as futuras telas
// import 'meal_plan_screen.dart';
// import 'profile_screen.dart';

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
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camada 1: O Fundo do App
        Container(
          decoration: AppTheme.backgroundDecoration,
        ),
        // Camada 2: O Conteúdo
        Scaffold(
          backgroundColor: Colors.transparent,
          body: _widgetOptions.elementAt(_selectedIndex),
          // 2. A barra de navegação agora é envolvida pelo efeito de vidro
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
                  backgroundColor:
                      Colors.transparent, // Essencial para o efeito
                  elevation: 0, // Remove a sombra
                  selectedItemColor: AppTheme.accentColor,
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
                      icon: Icon(Icons.person_outline),
                      label: 'Perfil',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
