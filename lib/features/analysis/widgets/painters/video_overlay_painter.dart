import 'dart:math';
import 'package:flutter/material.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/widgets/dark_analysis_theme.dart';

/// Paints all animated overlay phases on top of the outfit photo.
/// Driven entirely by [elapsedSeconds] (0.0–20.0) — fully stateless.
class StyleVideoPainter extends CustomPainter {
  final double elapsedSeconds;
  final StyleAnalysis analysis;

  const StyleVideoPainter({
    required this.elapsedSeconds,
    required this.analysis,
  });

  // ── Phase boundaries ──────────────────────────────────────────────────────
  static const _phases = [
    (start: 0.0,  end: 2.0),   // 0: Intro
    (start: 2.0,  end: 5.5),   // 1: Color
    (start: 5.5,  end: 8.5),   // 2: Fit
    (start: 8.5,  end: 11.0),  // 3: Occasion
    (start: 11.0, end: 13.5),  // 4: Trend
    (start: 13.5, end: 16.0),  // 5: Cohesion
    (start: 16.0, end: 20.0),  // 6: Reveal
  ];

  // ── Easing ────────────────────────────────────────────────────────────────
  static double _easeOut(double t) {
    final c = 1.0 - t;
    return 1.0 - c * c * c;
  }

  static double _bounce(double t) {
    const n1 = 7.5625, d1 = 2.75;
    if (t < 1 / d1) return n1 * t * t;
    if (t < 2 / d1) { final tt = t - 1.5 / d1; return n1 * tt * tt + 0.75; }
    if (t < 2.5 / d1) { final tt = t - 2.25 / d1; return n1 * tt * tt + 0.9375; }
    final tt = t - 2.625 / d1; return n1 * tt * tt + 0.984375;
  }

  // Opacity for a phase with 0.3s cross-dissolve at each end
  double _phaseOpacity(int phase) {
    const td = 0.3;
    final p = _phases[phase];
    if (elapsedSeconds <= p.start || elapsedSeconds >= p.end) return 0;
    final fadeIn  = ((elapsedSeconds - p.start) / td).clamp(0.0, 1.0);
    final fadeOut = ((p.end - elapsedSeconds) / td).clamp(0.0, 1.0);
    return min(fadeIn, fadeOut);
  }

  // Progress within a phase (0→1)
  double _phaseProgress(int phase) {
    final p = _phases[phase];
    return ((elapsedSeconds - p.start) / (p.end - p.start)).clamp(0.0, 1.0);
  }

  // ── Garment zone mapping ──────────────────────────────────────────────────
  // Returns up to 4 zones as {label: Rect} using standard body proportions
  Map<String, Rect> _garmentZones(Size sz) {
    final zones = <String, Rect>{};
    final items = analysis.detectedItems;
    for (int i = 0; i < items.length && zones.length < 4; i++) {
      final item = items[i].toLowerCase();
      if (!zones.containsKey('top') &&
          ['blazer','shirt','top','jacket','coat','sweater','hoodie','tee','blouse','dress'].any(item.contains)) {
        zones[items[i]] = Rect.fromLTWH(sz.width * 0.15, sz.height * 0.20, sz.width * 0.70, sz.height * 0.32);
      } else if (!zones.containsKey('bottom') &&
          ['jeans','pant','trouser','skirt','short','legging'].any(item.contains)) {
        zones[items[i]] = Rect.fromLTWH(sz.width * 0.20, sz.height * 0.50, sz.width * 0.60, sz.height * 0.30);
      } else if (!zones.containsKey('shoes') &&
          ['shoe','boot','sneaker','heel','sandal','loafer'].any(item.contains)) {
        zones[items[i]] = Rect.fromLTWH(sz.width * 0.25, sz.height * 0.80, sz.width * 0.50, sz.height * 0.15);
      } else if (!zones.containsKey('acc') &&
          ['bag','hat','watch','belt','scarf','glasses','necklace','earring'].any(item.contains)) {
        zones[items[i]] = Rect.fromLTWH(sz.width * 0.60, sz.height * 0.40, sz.width * 0.25, sz.height * 0.15);
      }
    }
    // Fallbacks if no items matched
    if (zones.isEmpty) {
      zones['Top']    = Rect.fromLTWH(sz.width * 0.15, sz.height * 0.20, sz.width * 0.70, sz.height * 0.30);
      zones['Bottom'] = Rect.fromLTWH(sz.width * 0.20, sz.height * 0.52, sz.width * 0.60, sz.height * 0.28);
    }
    return zones;
  }

  // Zone colors corresponding to dimension colors
  static const _zoneColors = [
    DarkAnalysisTheme.gold,
    DarkAnalysisTheme.teal,
    DarkAnalysisTheme.violet,
    DarkAnalysisTheme.rose,
  ];

