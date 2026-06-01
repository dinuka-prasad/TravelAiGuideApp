// ─────────────────────────────────────────────
// App Colour & Theme Tokens — Sri Lankan Tropical
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — Tropical Green
  static const Color primary = Color(0xFF2E7D32); // Green 800
  static const Color primaryLight = Color(0xFF66BB6A); // Green 400
  static const Color primaryDark = Color(0xFF1B5E20); // Green 900
  static const Color primarySurface = Color(0xFFE8F5E9); // Green 50

  // Accent — Sunset Orange / Warm Gold
  static const Color accent = Color(0xFFFF8F00); // Amber 800
  static const Color accentLight = Color(0xFFFFB300); // Amber 600
  static const Color accentDark = Color(0xFFFF6F00); // Amber 900

  // Secondary - Ocean Blue
  static const Color oceanBlue = Color(0xFF0288D1); // Light Blue 700

  // Neutral
  static const Color background = Color(0xFFFBFDF9); // Very light greenish-white tint
  static const Color surface = Colors.white;
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1B1B1B); // Near black
  static const Color textSecondary = Color(0xFF4B554B); // Muted green-grey
  static const Color textHint = Color(0xFFA0AAB0);

  // Status
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFFAB00);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC2E7D32), Color(0xFF1B5E20)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFFB0B0C0),
      elevation: 20,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}
