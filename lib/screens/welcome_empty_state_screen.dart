import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import 'main_screen.dart';

class WelcomeEmptyStateScreen extends StatelessWidget {
  const WelcomeEmptyStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos um Consumer para que os círculos se atualizem ao selecionar um tema
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GradientScaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  const Icon(Icons.palette_outlined,
                      size: 80, color: Colors.white70),
                  const SizedBox(height: 24),
                  const Text(
                    'Personalize sua Experiência',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Escolha um tema visual para o seu aplicativo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Círculos de seleção de tema
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: AppThemes.themeOptions.map((themeOption) {
                      bool isSelected =
                          themeProvider.currentTheme.name == themeOption.name;
                      return GestureDetector(
                        onTap: () => themeProvider.setTheme(themeOption),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: (themeOption.background is BoxDecoration)
                                ? (themeOption.background as BoxDecoration)
                                    .gradient
                                : null,
                            color: (themeOption.background is BoxDecoration)
                                ? (themeOption.background as BoxDecoration)
                                    .color
                                : null,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          // Adiciona um checkmark no tema selecionado
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 28)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const Spacer(flex: 3),

                  const Text(
                    'A seguir, vamos configurar seu primeiro plano alimentar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),

                  // Botão para avançar para a criação do plano
                  ElevatedButton(
                    onPressed: () {
                      // Leva o usuário para a MainScreen, já na aba "Plano" (índice 1)
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) =>
                                const MainScreen(initialIndex: 1)),
                      );
                    },
                    child: const Text('Avançar'),
                  ),
                  const SizedBox(height: 16),

                  // Botão para pular esta etapa
                  TextButton(
                    onPressed: () {
                      // Leva o usuário para a MainScreen na aba padrão "Resumo" (índice 0)
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const MainScreen()),
                      );
                    },
                    child: const Text('Configurar Plano Depois'),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
