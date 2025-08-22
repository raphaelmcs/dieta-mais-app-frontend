import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_service.dart';
//import 'main_screen.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'onboarding_check_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _performLogin() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final authToken = await _apiService.login(
          _emailController.text,
          _passwordController.text,
        );
        await _storage.write(key: 'auth_token', value: authToken);

        await _setupNotifications(authToken);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const OnboardingCheckScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Erro: ${e.toString().replaceAll("Exception: ", "")}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setupNotifications(String authToken) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      try {
        await _apiService.sendDeviceToken(authToken, fcmToken);
      } catch (e) {
        print('Falha ao enviar token FCM para o backend: $e');
      }
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
          appBar: AppBar(
            centerTitle: true,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/logo_completa.png',
                      height: 150,
                    ),
                    const SizedBox(height: 48.0),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        // <-- 'const' adicionado
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Por favor, insira um email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        // <-- 'const' adicionado
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 48.0),
                    if (_isLoading)
                      CircularProgressIndicator(color: theme.primaryColor)
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppThemes.glassColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  width: 1.5,
                                  color: AppThemes.glassColor.withOpacity(0.2),
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: _performLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16.0),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text('Esqueci minha senha?'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Não tem uma conta?'),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            'Cadastre-se',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
