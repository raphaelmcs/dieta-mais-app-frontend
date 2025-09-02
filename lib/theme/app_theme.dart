// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ===============================================================
/// OPÇÕES DE TEMA (com gradiente e Poppins)
/// + componentes: Inputs, Snackbars, Dialogs, Cards, Toggles
/// ===============================================================

class AppThemeOption {
  final String name;
  final ThemeData themeData;
  final BoxDecoration background;

  const AppThemeOption({
    required this.name,
    required this.themeData,
    required this.background,
  });
}

class AppThemes {
  static const Color glassColor = Colors.white;

  // Tema 1: Aurora Púrpura (escuro)
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
      accentColor: const Color(0xFFFFA07A),
      baseTheme: ThemeData.dark(),
    ),
  );

  // Tema 2: Floresta Vital (escuro)
  static final AppThemeOption florestaVital = AppThemeOption(
    name: 'Floresta Vital',
    background: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF00467F), Color(0xFF079D7F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    themeData: _buildTheme(
      accentColor: const Color(0xFF59E4A9),
      baseTheme: ThemeData.dark(),
    ),
  );

  // Tema 3: Sol Poente (claro)
  static final AppThemeOption solPoente = AppThemeOption(
    name: 'Sol Poente',
    background: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    themeData: _buildTheme(
      accentColor: const Color(0xFF2c2c2c),
      baseTheme: ThemeData.light(),
      primaryTextColor: Colors.black87,
      secondaryTextColor: Colors.black54,
    ),
  );

  // Tema 4: Preto & Branco (escuro minimalista)
  static final AppThemeOption pretoEBranco = AppThemeOption(
    name: 'Preto & Branco',
    background: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF2E2E2E), Color(0xFF1A1A1A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    themeData: _buildTheme(
      accentColor: Colors.white,
      baseTheme: ThemeData.dark(),
      primaryTextColor: Colors.white,
      secondaryTextColor: Colors.grey,
    ),
  );

  // Lista para seleção
  static final List<AppThemeOption> themeOptions = [
    auroraPurpura,
    florestaVital,
    solPoente,
    pretoEBranco,
  ];

  // Construtor de ThemeData com “glass” e componentes coerentes
  static ThemeData _buildTheme({
    required Color accentColor,
    required ThemeData baseTheme,
    Color primaryTextColor = Colors.white,
    Color secondaryTextColor = Colors.white70,
  }) {
    final isDark = baseTheme.brightness == Brightness.dark;
    final onPrimary = isDark ? Colors.black : Colors.white;

    final textTheme = GoogleFonts.poppinsTextTheme(
      baseTheme.textTheme.apply(
        bodyColor: primaryTextColor,
        displayColor: primaryTextColor,
      ),
    );

    // Inputs (glass)
    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
      labelStyle: textTheme.bodyMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.15),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.18)
              : Colors.black.withOpacity(0.18),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );

    // SnackBar (floating)
    final snackBarTheme = SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? Colors.black.withOpacity(0.85)
          : Colors.grey.shade900.withOpacity(0.92),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
    );

    // Dialog (glass)
    final dialogTheme = DialogThemeData(
      backgroundColor: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.06),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle:
          textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      contentTextStyle: textTheme.bodyMedium,
    );

    // Card (glass)
    final cardTheme = CardThemeData(
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.06),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(8),
    );

    // Botões
    final elevatedButtons = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.1),
        foregroundColor: primaryTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
    );

    final outlinedButtons = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryTextColor,
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.35)
              : Colors.black.withOpacity(0.35),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );

    // Toggles (Checkbox/Radio/Switch) com acento coerente
    final checkboxTheme = CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: MaterialStateBorderSide.resolveWith((states) {
        final color = states.contains(MaterialState.selected)
            ? accentColor
            : (isDark ? Colors.white70 : Colors.black54);
        return BorderSide(color: color, width: 1.4);
      }),
      fillColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? accentColor
            : Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(onPrimary),
    );

    final radioTheme = RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? accentColor
            : (isDark ? Colors.white70 : Colors.black54);
      }),
    );

    final switchTheme = SwitchThemeData(
      trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      trackColor: MaterialStateProperty.resolveWith((states) {
        final sel = states.contains(MaterialState.selected);
        return sel
            ? accentColor.withOpacity(0.45)
            : (isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.12));
      }),
      thumbColor: MaterialStateProperty.resolveWith((states) {
        final sel = states.contains(MaterialState.selected);
        return sel ? accentColor : (isDark ? Colors.white70 : Colors.black54);
      }),
    );

    return baseTheme.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent, // p/ gradiente do fundo

      primaryColor: accentColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: accentColor,
        secondary: accentColor,
        onPrimary: onPrimary,
        onSurface: primaryTextColor,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: primaryTextColor),
      ),

      elevatedButtonTheme: elevatedButtons,
      outlinedButtonTheme: outlinedButtons,
      inputDecorationTheme: inputDecorationTheme,
      snackBarTheme: snackBarTheme,
      dialogTheme: dialogTheme,
      cardTheme: cardTheme,
      checkboxTheme: checkboxTheme,
      radioTheme: radioTheme,
      switchTheme: switchTheme,
    );
  }
}

/// ===============================================================
/// CLASSE UTILITÁRIA: AppTheme (estilos de texto usados nas telas)
/// ===============================================================
class AppTheme {
  static final TextStyle titleStyle = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle subtitleStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static final TextStyle sectionTitleStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle cardTitleStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
