import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  AppThemeOption _currentTheme;

  ThemeProvider() : _currentTheme = AppThemes.auroraPurpura {
    // Tema padrão
    _loadTheme();
  }

  AppThemeOption get currentTheme => _currentTheme;

  // Carrega o tema salvo no dispositivo
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme') ?? 'Aurora Púrpura';
    _currentTheme = AppThemes.themeOptions.firstWhere(
      (theme) => theme.name == themeName,
      orElse: () => AppThemes.auroraPurpura,
    );
    notifyListeners();
  }

  // Define um novo tema e o salva
  void setTheme(AppThemeOption theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
    notifyListeners();
  }
}
