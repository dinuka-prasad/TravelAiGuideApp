// ─────────────────────────────────────────────
// App Colour & Theme Tokens — Sri Lankan Tropical
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  static bool isDarkGlobal = false;

  ThemeMode get themeMode => isDarkGlobal ? ThemeMode.dark : ThemeMode.light;
  bool get isDarkMode => isDarkGlobal;

  void toggleTheme(bool isOn) {
    isDarkGlobal = isOn;
    notifyListeners();
  }
}

class AppColors {
  static bool get isDark => ThemeProvider.isDarkGlobal;

  // Primary palette — Tropical Green
  static Color get primary => isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32); // Green 800 / Green 400
  static Color get primaryLight => isDark ? const Color(0xFF81C784) : const Color(0xFF66BB6A); // Green 400
  static Color get primaryDark => isDark ? const Color(0xFF1B5E20) : const Color(0xFF1B5E20); // Green 900
  static Color get primarySurface => isDark ? const Color(0xFF263228) : const Color(0xFFE8F5E9); // Green 50

  // Accent — Sunset Orange / Warm Gold
  static Color get accent => const Color(0xFFFF8F00); // Amber 800
  static Color get accentLight => const Color(0xFFFFB300); // Amber 600
  static Color get accentDark => const Color(0xFFFF6F00); // Amber 900

  // Secondary - Ocean Blue
  static Color get oceanBlue => const Color(0xFF0288D1); // Light Blue 700

  // Neutral
  static Color get background => isDark ? const Color(0xFF141A15) : const Color(0xFFFAF2EC); // Very soft warm sunset peach tint
  static Color get surface => isDark ? const Color(0xFF1F2620) : Colors.white;
  static Color get cardBg => isDark ? const Color(0xFF1F2620) : const Color(0xFFFFFFFF);

  // Text
  static Color get textPrimary => isDark ? Colors.white : const Color(0xFF1B1B1B); // Near black
  static Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF4B554B); // Muted green-grey
  static Color get textHint => isDark ? Colors.white38 : const Color(0xFFA0AAB0);

  // Status
  static Color get success => const Color(0xFF00C853);
  static Color get error => const Color(0xFFFF1744);
  static Color get warning => const Color(0xFFFFAB00);

  // Gradients
  static LinearGradient get primaryGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF1B5E20)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        );

  static LinearGradient get heroGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC1B5E20), Color(0xFF121B13)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC2E7D32), Color(0xFF1B5E20)],
        );

  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.light,
      primary: const Color(0xFF2E7D32),
      onPrimary: Colors.white,
      secondary: const Color(0xFFFF8F00),
      onSecondary: Colors.white,
      surface: Colors.white,
      error: const Color(0xFFFF1744),
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFFFAF2EC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1B1B1B),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF1B1B1B),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF2E7D32),
      unselectedItemColor: Color(0xFFB0B0C0),
      elevation: 20,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
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
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF66BB6A),
      brightness: Brightness.dark,
      primary: const Color(0xFF66BB6A),
      onPrimary: Colors.black,
      secondary: const Color(0xFFFF8F00),
      onSecondary: Colors.black,
      surface: const Color(0xFF1F2620),
      error: const Color(0xFFFF1744),
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFF141A15),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1F2620),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF141A15),
      selectedItemColor: Color(0xFF66BB6A),
      unselectedItemColor: Color(0xFF708070),
      elevation: 20,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF262F27),
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
        borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}
