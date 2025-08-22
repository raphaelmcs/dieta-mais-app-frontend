import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

//import 'onboarding_check_screen.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'main_screen.dart'; // O destino principal
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // Lógica simplificada: se tem token, vai para MainScreen. Senão, vai para Login.
  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (token != null) {
      // Se está logado, vai direto para a tela boas vindas
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Se não está logado, vai para a tela de login
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        Provider.of<ThemeProvider>(context).currentTheme.background;
    return Stack(
      children: [
        Container(decoration: background),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppThemes.glassColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppThemes.glassColor.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
