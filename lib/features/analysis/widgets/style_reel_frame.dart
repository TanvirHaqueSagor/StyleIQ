import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/widgets/dark_analysis_theme.dart';

/// A single frame of the StyleIQ animated reel, rendered at time [t] (0.0–1.0).
///
/// All animation is driven by [t], making this a pure stateless widget
/// suitable for off-screen frame capture via screenshot package.
class StyleReelFrame extends StatelessWidget {
  final StyleAnalysis analysis;
  final Uint8List? imageBytes;
  final double t; // 0.0 → 1.0

  const StyleReelFrame({
    super.key,
    required this.analysis,
    required this.imageBytes,
    required this.t,
  });

  // Smooth ease-in-out interpolation
  double _ease(double x) =>
      x < 0.5 ? 2 * x * x : -1 + (4 - 2 * x) * x;

  // Returns 0.0–1.0 for a window starting at [start], lasting [dur] of total t range
  double _show(double start, double dur) =>
      _ease(((t - start) / dur).clamp(0.0, 1.0));

  LinearGradient _gradeGradient(String grade) {
    if (grade == 'S') {
      return const LinearGradient(
          colors: [Color(0xFFffd700), Color(0xFFff8c00)]);
    }
    if (grade.startsWith('A')) {
      return const LinearGradient(
          colors: [Color(0xFF4ecdc4), Color(0xFF44a08d)]);
    }
    if (grade.startsWith('B')) {
      return const LinearGradient(
          colors: [Color(0xFF5b9cf5), Color(0xFF667eea)]);
    }
    return const LinearGradient(
        colors: [Color(0xFFe06b7a), Color(0xFFf5576c)]);
  }

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    final dims = a.dimensions;

    final photoO     = _show(0.00, 0.30);
    final ringP      = _show(0.00, 0.55);
    final gradeO     = _show(0.35, 0.20);
    final headlineO  = _show(0.45, 0.20);
    final hSlide     = (1.0 - headlineO) * 8.0;
    final barFills   = List.generate(5, (i) => _show(0.55 + i * 0.05, 0.15));
    final brandO     = _show(0.82, 0.18);

    final dimData = [
      ('COLOR',    dims.colorHarmony.score,    DarkAnalysisTheme.gold),
      ('FIT',      dims.fitProportion.score,   DarkAnalysisTheme.teal),
      ('OCCASION', dims.occasionMatch.score,   DarkAnalysisTheme.violet),
      ('TREND',    dims.trendAlignment.score,  DarkAnalysisTheme.rose),
      ('STYLE',    dims.styleCohesion.score,   DarkAnalysisTheme.blue),
    ];

    return Container(
      width: 360,
      height: 640,
      decoration: const BoxDecoration(color: DarkAnalysisTheme.bg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'StyleIQ',
                  style: GoogleFonts.playfairDisplay(
                    color: DarkAnalysisTheme.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: DarkAnalysisTheme.gold.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AI STYLE ANALYSIS',
                    style: TextStyle(
                      color: DarkAnalysisTheme.gold.withValues(alpha: 0.8),
                      fontSize: 8,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Photo ────────────────────────────────────────────────────────
            Opacity(
              opacity: photoO,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: imageBytes != null
                      ? Image.memory(imageBytes!, fit: BoxFit.cover)
                      : const ColoredBox(
                          color: DarkAnalysisTheme.surface,
                          child: Center(
                            child: Icon(Icons.checkroom,
                                color: DarkAnalysisTheme.textMuted, size: 48),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Grade + score ────────────────────────────────────────────────
            Opacity(
              opacity: gradeO,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: _gradeGradient(a.letterGrade),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a.letterGrade,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${a.overallScore.round()}',
                    style: GoogleFonts.playfairDisplay(
                      color: DarkAnalysisTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    ' /100',
                    style: GoogleFonts.dmSans(
                      color: DarkAnalysisTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      value: (a.overallScore / 100) * ringP,
                      strokeWidth: 4,
                      backgroundColor: DarkAnalysisTheme.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          DarkAnalysisTheme.gold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Headline ─────────────────────────────────────────────────────
            Transform.translate(
              offset: Offset(0, hSlide),
              child: Opacity(
                opacity: headlineO,
                child: Text(
                  a.headline,
                  style: GoogleFonts.dmSans(
                    color: DarkAnalysisTheme.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Dimension bars ───────────────────────────────────────────────
            ...List.generate(5, (i) {
              final label = dimData[i].$1;
              final score = dimData[i].$2;
              final color = dimData[i].$3;
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: DarkAnalysisTheme.textMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (score / 100) * barFills[i],
                          backgroundColor: DarkAnalysisTheme.border,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${score.round()}',
                        style: GoogleFonts.jetBrainsMono(
                          color: DarkAnalysisTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Spacer(),

            // ── Footer branding ──────────────────────────────────────────────
            Opacity(
              opacity: brandO,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 1,
                      color: DarkAnalysisTheme.gold.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Analyzed by StyleIQ AI',
                      style: TextStyle(
                        color: DarkAnalysisTheme.textMuted,
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 16,
                      height: 1,
                      color: DarkAnalysisTheme.gold.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
