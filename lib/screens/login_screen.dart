import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 1. Importa o Firebase Messaging
import '../api/api_service.dart';
import 'main_screen.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
//import '../widgets/gradient_scaffold.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

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
      setState(() {
        _isLoading = true;
      });

      try {
        final authToken = await _apiService.login(
          _emailController.text,
          _passwordController.text,
        );

        await _storage.write(key: 'auth_token', value: authToken);

        // ***** LÓGICA DE NOTIFICAÇÃO ADICIONADA AQUI *****
        await _setupNotifications(authToken);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 2. Novo método para configurar as notificações
  Future<void> _setupNotifications(String authToken) async {
    // Pede permissão ao usuário
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Pega o token FCM do dispositivo
    final fcmToken = await messaging.getToken();

    if (fcmToken != null) {
      print(
          '<<<<< FCM Token: $fcmToken >>>>>'); // Para vermos o token no console
      try {
        // Envia o token para o nosso backend
        await _apiService.sendDeviceToken(authToken, fcmToken);
      } catch (e) {
        // Se falhar, apenas mostra um erro no console, não impede o login
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
            //title: const Text('Dieta+ App'),
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
                      height: 150, // Ajuste a altura como preferir
                    ),
                    const SizedBox(height: 48.0), // Espaçamento
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
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
                        // NAVEGA PARA A TELA DE ESQUECI A SENHA
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'Esqueci minha senha?',
                        style:
                            TextStyle(color: theme.textTheme.bodySmall?.color),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem uma conta?',
                          style: TextStyle(
                              color: theme.textTheme.bodySmall?.color),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navega para a tela de registro
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Cadastre-se',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 242, 196, 245),
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
