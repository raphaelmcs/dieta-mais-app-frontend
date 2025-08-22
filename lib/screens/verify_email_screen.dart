import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _apiService = ApiService();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  int _cooldownSec = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    setState(() => _cooldownSec = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldownSec <= 1) {
        t.cancel();
        setState(() => _cooldownSec = 0);
      } else {
        setState(() => _cooldownSec -= 1);
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite os 6 dígitos do código.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.verifyEmailCode(
        email: widget.email.trim().toLowerCase(),
        code: code,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verificado com sucesso! Faça login.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_cooldownSec > 0) return;
    try {
      await _apiService.resendEmailCode(
          email: widget.email.trim().toLowerCase());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Novo código enviado!'),
          backgroundColor: Colors.green,
        ),
      );
      _startCooldown(60); // cooldown de 60s
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  PinTheme _pinThemeBase(
      Color glass, double opacity, double borderOpacity, double width) {
    return PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: glass.withOpacity(opacity),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: glass.withOpacity(borderOpacity), width: width),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = AppThemes.glassColor;

    final defaultPinTheme = _pinThemeBase(glass, 0.15, 0.30, 1.5);
    final focusedPinTheme = _pinThemeBase(glass, 0.25, 0.60, 2.0);
    final submittedPinTheme = _pinThemeBase(glass, 0.35, 0.80, 2.0);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Verificar Email')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  size: 72, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                "Enviamos um código de 6 dígitos para:",
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.email,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // PINput (6 caixinhas)
              Pinput(
                length: 6,
                controller: _codeController,
                keyboardType: TextInputType.number,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                showCursor: true,
                onCompleted: (_) {
                  // opcional: chamar automaticamente quando completar 6 dígitos
                  _verifyCode();
                },
              ),

              const SizedBox(height: 28),

              if (_isLoading)
                CircularProgressIndicator(color: theme.primaryColor)
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: glass.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  width: 1.5, color: glass.withOpacity(0.2)),
                            ),
                            child: ElevatedButton(
                              onPressed: _verifyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Verificar Código',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _cooldownSec == 0 ? _resendCode : null,
                      child: Text(
                        _cooldownSec == 0
                            ? 'Não recebeu? Reenviar código'
                            : 'Reenviar em $_cooldownSec s',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
