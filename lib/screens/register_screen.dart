import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  String? _fullPhoneNumber;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _performRegister() async {
    // Valida o formulário antes de continuar
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.register(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _fullPhoneNumber, // 3. Passa o número completo para a API
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Usuário registrado com sucesso! Por favor, faça o login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
        appBar: AppBar(title: const Text('Criar Conta')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(),
                    ),
                  ),
                  initialCountryCode: 'BR', // Define o Brasil como padrão
                  languageCode: 'pt_BR', // Deixa a lista de países em português
                  onChanged: (phone) {
                    // Guarda o número completo (ex: +5511987654321) na nossa variável
                    _fullPhoneNumber = phone.completeNumber;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      labelText: 'Senha (mínimo 8 caracteres)'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 8)
                      ? 'A senha deve ter no mínimo 8 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordConfirmationController,
                  decoration:
                      const InputDecoration(labelText: 'Confirmar Senha'),
                  obscureText: true,
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  CircularProgressIndicator(color: theme.primaryColor)
                else
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      // Para arredondar as bordas do efeito
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
                            onPressed: _performRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Registrar',
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
              ],
            ),
          ),
        ));
  }
}
