import 'package:dieta_mais_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa o provider
import '../theme/app_theme.dart';

class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar; // <-- NOVO PARÂMETRO ADICIONADO

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar, // <-- E AQUI NO CONSTRUTOR
  });

  @override
  Widget build(BuildContext context) {
    // Pega o fundo do tema ativo através do Provider
    final background =
        Provider.of<ThemeProvider>(context).currentTheme.background;

    return Stack(
      children: [
        Container(decoration: background), // Usa o fundo dinâmico
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar, // <-- PARÂMETRO REPASSADO
        ),
      ],
    );
  }
}
