import 'dart:ui';
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return GradientScaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.palette_outlined, size: 72, color: cs.onSurface.withOpacity(.85)),
                        const SizedBox(height: 16),
                        Text(
                          'Personalize sua Experiência',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Escolha um tema visual para o seu aplicativo.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Círculos de seleção de tema
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: AppThemes.themeOptions.map((themeOption) {
                            final isSelected = themeProvider.currentTheme.name == themeOption.name;
                            final deco = (themeOption.background is BoxDecoration)
                                ? themeOption.background as BoxDecoration
                                : const BoxDecoration();
                            return GestureDetector(
                              onTap: () => themeProvider.setTheme(themeOption),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: isSelected ? 58 : 52,
                                height: isSelected ? 58 : 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: deco.gradient,
                                  color: deco.color,
                                  border: Border.all(
                                    color: isSelected ? cs.primary : Colors.white.withOpacity(0.25),
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: cs.primary.withOpacity(.35),
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 28),
                        Divider(color: Colors.white.withOpacity(.08)),
                        const SizedBox(height: 16),

                        Text(
                          'A seguir, vamos configurar seu primeiro plano alimentar.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),

                        // Botão primário com gradiente (consistente com o projeto)
                        _PrimaryGradientButton(
                          label: 'Avançar',
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(initialIndex: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Botão de texto secundário
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const MainScreen()),
                            );
                          },
                          child: const Text('Configurar Plano Depois'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card “glass” local (não depende de outros widgets)
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: cs.surface.withOpacity(0.12),
            border: Border.all(color: Colors.white.withOpacity(.18), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.10),
                Colors.white.withOpacity(.04),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Botão primário com gradiente que respeita o tema atual
class _PrimaryGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryGradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cs.primary,
        cs.secondary,
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
