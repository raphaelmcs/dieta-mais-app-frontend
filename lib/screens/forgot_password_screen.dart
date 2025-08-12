import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../api/api_service.dart';
import '../widgets/gradient_scaffold.dart';
import 'reset_password_screen.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;
  final _phoneController = TextEditingController();

  final phoneMaskFormatter = MaskTextInputFormatter(
      mask: '+## (##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final identifier = '+${phoneMaskFormatter.getUnmaskedText()}';
      try {
        final message =
            await _apiService.forgotPassword(identifier: identifier);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(identifier: identifier),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro: ${e.toString()}'),
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
    return GradientScaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Digite seu telefone cadastrado para receber um código de recuperação via SMS.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 16, color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                inputFormatters: [phoneMaskFormatter],
                decoration:
                    const InputDecoration(labelText: 'Telefone (ex: +5511...)'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.accentColor)
              else
                SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.glassColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            width: 1.5,
                            color: AppTheme.glassColor.withOpacity(0.2),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _sendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Enviar Código',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
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
