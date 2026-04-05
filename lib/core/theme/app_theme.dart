import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color primaryMain  = Color(0xFF6C4FF0); // rich violet
  static const Color primaryDark  = Color(0xFF3D1FC8);
  static const Color primaryLight = Color(0xFF9B7FFF);

  static const Color accentMain  = Color(0xFF00D4AA); // electric teal
  static const Color accentLight = Color(0xFF5EECD4);
  static const Color accentDark  = Color(0xFF009E7E);

  // Secondary accents
  static const Color coral  = Color(0xFFFF5252);
  static const Color amber  = Color(0xFFFFB547);
  static const Color rose   = Color(0xFFFF4081);
  static const Color indigo = Color(0xFF536DFE);

  // Score colors
  static const Color scoreExcellent = Color(0xFF00D4AA); // teal  85+
  static const Color scoreGood      = Color(0xFF536DFE); // indigo 70-84
  static const Color scoreOk        = Color(0xFFFFB547); // amber  55-69
  static const Color scorePoor      = Color(0xFFFF5252); // coral  <55

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color light        = Color(0xFFFFFFFF);
  static const Color scaffoldBg   = Color(0xFFF5F4FF);
  static const Color lightGrey    = Color(0xFFEEEDF8);
  static const Color mediumGrey   = Color(0xFFB0ADCF);
  static const Color darkGrey     = Color(0xFF4A4668);
  static const Color dark         = Color(0xFF1A1730);

  // ── Dark mode surfaces ─────────────────────────────────────────────────────
  static const Color darkBg          = Color(0xFF0F0D1A);
  static const Color darkSurface     = Color(0xFF1C1929);
  static const Color darkCard        = Color(0xFF241F38);
  static const Color darkCardLight   = Color(0xFF2E2845);
  static const Color darkBorder      = Color(0xFF3A3354);

  // Semantic
  static const Color success = Color(0xFF00D4AA);
  static const Color warning = amber;
  static const Color error   = coral;

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient purpleToTealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMain, accentMain],
  );

  static const LinearGradient purpleToPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMain, rose],
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C1232), Color(0xFF0F0D1A)],
  );

  static const LinearGradient scoreCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1F5E), Color(0xFF1A3A4A)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C4FF0), Color(0xFF00D4AA)],
    stops: [0.0, 1.0],
  );

  static LinearGradient get purpleGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryMain, primaryDark],
      );

  // ── Theme data ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme  => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryMain,
      scaffoldBackgroundColor: isDark ? darkBg : scaffoldBg,
      textTheme: _buildTextTheme(isDark),
      appBarTheme: _buildAppBarTheme(isDark),
      cardTheme: _buildCardTheme(isDark),
      inputDecorationTheme: _buildInputTheme(isDark),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryMain,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: primaryMain,
              secondary: accentMain,
              tertiary: rose,
              surface: darkSurface,
              error: error,
            )
          : const ColorScheme.light(
              primary: primaryMain,
              secondary: accentMain,
              tertiary: rose,
              surface: Colors.white,
              error: error,
            ),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final base  = GoogleFonts.plusJakartaSansTextTheme();
    final color = isDark ? Colors.white : dark;
    final muted = isDark ? const Color(0xFF9B97B8) : mediumGrey;
    return base.copyWith(
      displayLarge:  base.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w800, color: color),
      displayMedium: base.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: color),
      displaySmall:  base.displaySmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: color),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: color),
      headlineMedium:base.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: color),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleLarge:    base.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleMedium:   base.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      bodyLarge:     base.bodyLarge?.copyWith(fontSize: 16, color: color),
      bodyMedium:    base.bodyMedium?.copyWith(fontSize: 14, color: isDark ? const Color(0xFFCBC8E8) : darkGrey),
      bodySmall:     base.bodySmall?.copyWith(fontSize: 12, color: muted),
      labelLarge:    base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: color),
    );
  }

  static AppBarTheme _buildAppBarTheme(bool isDark) => AppBarTheme(
        backgroundColor: isDark ? darkBg : scaffoldBg,
        foregroundColor: isDark ? Colors.white : dark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : dark,
        ),
      );

  static CardThemeData _buildCardTheme(bool isDark) => CardThemeData(
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: isDark ? darkCard : Colors.white,
      );

  static InputDecorationTheme _buildInputTheme(bool isDark) => InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard : lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? darkBorder : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryMain, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? const Color(0xFF6B6890) : mediumGrey),
      );

  // ── Helpers ─────────────────────────────────────────────────────────────────
  static Color getScoreColor(double score) {
    if (score >= 85) return scoreExcellent;
    if (score >= 70) return scoreGood;
    if (score >= 55) return scoreOk;
    return scorePoor;
  }

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

  static LinearGradient scoreGradient(double score) {
    final c = getScoreColor(score);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.withValues(alpha: 0.8), c],
    );
  }

  /// Glassmorphism decoration — dark frosted card
  static BoxDecoration glassCard({
    double radius = 20,
    Color? borderColor,
    Color? bgColor,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: (bgColor ?? darkCard).withValues(alpha: 0.85),
        border: Border.all(
          color: (borderColor ?? darkBorder).withValues(alpha: 0.6),
          width: 1,
        ),
      );

  /// Premium gradient border decoration
  static BoxDecoration gradientBorderCard({double radius = 20}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: purpleToTealGradient,
      );
}
