import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color primaryMain = Color(0xFF534AB7);
  static const Color primaryDark = Color(0xFF26215C);

  // Accent colors
  static const Color accentMain = Color(0xFF1D9E75);
  static const Color accentLight = Color(0xFF5DCAA5);

  // Secondary accents
  static const Color coral = Color(0xFFD85A30);
  static const Color amber = Color(0xFFEF9F27);

  // Score colors
  static const Color scoreExcellent = accentMain; // Teal for 85+
  static const Color scoreGood = Color(0xFF2196F3); // Blue for 70-84
  static const Color scoreOk = amber; // Amber for 55-69
  static const Color scorePoor = coral; // Coral for <55

  // Neutral colors
  static const Color light = Color(0xFFFAFAFA);
  static const Color scaffoldBg = Color(0xFFF6F6FA); // Home screen background
  static const Color lightGrey = Color(0xFFF0F0F0);
  static const Color mediumGrey = Color(0xFFBDBDBD);
  static const Color darkGrey = Color(0xFF424242);
  static const Color dark = Color(0xFF212121);

  // Success, warning, error
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = amber;
  static const Color error = coral;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryMain,
      scaffoldBackgroundColor: light,
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      buttonTheme: _buildButtonTheme(),
      floatingActionButtonTheme: _buildFABTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      colorScheme: const ColorScheme.light(
        primary: primaryMain,
        secondary: accentMain,
        tertiary: coral,
        surface: Colors.white,
        error: error,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: dark,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: dark,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: dark,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: dark,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: dark,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: dark,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: dark,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        color: dark,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        color: darkGrey,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        color: mediumGrey,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: primaryMain,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  static ButtonThemeData _buildButtonTheme() {
    return ButtonThemeData(
      buttonColor: primaryMain,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFABTheme() {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryMain,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryMain,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: mediumGrey,
      ),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
    );
  }

  /// Get score color based on score value
  static Color getScoreColor(double score) {
    if (score >= 85) return scoreExcellent;
    if (score >= 70) return scoreGood;
    if (score >= 55) return scoreOk;
    return scorePoor;
  }

  /// Get letter grade based on score
  static String getLetterGrade(double score) {
    if (score >= 95) return 'S';
    if (score >= 90) return 'A+';
    if (score >= 85) return 'A';
    if (score >= 80) return 'B+';
    if (score >= 75) return 'B';
    if (score >= 70) return 'C+';
    if (score >= 65) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  /// Create a gradient from purple to teal
  static LinearGradient get purpleToTealGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryMain, accentMain],
    );
  }

  /// Create a purple gradient
  static LinearGradient get purpleGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryMain, primaryDark],
    );
  }
}
