import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart'; // A importação continua a mesma, mas o uso muda
import '../widgets/gradient_scaffold.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmationController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final token = await _storage.read(key: 'auth_token');
        if (token == null) throw Exception('Token não encontrado');

        final successMessage = await _apiService.changePassword(
          token: token,
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          newPasswordConfirmation: _newPasswordConfirmationController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(successMessage), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(); // Volta para a tela de Perfil
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o Theme.of(context) para pegar as cores do tema ativo
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Alterar Senha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(labelText: 'Senha Atual'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                    labelText: 'Nova Senha (mínimo 8 caracteres)'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 8)
                    ? 'A senha deve ter no mínimo 8 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordConfirmationController,
                decoration:
                    const InputDecoration(labelText: 'Confirmar Nova Senha'),
                obscureText: true,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                CircularProgressIndicator(
                    color:
                        theme.primaryColor) // Usa a cor de acento do tema ativo
              else
                SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.15), // Efeito de vidro é constante
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            width: 1.5,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _submitChangePassword,
                          child: const Text('Salvar Nova Senha'),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
