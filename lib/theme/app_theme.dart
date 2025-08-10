import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores Base da Paleta "Aurora Púrpura"
  static const Color accentColor = Color(0xFFFFA07A); // Laranja Salmão Suave
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Colors.white70;
  static const Color glassColor = Colors.white;

  // Fundo Gradiente, inspirado na imagem
  static const BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFF3A1C71), // Roxo Profundo
        Color(0xFFD76D77), // Rosa Queimado
        Color(0xFFFFAF7B), // Laranja Pêssego
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Tema Escuro Completo
  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    return baseTheme.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      primaryColor: accentColor,
      // Essencial: Fundo do Scaffold é transparente para o gradiente aparecer
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
            color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      elevatedButtonTheme:
          ElevatedButtonThemeData(/* ... seu estilo de botão ... */),
      inputDecorationTheme:
          InputDecorationTheme(/* ... seu estilo de input ... */),
      iconTheme: const IconThemeData(color: primaryTextColor),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor,
      ),
    );
  }
}
