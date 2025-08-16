import 'package:dieta_mais_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'main_screen.dart'; // <-- MUDANÇA: Importa a nova tela principal
import 'package:provider/provider.dart'; // Importa o provider
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

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    if (token != null) {
      Navigator.of(context).pushReplacement(
          // ***** MUDANÇA AQUI *****
          MaterialPageRoute(builder: (context) => const MainScreen()));
    } else {
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
