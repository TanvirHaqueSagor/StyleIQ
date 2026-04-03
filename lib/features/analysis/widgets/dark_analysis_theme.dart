import 'package:flutter/material.dart';

/// Color system and shared helpers for the dark premium analysis screen.
abstract class DarkAnalysisTheme {
  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0a0a0f);
  static const Color surface = Color(0xFF141420);
  static const Color surfaceElevated = Color(0xFF1c1c2e);
  static const Color surfaceHighlight = Color(0xFF252538);

  // ── Accent palette ───────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFd4a853);
  static const Color teal = Color(0xFF4ecdc4);
  static const Color violet = Color(0xFF9b7fe6);
  static const Color rose = Color(0xFFe06b7a);
  static const Color blue = Color(0xFF5b9cf5);

  // ── Typography ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFf0f0f0);
  static const Color textSecondary = Color(0xFFa0a0b8);
  static const Color textMuted = Color(0xFF606080);

  // ── Borders ──────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF252538);
  static const Color borderAccent = Color(0xFF3a3a58);

  // ── Score-aware color ─────────────────────────────────────────────────────────
  static Color scoreColor(double score) {
    if (score >= 85) return teal;
    if (score >= 70) return blue;
    if (score >= 55) return gold;
    return rose;
  }
}
