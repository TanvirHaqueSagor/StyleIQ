import 'dart:math';
import 'package:flutter/material.dart';

/// Circular score ring with gradient arc and tip dot.
///
/// Arc uses a gold→teal→violet sweep gradient matching the HTML design.
class ScoreRingPainter extends CustomPainter {
  final double score; // 0 – 100
  final double animationValue; // 0.0 – 1.0
  final Color trackColor;

  ScoreRingPainter({
    required this.score,
    required this.animationValue,
    required this.trackColor,
  });

  static const _gradColors = [
    Color(0xFFd4a853), // gold
    Color(0xFF4ecdc4), // teal
    Color(0xFF9b7fe6), // violet
    Color(0xFFd4a853), // gold (seamless loop)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - 14;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * (score / 100) * animationValue;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // ── Background track ────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    if (sweepAngle <= 0.001) return;

    // ── Gradient shader (sweep, starts at top) ──────────────────────────────
    final shader = const SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: _gradColors,
    ).createShader(Rect.fromCircle(center: center, radius: radius + 14));

    // ── Glow arc (wide, blurred, semi-transparent gold) ─────────────────────
    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0xFFd4a853).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── Main arc (gradient) ─────────────────────────────────────────────────
    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // ── Tip dot ─────────────────────────────────────────────────────────────
    final endAngle = startAngle + sweepAngle;
    final tip = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );

    canvas.drawCircle(
      tip, 13,
      Paint()
        ..color = const Color(0xFFd4a853).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(tip, 5.5, Paint()..color = const Color(0xFFd4a853));
    canvas.drawCircle(
      tip, 2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(ScoreRingPainter old) =>
      old.animationValue != animationValue || old.score != score;
}

/// Dark-themed spider/radar chart with glowing polygon.
class DarkRadarChartPainter extends CustomPainter {
  final List<double> values; // 0.0 – 1.0 per axis
  final List<String> labels;
  final Color accentColor;
  final double animationValue; // 0.0 – 1.0

  const DarkRadarChartPainter({
    required this.values,
    required this.labels,
    required this.accentColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - 30;
    const sides = 5;
    const startAngle = -pi / 2;
    const step = 2 * pi / sides;

    // Grid rings
    for (int ring = 1; ring <= 4; ring++) {
      final r = maxR * ring / 4;
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final a = startAngle + i * step;
        final pt = Offset(center.dx + r * cos(a), center.dy + r * sin(a));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 4 ? 1.0 : 0.7,
      );
    }

    // Spokes
    for (int i = 0; i < sides; i++) {
      final a = startAngle + i * step;
      canvas.drawLine(
        center,
        Offset(center.dx + maxR * cos(a), center.dy + maxR * sin(a)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 0.7,
      );
    }

    // Data polygon
    final dataPath = Path();
    for (int i = 0; i <= sides; i++) {
      final idx = i % sides;
      final v = values[idx] * animationValue;
      final a = startAngle + idx * step;
      final pt = Offset(
        center.dx + maxR * v * cos(a),
        center.dy + maxR * v * sin(a),
      );
      i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
    }

    // Fill
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = accentColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // Glow stroke
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = accentColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round,
    );

    // Crisp stroke
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    // Vertex dots
    for (int i = 0; i < sides; i++) {
      final v = values[i] * animationValue;
      final a = startAngle + i * step;
      final pt = Offset(
        center.dx + maxR * v * cos(a),
        center.dy + maxR * v * sin(a),
      );
      canvas.drawCircle(pt, 8, Paint()..color = accentColor.withValues(alpha: 0.25));
      canvas.drawCircle(pt, 4, Paint()..color = accentColor);
      canvas.drawCircle(pt, 2, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    // Labels
    for (int i = 0; i < sides; i++) {
      final a = startAngle + i * step;
      final pt = Offset(
        center.dx + (maxR + 20) * cos(a),
        center.dy + (maxR + 20) * sin(a),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Color(0xFF8a8694),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, pt - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(DarkRadarChartPainter old) =>
      old.animationValue != animationValue;
}

/// Spinning conic-gradient border for the hero photo frame.
///
/// Animates by updating [angle] via an [AnimationController].
class SpinningBorderPainter extends CustomPainter {
  final double angle; // 0 – 2π, updated each frame

  SpinningBorderPainter({required this.angle});

  static const _colors = [
    Color(0xFFd4a853),
    Color(0xFF4ecdc4),
    Color(0xFF9b7fe6),
    Color(0xFFe06b7a),
    Color(0xFFd4a853), // seamless wrap
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shader = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * pi,
      colors: _colors,
    ).createShader(rect);

    // Glow layer
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(10), const Radius.circular(22)),
      Paint()
        ..color = const Color(0xFFd4a853).withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Crisp border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(22)),
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(SpinningBorderPainter old) => old.angle != angle;
}

/// Simple sine-wave path drawn with a gold stroke — used as section divider.
class WavePainter extends CustomPainter {
  const WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFd4a853).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    final sw = size.width / 4;
    for (int i = 0; i < 4; i++) {
      final x0 = sw * i;
      path.cubicTo(
        x0 + sw * 0.25, size.height * 0.1,
        x0 + sw * 0.75, size.height * 0.9,
        x0 + sw, size.height / 2,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter _) => false;
}
