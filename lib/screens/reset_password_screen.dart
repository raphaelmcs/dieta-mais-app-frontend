import 'package:flutter/material.dart';
import 'dart:ui';
import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String identifier; // Recebe o telefone da tela anterior

  const ResetPasswordScreen({super.key, required this.identifier});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  late final TextEditingController _identifierController;
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(text: widget.identifier);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submitResetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final message = await _apiService.resetPassword(
          identifier: _identifierController.text, // Envia o telefone
          token: _tokenController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Erro: ${e.toString().replaceAll("Exception: ", "")}'),
                backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(title: const Text('Redefinir Senha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                readOnly: true, // Campo desabilitado
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenController,
                decoration:
                    const InputDecoration(labelText: 'Código de 6 dígitos'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'Nova Senha (mínimo 8 caracteres)'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 8)
                    ? 'A senha deve ter no mínimo 8 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordConfirmationController,
                decoration:
                    const InputDecoration(labelText: 'Confirmar Nova Senha'),
                obscureText: true,
                validator: (v) {
                  if (v != _passwordController.text)
                    return 'As senhas não coincidem';
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
                          onPressed: _submitResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Salvar Nova Senha',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
