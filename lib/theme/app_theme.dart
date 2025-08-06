import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa o google_fonts

class AppTheme {
  // ... As cores continuam as mesmas ...
  static const Color accentColor = Color(0xFFFFA07A);
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Colors.white70;
  static const Color glassColor = Colors.white;
  static const BoxDecoration backgroundDecoration = BoxDecoration(/*...*/);

  static ThemeData get darkTheme {
    // Pega o tema escuro base do Flutter
    final baseTheme = ThemeData.dark();

    // Retorna o tema base com nossas customizações por cima
    return baseTheme.copyWith(
      // APLICA A FONTE POPPINS A TODOS OS ESTILOS DE TEXTO
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),

      primaryColor: accentColor,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
            color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: glassColor.withOpacity(0.25),
          foregroundColor: primaryTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: glassColor.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: secondaryTextColor),
        filled: true,
        fillColor: glassColor.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glassColor.withOpacity(0.5)),
        ),
      ),
      iconTheme: const IconThemeData(color: primaryTextColor),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor,
      ),
    );
  }
}