  // ── Text drawing helper ───────────────────────────────────────────────────
  void _drawText(
    Canvas canvas,
    String text,
    Offset pos, {
    double fontSize = 12,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w500,
    bool italic = false,
    TextAlign align = TextAlign.left,
    double maxWidth = 300,
    bool shadow = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: weight,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          shadows: shadow
              ? const [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1))]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: maxWidth);

    Offset drawPos;
    if (align == TextAlign.center) {
      drawPos = Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2);
    } else if (align == TextAlign.right) {
      drawPos = Offset(pos.dx - tp.width, pos.dy);
    } else {
      drawPos = pos;
    }
    tp.paint(canvas, drawPos);
  }

  // ── Dimension label banner ────────────────────────────────────────────────
  void _drawDimensionLabel(
    Canvas canvas, Size size, double slideProgress,
    String label, double score, Color color, double opacity,
  ) {
    final slide = _easeOut(slideProgress.clamp(0.0, 1.0));
    final x = -size.width * 0.5 * (1 - slide);
    final y = size.height * 0.06;

    canvas.save();
    canvas.translate(x, 0);

    // Background pill
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, y, 180, 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.6 * opacity),
    );
    // Left accent stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(12, y, 3, 24), const Radius.circular(2)),
      Paint()..color = color.withValues(alpha: opacity),
    );

    _drawText(canvas, label,
      Offset(22, y + 5),
      fontSize: 9, color: color.withValues(alpha: opacity),
      weight: FontWeight.w800,
    );
    _drawText(canvas, '${score.round()}/100',
      Offset(160, y + 5),
      fontSize: 9, color: Colors.white.withValues(alpha: 0.8 * opacity),
      weight: FontWeight.w600,
    );

    canvas.restore();
  }

  // ── Dashed line helper ────────────────────────────────────────────────────
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {double dashLen = 6, double gapLen = 4, double drawProgress = 1.0}) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final total = sqrt(dx * dx + dy * dy);
    final drawLen = total * drawProgress.clamp(0.0, 1.0);
    final nx = dx / total, ny = dy / total;
    double dist = 0;
    bool drawing = true;
    while (dist < drawLen) {
      final segLen = drawing ? min(dashLen, drawLen - dist) : gapLen;
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + nx * dist, start.dy + ny * dist),
          Offset(start.dx + nx * (dist + segLen), start.dy + ny * (dist + segLen)),
          paint,
        );
      }
      dist += segLen;
      drawing = !drawing;
    }
  }

  // ── Typewriter text ───────────────────────────────────────────────────────
  void _drawTypewriterText(
    Canvas canvas, Size size, String text, double elapsed,
    {double x = 0, double y = 0, double cps = 18}
  ) {
    final chars = (elapsed * cps).round().clamp(0, text.length);
    if (chars == 0) return;
    final visible = text.substring(0, chars);
    final showCursor = (elapsed * 2).round() % 2 == 0;
    final full = showCursor ? '$visible|' : visible;

    _drawText(canvas, full,
      Offset(x, y),
      fontSize: 10,
      color: Colors.white.withValues(alpha: 0.7),
      maxWidth: size.width - 24,
      shadow: true,
    );
  }

  // ── Vignette ──────────────────────────────────────────────────────────────
  void _drawVignette(Canvas canvas, Size sz, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.6 * opacity),
        ],
      ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, sz.width, sz.height), paint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN PAINT
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void paint(Canvas canvas, Size size) {
    final t = elapsedSeconds;

    // Always draw vignette when animation has started
    if (t > 0) {
      _drawVignette(canvas, size, min(t / 1.0, 1.0));
    }

    // Phase 0: Intro
    final op0 = _phaseOpacity(0);
    if (op0 > 0) _renderPhase0(canvas, size, op0);

    // Phase 1: Color Harmony
    final op1 = _phaseOpacity(1);
    if (op1 > 0) _renderPhase1(canvas, size, op1);

    // Phase 2: Fit & Proportion
    final op2 = _phaseOpacity(2);
    if (op2 > 0) _renderPhase2(canvas, size, op2);

    // Phase 3: Occasion Match
    final op3 = _phaseOpacity(3);
    if (op3 > 0) _renderPhase3(canvas, size, op3);

    // Phase 4: Trend Alignment
    final op4 = _phaseOpacity(4);
    if (op4 > 0) _renderPhase4(canvas, size, op4);

    // Phase 5: Style Cohesion
    final op5 = _phaseOpacity(5);
    if (op5 > 0) _renderPhase5(canvas, size, op5);

    // Phase 6: Score Reveal
    final op6 = _phaseOpacity(6);
    if (op6 > 0) _renderPhase6(canvas, size, op6);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 0: INTRO (0-2s)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderPhase0(Canvas canvas, Size size, double opacity) {
    final progress = _phaseProgress(0);
    final t = elapsedSeconds;

    // Scan line sweeps top to bottom over 1.5s
    final scanP = (t / 1.5).clamp(0.0, 1.0);
    if (scanP < 1.0) {
      final scanY = scanP * size.height;
      canvas.drawLine(
        Offset(0, scanY), Offset(size.width, scanY),
        Paint()
          ..color = DarkAnalysisTheme.gold.withValues(alpha: 0.35 * opacity)
          ..strokeWidth = 2,
      );
      // Glow below scan line
      final glowPaint = Paint()
        ..color = DarkAnalysisTheme.gold.withValues(alpha: 0.08 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), glowPaint);
    }

    // Sparkle particles (10, drift upward)
    final rng = Random(42);
    for (int i = 0; i < 10; i++) {
      final baseX = 0.2 + rng.nextDouble() * 0.6;
      final speed  = 0.3 + rng.nextDouble() * 0.4;
      final py = 0.55 - speed * progress;
      if (py < 0.05 || py > 0.95) continue;
      final px = baseX + sin(t * 2 + i) * 0.03;
      final particleOpacity = max(0.0, 1.0 - progress * 1.5) * opacity;
      canvas.drawCircle(
        Offset(px * size.width, py * size.height),
        1.5 + rng.nextDouble(),
        Paint()..color = DarkAnalysisTheme.gold.withValues(alpha: 0.35 * particleOpacity),
      );
    }

    // "Analyzing your style..." text — fades in at 0.5s, out at 1.8s
    if (t >= 0.5 && t <= 1.8) {
      final textOpacity = (t < 0.8 ? (t - 0.5) / 0.3 : (1.8 - t) / 0.3).clamp(0.0, 1.0) * opacity;
      _drawText(canvas, 'Analyzing your style...',
        Offset(size.width / 2, size.height * 0.84),
        fontSize: 13, color: Colors.white.withValues(alpha: 0.85 * textOpacity),
        weight: FontWeight.w500, align: TextAlign.center, shadow: true,
      );
    }

    // Item labels flash at 1.5s
    if (t >= 1.5 && t <= 1.9) {
      final flashOp = ((1.9 - t) / 0.4).clamp(0.0, 1.0) * opacity;
      final items = analysis.detectedItems.take(4).toList();
      final positions = [
        Offset(size.width * 0.5,  size.height * 0.28),  // torso area
        Offset(size.width * 0.5,  size.height * 0.62),  // leg area
        Offset(size.width * 0.5,  size.height * 0.85),  // feet
        Offset(size.width * 0.75, size.height * 0.45),  // accessory
      ];
      for (int i = 0; i < min(items.length, 4); i++) {
        _drawText(canvas, items[i],
          positions[i],
          fontSize: 10,
          color: Colors.white.withValues(alpha: flashOp),
          weight: FontWeight.w600,
          align: TextAlign.center, shadow: true,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 1: COLOR HARMONY (2-5.5s)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderPhase1(Canvas canvas, Size size, double opacity) {
    final progress = _phaseProgress(1);
    final localT = elapsedSeconds - 2.0;

    // Dimension label
    _drawDimensionLabel(canvas, size, progress * 2, 'COLOR HARMONY',
        analysis.dimensions.colorHarmony.score,
        DarkAnalysisTheme.gold, opacity);

    // Garment zone colored overlays
    final zones = _garmentZones(size);
    int zi = 0;
    for (final entry in zones.entries) {
      final zoneColor = _zoneColors[zi % _zoneColors.length];
      // Stagger pulse: each zone starts 0.2s after previous
      final zoneProgress = ((localT - zi * 0.2) / 0.5).clamp(0.0, 1.0);
      if (zoneProgress <= 0) { zi++; continue; }
      // Pulse opacity between 0.15 and 0.30
      final pulse = 0.15 + 0.15 * (0.5 + 0.5 * sin(localT * 2 * pi / 0.8 + zi));
      final r = entry.value;
      // Soft fill
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()..color = zoneColor.withValues(alpha: pulse * opacity * zoneProgress),
      );
      // 2px border
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()
          ..color = zoneColor.withValues(alpha: 0.6 * opacity * zoneProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // Zone label
      _drawText(canvas, entry.key,
        Offset(r.left + 6, r.top + 4),
        fontSize: 8, color: Colors.white.withValues(alpha: 0.8 * opacity * zoneProgress),
        weight: FontWeight.w600, shadow: true,
      );
      zi++;
    }

    // Palette swatches at bottom (slide in from left, staggered)
    final paletteColors = [
      DarkAnalysisTheme.gold, DarkAnalysisTheme.teal,
      DarkAnalysisTheme.blue, DarkAnalysisTheme.violet, DarkAnalysisTheme.rose,
    ];
    for (int i = 0; i < 4; i++) {
      final swatchP = ((localT - 0.5 - i * 0.15) / 0.3).clamp(0.0, 1.0);
      if (swatchP <= 0) continue;
      final slideX = _easeOut(swatchP);
      final sx = (12.0 + i * 44.0) * slideX;
      final sy = size.height * 0.88;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sx, sy, 38, 20), const Radius.circular(5)),
        Paint()..color = paletteColors[i].withValues(alpha: opacity * swatchP),
      );
    }

    // Mini color wheel top-right
    final wheelProgress = (localT / 1.5).clamp(0.0, 1.0);
    if (wheelProgress > 0) {
      final cx = size.width - 30, cy = 30.0;
      canvas.drawCircle(
        Offset(cx, cy), 22,
        Paint()
          ..color = DarkAnalysisTheme.surfaceElevated.withValues(alpha: 0.7 * opacity)
          ..style = PaintingStyle.fill,
      );
      // Draw color wheel segments
      for (int i = 0; i < 6; i++) {
        final angle = (i / 6) * 2 * pi - pi / 2;
        final segColor = HSVColor.fromAHSV(1, i * 60.0, 0.7, 0.9).toColor();
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: 18),
          angle, pi / 3,
          false,
          Paint()
            ..color = segColor.withValues(alpha: 0.8 * opacity * wheelProgress)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7,
        );
      }
      _drawText(canvas, 'Palette',
        Offset(cx, cy + 28),
        fontSize: 7, color: DarkAnalysisTheme.textMuted.withValues(alpha: opacity),
        align: TextAlign.center,
      );
    }

    // AI comment typewriter
    final comment = analysis.dimensions.colorHarmony.comment;
    if (localT > 1.0 && comment.isNotEmpty) {
      _drawTypewriterText(canvas, size, comment, localT - 1.0,
        x: 12, y: size.height * 0.78);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 2: FIT & PROPORTION (5.5-8.5s)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderPhase2(Canvas canvas, Size size, double opacity) {
    final progress = _phaseProgress(2);
    final localT = elapsedSeconds - 5.5;

    _drawDimensionLabel(canvas, size, progress * 2, 'FIT & PROPORTION',
        analysis.dimensions.fitProportion.score,
        DarkAnalysisTheme.teal, opacity);

    // Silhouette glow on sides (simplified as edge glow)
    final glowProgress = (localT / 1.0).clamp(0.0, 1.0);
    if (glowProgress > 0) {
      final glowH = size.height * glowProgress;
      // Left edge glow
      final leftPaint = Paint()
        ..shader = LinearGradient(
          colors: [DarkAnalysisTheme.teal.withValues(alpha: 0.4 * opacity), Colors.transparent],
          begin: Alignment.centerLeft, end: Alignment.center,
        ).createShader(Rect.fromLTWH(0, 0, size.width * 0.12, glowH))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.08, glowH), leftPaint);
      // Right edge glow
      final rightPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, DarkAnalysisTheme.teal.withValues(alpha: 0.4 * opacity)],
          begin: Alignment.center, end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(size.width * 0.88, 0, size.width * 0.12, glowH));
      canvas.drawRect(Rect.fromLTWH(size.width * 0.92, 0, size.width * 0.08, glowH), rightPaint);
    }

    // Proportion guide lines (shoulder, waist, hip)
    final lineData = [
      (y: 0.30, label: 'Shoulders', delay: 0.4),
      (y: 0.52, label: 'Waist',     delay: 0.6),
      (y: 0.66, label: 'Hips',      delay: 0.8),
    ];
    for (final d in lineData) {
      final lineP = ((localT - d.delay) / 0.5).clamp(0.0, 1.0);
      if (lineP <= 0) continue;
      final lineProgress = _easeOut(lineP);
      final y = size.height * d.y;
      _drawDashedLine(
        canvas,
        Offset(size.width * 0.08, y), Offset(size.width * 0.92, y),
        Paint()
          ..color = DarkAnalysisTheme.teal.withValues(alpha: 0.7 * opacity)
          ..strokeWidth = 1.5,
        drawProgress: lineProgress,
      );
      if (lineProgress > 0.9) {
        _drawText(canvas, d.label,
          Offset(size.width * 0.93, y - 5),
          fontSize: 8, color: DarkAnalysisTheme.teal.withValues(alpha: opacity),
          weight: FontWeight.w600, shadow: true,
        );
      }
    }

    // Balance indicator (slides in from right)
    final balanceP = ((localT - 1.2) / 0.5).clamp(0.0, 1.0);
    if (balanceP > 0) {
      final slideIn = _easeOut(balanceP);
      final barW = 140.0, barX = size.width - 12 - barW * slideIn;
      final barY = size.height * 0.90;
      // Background
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW, 22), const Radius.circular(11)),
        Paint()..color = Colors.black.withValues(alpha: 0.55 * opacity),
      );
      // Labels
      _drawText(canvas, 'Fitted',
        Offset(barX + 8, barY + 5),
        fontSize: 8, color: DarkAnalysisTheme.teal.withValues(alpha: opacity),
        weight: FontWeight.w600,
      );
      _drawText(canvas, 'Relaxed',
        Offset(barX + barW - 8, barY + 5),
        fontSize: 8, color: DarkAnalysisTheme.textSecondary.withValues(alpha: opacity),
        weight: FontWeight.w600, align: TextAlign.right,
      );
      // Marker dot at 45% (mid-fitted)
      final markerX = barX + barW * 0.45;
      canvas.drawCircle(
        Offset(markerX, barY + 11),
        5, Paint()..color = DarkAnalysisTheme.teal.withValues(alpha: opacity),
      );
    }

    // AI comment
    final comment = analysis.dimensions.fitProportion.comment;
    if (localT > 1.5 && comment.isNotEmpty) {
      _drawTypewriterText(canvas, size, comment, localT - 1.5,
        x: 12, y: size.height * 0.78);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 3: OCCASION MATCH (8.5-11s)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderPhase3(Canvas canvas, Size size, double opacity) {
    final progress = _phaseProgress(3);
    final localT = elapsedSeconds - 8.5;

    _drawDimensionLabel(canvas, size, progress * 2, 'OCCASION MATCH',
        analysis.dimensions.occasionMatch.score,
        DarkAnalysisTheme.violet, opacity);

    // Extra dark overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.25 * opacity),
    );

    // Occasion badge stamp
    final badgeP = ((localT - 0.3) / 0.4).clamp(0.0, 1.0);
    if (badgeP > 0) {
      final scale = 1.0 + 0.5 * _bounce(1 - badgeP); // spring down from 1.5 to 1.0
      final rotation = -0.087 * (1 - badgeP); // -5deg to 0
      final badgeText = analysis.aestheticCategory?.toUpperCase() ?? 'SMART CASUAL';
      final cx = size.width / 2, cy = size.height * 0.42;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rotation);
      canvas.scale(scale);
      canvas.translate(-cx, -cy);

      const bw = 160.0, bh = 32.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bw / 2, cy - bh / 2, bw, bh),
          const Radius.circular(8)),
        Paint()..color = DarkAnalysisTheme.violet.withValues(alpha: 0.85 * opacity),
      );
      _drawText(canvas, badgeText,
        Offset(cx, cy - 6),
        fontSize: 12, color: Colors.white.withValues(alpha: opacity),
        weight: FontWeight.w800, align: TextAlign.center, shadow: true,
      );
      canvas.restore();
    }

    // Formality meter
    final meterP = ((localT - 0.8) / 0.8).clamp(0.0, 1.0);
    if (meterP > 0) {
      const mw = 160.0, mh = 6.0;
      final mx = size.width / 2 - mw / 2;
      final my = size.height * 0.52;
      // Track
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(mx, my, mw, mh), const Radius.circular(3)),
        Paint()..color = DarkAnalysisTheme.border.withValues(alpha: opacity),
      );
      // Fill (animate to 60% position)
      final fillW = mw * 0.60 * _easeOut(meterP);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(mx, my, fillW, mh), const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF22c55e), DarkAnalysisTheme.violet],
          ).createShader(const Rect.fromLTWH(0, 0, mw, mh)),
      );
      // Labels
      _drawText(canvas, 'Casual', Offset(mx, my + 10),
        fontSize: 7, color: DarkAnalysisTheme.textMuted.withValues(alpha: opacity), weight: FontWeight.w600);
      _drawText(canvas, 'Black Tie', Offset(mx + mw, my + 10),
        fontSize: 7, color: DarkAnalysisTheme.textMuted.withValues(alpha: opacity),
        weight: FontWeight.w600, align: TextAlign.right);
    }

    // Setting tag bottom-left
    final tagP = ((localT - 1.5) / 0.4).clamp(0.0, 1.0);
    if (tagP > 0) {
      _drawText(canvas, '📍  ${analysis.seasonAppropriateness ?? 'All Season'}',
        Offset(12, size.height * 0.88),
        fontSize: 9, color: DarkAnalysisTheme.violet.withValues(alpha: opacity * tagP),
        weight: FontWeight.w600, shadow: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 4: TREND ALIGNMENT (11-13.5s)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderPhase4(Canvas canvas, Size size, double opacity) {
    final progress = _phaseProgress(4);
    final localT = elapsedSeconds - 11.0;

    _drawDimensionLabel(canvas, size, progress * 2, 'TREND ALIGNMENT',
        analysis.dimensions.trendAlignment.score,
        DarkAnalysisTheme.rose, opacity);

    // Trend arrows near top/bottom zones
    final arrowPositions = [
      Offset(size.width * 0.75, size.height * 0.30),
      Offset(size.width * 0.25, size.height * 0.55),
    ];
    final trendLabels = analysis.detectedItems.take(2).map((item) => '$item · Trending').toList();
    while (trendLabels.length < 2) { trendLabels.add('Style · Trending'); }

    for (int i = 0; i < 2; i++) {
      final arrowP = ((localT - 0.3 - i * 0.2) / 0.4).clamp(0.0, 1.0);
      if (arrowP <= 0) continue;
      final bounce = _bounce(arrowP);
      final pos = arrowPositions[i];
      // Arrow icon (drawn as triangle)
      final arrowY = pos.dy - 10 * bounce;
      final path = Path()
        ..moveTo(pos.dx, arrowY - 8)
        ..lineTo(pos.dx - 6, arrowY + 4)
        ..lineTo(pos.dx + 6, arrowY + 4)
        ..close();
      canvas.drawPath(path,
        Paint()..color = DarkAnalysisTheme.rose.withValues(alpha: opacity * bounce));
      // Label
      _drawText(canvas, trendLabels[i],
        Offset(pos.dx + 10, arrowY - 5),
        fontSize: 8, color: Colors.white.withValues(alpha: opacity * bounce),
        weight: FontWeight.w600, shadow: true,
      );
    }

    // Trend timeline bar
    final timelineP = ((localT - 0.8) / 0.8).clamp(0.0, 1.0);
    if (timelineP > 0) {
      const tw = 200.0;
      final tx = size.width / 2 - tw / 2;
      final ty = size.height * 0.88;
      // Line
      canvas.drawLine(Offset(tx, ty + 5), Offset(tx + tw, ty + 5),
        Paint()..color = DarkAnalysisTheme.textMuted.withValues(alpha: 0.5 * opacity)..strokeWidth = 1.5);
      // Labels
      _drawText(canvas, 'Classic', Offset(tx, ty - 2),
        fontSize: 7, color: DarkAnalysisTheme.textMuted.withValues(alpha: opacity), weight: FontWeight.w600);
      _drawText(canvas, 'Trendy', Offset(tx + tw, ty - 2),
        fontSize: 7, color: DarkAnalysisTheme.rose.withValues(alpha: opacity),
        weight: FontWeight.w600, align: TextAlign.right);
      // Animated dot (at ~65% = trending)
      final trendScore = analysis.dimensions.trendAlignment.score / 100;
      final dotX = tx + tw * trendScore * _easeOut(timelineP);
      // Rose gradient fill
      canvas.drawRect(
        Rect.fromLTWH(tx, ty + 3, (dotX - tx).clamp(0, tw), 4),
        Paint()..shader = LinearGradient(
          colors: [DarkAnalysisTheme.rose.withValues(alpha: 0.3 * opacity), DarkAnalysisTheme.rose.withValues(alpha: 0.7 * opacity)],
        ).createShader(Rect.fromLTWH(tx, ty, tw, 4)),
      );
      canvas.drawCircle(Offset(dotX, ty + 5), 5,
        Paint()..color = DarkAnalysisTheme.rose.withValues(alpha: opacity));
    }

    // Seasonal tag top-left
    final season = analysis.seasonAppropriateness ?? 'All Season';
    if (localT > 0.5) {
      final tagOp = ((localT - 0.5) / 0.3).clamp(0.0, 1.0) * opacity;
      _drawText(canvas, '🍂  $season',
        Offset(12, size.height * 0.12),
        fontSize: 9, color: DarkAnalysisTheme.rose.withValues(alpha: tagOp),
        weight: FontWeight.w600, shadow: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 5: STYLE COHESION (13.5-16s)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderPhase5(Canvas canvas, Size size, double opacity) {
    final progress = _phaseProgress(5);
    final localT = elapsedSeconds - 13.5;

    _drawDimensionLabel(canvas, size, progress * 2, 'STYLE COHESION',
        analysis.dimensions.styleCohesion.score,
        DarkAnalysisTheme.blue, opacity);

    // Animated connection lines between zones (marching ants effect)
    final connectionPairs = [
      (Offset(size.width * 0.5, size.height * 0.35), Offset(size.width * 0.5, size.height * 0.86)), // top to shoes
      (Offset(size.width * 0.25, size.height * 0.52), Offset(size.width * 0.75, size.height * 0.35)), // cross body
    ];
    for (int i = 0; i < connectionPairs.length; i++) {
      final lineP = ((localT - 0.3 - i * 0.3) / 0.5).clamp(0.0, 1.0);
      if (lineP <= 0) continue;
      final p = connectionPairs[i];
      final paint = Paint()
        ..color = DarkAnalysisTheme.blue.withValues(alpha: 0.7 * opacity * lineP)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      _drawDashedLine(canvas, p.$1, p.$2, paint,
        dashLen: 6, gapLen: 4, drawProgress: lineP);
      // Node dots at endpoints
      canvas.drawCircle(p.$1, 4 + sin(localT * 3) * 1.5,
        Paint()..color = DarkAnalysisTheme.blue.withValues(alpha: 0.7 * opacity * lineP));
      canvas.drawCircle(p.$2, 4 + sin(localT * 3 + pi) * 1.5,
        Paint()..color = DarkAnalysisTheme.blue.withValues(alpha: 0.7 * opacity * lineP));
    }

    // "Rule of 3" focal circles
    final focalPoints = [
      Offset(size.width * 0.50, size.height * 0.30),
      Offset(size.width * 0.35, size.height * 0.55),
      Offset(size.width * 0.65, size.height * 0.55),
    ];
    for (int i = 0; i < 3; i++) {
      final circP = ((localT - 0.8 - i * 0.15) / 0.5).clamp(0.0, 1.0);
      if (circP <= 0) continue;
      final pos = focalPoints[i];
      // Circle draws itself
      canvas.drawArc(
        Rect.fromCircle(center: pos, radius: 32),
        -pi / 2, 2 * pi * circP,
        false,
        Paint()
          ..color = DarkAnalysisTheme.blue.withValues(alpha: 0.7 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // Number badge
      if (circP > 0.8) {
        canvas.drawCircle(Offset(pos.dx + 22, pos.dy - 22), 9,
          Paint()..color = DarkAnalysisTheme.blue.withValues(alpha: opacity));
        _drawText(canvas, '${i + 1}',
          Offset(pos.dx + 22, pos.dy - 27),
          fontSize: 9, color: Colors.white.withValues(alpha: opacity),
          weight: FontWeight.w800, align: TextAlign.center,
        );
      }
    }

    // Aesthetic label bottom-right
    final aesthetic = analysis.aestheticCategory ?? 'Contemporary Style';
    if (localT > 1.5) {
      final aop = ((localT - 1.5) / 0.4).clamp(0.0, 1.0) * opacity;
      _drawText(canvas, aesthetic,
        Offset(size.width - 12, size.height * 0.90),
        fontSize: 9, color: DarkAnalysisTheme.blue.withValues(alpha: aop),
        weight: FontWeight.w600, align: TextAlign.right, shadow: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 6: SCORE REVEAL (16-20s)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderPhase6(Canvas canvas, Size size, double opacity) {
    final localT = elapsedSeconds - 16.0;

    // Dark overlay + slight desaturate simulation (extra black overlay)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.35 * opacity),
    );

    final cx = size.width / 2, cy = size.height * 0.40;

    // Score ring (fills over 1.5s)
    final ringP = (localT / 1.5).clamp(0.0, 1.0);
    if (ringP > 0) {
      const radius = 50.0;
      const strokeW = 6.0;
      final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      // Track
      canvas.drawCircle(Offset(cx, cy), radius,
        Paint()
          ..color = DarkAnalysisTheme.border.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW);
      // Gradient arc
      final sweepAngle = 2 * pi * (analysis.overallScore / 100) * _easeOut(ringP);
      if (sweepAngle > 0.01) {
        canvas.drawArc(arcRect, -pi / 2, sweepAngle, false,
          Paint()
            ..shader = const SweepGradient(
              startAngle: -pi / 2, endAngle: 3 * pi / 2,
              colors: [DarkAnalysisTheme.gold, DarkAnalysisTheme.teal, DarkAnalysisTheme.violet, DarkAnalysisTheme.gold],
            ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius + 10))
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.round);
      }

      // Score number
      final displayScore = (analysis.overallScore * _easeOut(ringP)).round();
      _drawText(canvas, '$displayScore',
        Offset(cx, cy - 9),
        fontSize: 24, color: DarkAnalysisTheme.gold.withValues(alpha: opacity),
        weight: FontWeight.w800, align: TextAlign.center, shadow: true,
      );
      _drawText(canvas, '/100',
        Offset(cx, cy + 14),
        fontSize: 9, color: DarkAnalysisTheme.textSecondary.withValues(alpha: opacity),
        weight: FontWeight.w500, align: TextAlign.center,
      );
    }

    // Grade badge (appears at localT=2.0 with bounce)
    final gradeT = ((localT - 2.0) / 0.4).clamp(0.0, 1.0);
    if (gradeT > 0) {
      final scale = _bounce(gradeT);
      canvas.save();
      canvas.translate(cx, cy + 65);
      canvas.scale(scale);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-22, -14, 44, 28), const Radius.circular(6)),
        Paint()
          ..shader = const LinearGradient(
            colors: [DarkAnalysisTheme.gold, DarkAnalysisTheme.violet],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(-22, -14, 44, 28)),
      );
      _drawText(canvas, analysis.letterGrade,
        const Offset(0, -9),
        fontSize: 16, color: Colors.white.withValues(alpha: opacity),
        weight: FontWeight.w800, align: TextAlign.center,
      );
      canvas.restore();
    }

    // 5 mini dimension bars
    final dimScores = [
      analysis.dimensions.colorHarmony.score,
      analysis.dimensions.fitProportion.score,
      analysis.dimensions.occasionMatch.score,
      analysis.dimensions.trendAlignment.score,
      analysis.dimensions.styleCohesion.score,
    ];
    const dimColors = [
      DarkAnalysisTheme.gold, DarkAnalysisTheme.teal, DarkAnalysisTheme.violet,
      DarkAnalysisTheme.rose, DarkAnalysisTheme.blue,
    ];
    const dimLabels = ['CLR', 'FIT', 'OCC', 'TRD', 'STY'];
    const barW = 36.0, barH = 5.0, barSpacing = 10.0;
    const totalBarsW = 5 * barW + 4 * barSpacing;
    final barStartX = cx - totalBarsW / 2;
    final barY = cy + 90.0;

    for (int i = 0; i < 5; i++) {
      final barP = ((localT - 2.4 - i * 0.2) / 0.4).clamp(0.0, 1.0);
      if (barP <= 0) continue;
      final bx = barStartX + i * (barW + barSpacing);
      // Track
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, barY, barW, barH), const Radius.circular(3)),
        Paint()..color = DarkAnalysisTheme.border.withValues(alpha: opacity),
      );
      // Fill
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, barY, barW * (dimScores[i] / 100) * _easeOut(barP), barH),
          const Radius.circular(3)),
        Paint()..color = dimColors[i].withValues(alpha: opacity * _easeOut(barP)),
      );
      // Score label above
      _drawText(canvas, '${dimScores[i].round()}',
        Offset(bx + barW / 2, barY - 12),
        fontSize: 7, color: dimColors[i].withValues(alpha: opacity * _easeOut(barP)),
        weight: FontWeight.w700, align: TextAlign.center,
      );
      // Dim label below
      _drawText(canvas, dimLabels[i],
        Offset(bx + barW / 2, barY + barH + 4),
        fontSize: 6, color: DarkAnalysisTheme.textMuted.withValues(alpha: opacity),
        weight: FontWeight.w600, align: TextAlign.center,
      );
    }

    // Confetti burst (starts at localT=2.0)
    final confettiT = localT - 2.0;
    if (confettiT > 0 && confettiT < 2.5) {
      final cp = (confettiT / 2.0).clamp(0.0, 1.0);
      final rng = Random(99);
      for (int i = 0; i < 24; i++) {
        final angle = (i / 24) * 2 * pi + confettiT * pi;
        final radius = cp * size.width * 0.35;
        final px = cx + cos(angle) * radius + sin(confettiT * 3 + i) * 8;
        final py = cy + 65 + sin(angle) * radius * 0.6;
        final confOp = max(0.0, 1.0 - cp * 1.5) * opacity;
        if (confOp <= 0) continue;
        canvas.drawCircle(
          Offset(px, py), 3 + rng.nextDouble() * 2,
          Paint()..color = dimColors[i % 5].withValues(alpha: confOp),
        );
      }
    }

    // Headline typewriter at bottom
    final headline = analysis.headline;
    if (localT > 2.5 && headline.isNotEmpty) {
      _drawTypewriterText(canvas, size, '"$headline"', localT - 2.5,
        x: size.width * 0.1, y: size.height * 0.84, cps: 12);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════

  @override
  bool shouldRepaint(StyleVideoPainter old) =>
      old.elapsedSeconds != elapsedSeconds;
}
