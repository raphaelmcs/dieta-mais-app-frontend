import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    // A lógica do Stack que estávamos repetindo agora vive em um único lugar!
    return Stack(
      children: [
        // Camada 1: O Fundo
        Container(
          decoration: AppTheme.backgroundDecoration,
        ),
        // Camada 2: O Scaffold transparente com o conteúdo que passamos
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
        ),
      ],
    );
  }
}
