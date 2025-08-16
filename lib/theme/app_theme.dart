import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Classe auxiliar para agrupar os dados de um tema
class AppThemeOption {
  final String name;
  final ThemeData themeData;
  final BoxDecoration background;

  const AppThemeOption(
      {required this.name, required this.themeData, required this.background});
}

// Classe principal que contém todas as nossas opções de tema
class AppThemes {
  static const Color glassColor = Colors.white;
  // --- NOSSAS PALETAS DE CORES ---

  // Tema 1: Aurora Púrpura (o atual)
  static final AppThemeOption auroraPurpura = AppThemeOption(
    name: 'Aurora Púrpura',
    background: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    themeData: _buildTheme(
      accentColor: const Color(0xFFFFA07A), // Laranja Salmão Suave
      baseTheme: ThemeData.dark(),
    ),
  );

  // Tema 2: Floresta Vital
  static final AppThemeOption florestaVital = AppThemeOption(
    name: 'Floresta Vital',
    background: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF00467F),
          Color(0xFF079D7F)
        ], // Azul profundo e Verde mar
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    themeData: _buildTheme(
      accentColor: const Color(0xFF59E4A9), // Verde Menta
      baseTheme: ThemeData.dark(),
    ),
  );

  // Tema 3: Sol Poente (Tema Claro)
  static final AppThemeOption solPoente = AppThemeOption(
    name: 'Sol Poente',
    background: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFF7971E), Color(0xFFFFD200)], // Laranja e Amarelo
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    themeData: _buildTheme(
      accentColor: const Color(0xFF2c2c2c), // Quase preto para contraste
      baseTheme: ThemeData.light(),
      primaryTextColor: Colors.black87,
      secondaryTextColor: Colors.black54,
    ),
  );

  // Tema 4: Preto & Branco (Minimalista)
  static final AppThemeOption pretoEBranco = AppThemeOption(
    name: 'Preto & Branco',
    background: const BoxDecoration(
      color: Color(0xFF121212), // Fundo preto sólido
    ),
    themeData: _buildTheme(
      accentColor: Colors.white, // Acento branco
      baseTheme: ThemeData.dark(),
      primaryTextColor: Colors.white,
      secondaryTextColor: Colors.grey,
    ),
  );

  // --- LISTA E CONSTRUTOR ---

  // Lista de todos os temas disponíveis para a tela de seleção
  static final List<AppThemeOption> themeOptions = [
    auroraPurpura,
    florestaVital,
    solPoente,
    pretoEBranco,
  ];

  // Função auxiliar para construir o ThemeData e evitar repetição
  static ThemeData _buildTheme({
    required Color accentColor,
    required ThemeData baseTheme,
    Color primaryTextColor = Colors.white,
    Color secondaryTextColor = Colors.white70,
  }) {
    return baseTheme.copyWith(
      // Aplica a fonte Poppins a todos os estilos de texto
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme.apply(
        bodyColor: primaryTextColor,
        displayColor: primaryTextColor,
      )),
      primaryColor: accentColor,
      scaffoldBackgroundColor:
          Colors.transparent, // Essencial para o fundo funcionar

      unselectedWidgetColor: secondaryTextColor,
      // Esquema de cores principal
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: accentColor,
        secondary: accentColor,
        onPrimary: baseTheme.brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        onSurface: primaryTextColor,
      ),

      // Estilo da AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
            color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: primaryTextColor),
      ),

      // Estilo dos botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseTheme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.1),
          foregroundColor: primaryTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: baseTheme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
        ),
      ),

      // ... adicione aqui os outros estilos (inputDecorationTheme, dialogTheme, etc.) se precisar
    );
  }
}
