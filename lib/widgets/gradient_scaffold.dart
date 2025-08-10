import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  // NOVOS PARÂMETROS ADICIONADOS AQUI
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    // E AQUI NO CONSTRUTOR
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camada 1: O Fundo
        Container(
          decoration: AppTheme.backgroundDecoration,
        ),
        // Camada 2: O Scaffold que agora recebe os novos parâmetros
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton, // <-- PARÂMETRO REPASSADO
          floatingActionButtonLocation:
              floatingActionButtonLocation, // <-- PARÂMETRO REPASSADO
        ),
      ],
    );
  }
}
