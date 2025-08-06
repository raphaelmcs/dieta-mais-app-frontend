import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart'; // 1. Importa nosso tema

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dieta+ App',
      theme: AppTheme.darkTheme, // 2. Aplica nosso tema customizado
      home: const SplashScreen(),
    );
  }
}
