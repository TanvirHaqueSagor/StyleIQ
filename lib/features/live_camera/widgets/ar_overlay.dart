import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ar_item.dart';
import '../models/tracked_face.dart';

/// High-quality AR try-on overlay.
///
/// Each item is rendered in four passes:
///   1. Drop-shadow  (MaskFilter.blur)
///   2. Fill          (gradient tint / base colour)
///   3. Frame / stroke (metallic LinearGradient shader)
///   4. Specular highlight (white radial-gradient glare)
///
/// When [face] is available all anchors are derived from real ML Kit landmarks
/// and rotated with head tilt; otherwise static portrait proportions are used.
class ArOverlay extends StatelessWidget {
  final Map<String, Set<String>> activeItems;
  final TrackedFaceData? face;

  const ArOverlay({super.key, required this.activeItems, this.face});

  List<ArItem> _resolve() {
    final result = <ArItem>[];
    for (final entry in activeItems.entries) {
      for (final name in entry.value) {
        final item = ArCatalog.find(entry.key, name);
        if (item != null) result.add(item);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final active = _resolve();
    if (active.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ArOverlayPainter(items: active, face: face),
        ),
      ),
    );
  }
}

// ── Face geometry (unchanged from previous version) ──────────────────────────

class _FaceGeometry {
  final Offset noseBridge;
  final double rollRad;
  final Offset leftEye;
  final Offset rightEye;
  final double eyeDist;
  final Offset leftEar;
  final Offset rightEar;
  final Offset mouthCenter;
  final double mouthWidth;
  final Offset headTop;
  final Offset beardCenter;
  final double faceHalfW;

  const _FaceGeometry({
    required this.noseBridge,
    required this.rollRad,
    required this.leftEye,
    required this.rightEye,
    required this.eyeDist,
    required this.leftEar,
    required this.rightEar,
    required this.mouthCenter,
    required this.mouthWidth,
    required this.headTop,
    required this.beardCenter,
    required this.faceHalfW,
  });

  static Offset _toLocal(Offset p, Offset origin, double roll) {
    final v = p - origin;
    if (roll == 0) return v;
    final c = math.cos(-roll);
    final s = math.sin(-roll);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  factory _FaceGeometry.fromFace(TrackedFaceData face) {
    final nb   = face.noseBridge;
    final roll = face.headRollRad;
    Offset loc(Offset p) => _toLocal(p, nb, roll);

    final le = loc(face.leftEye);
    final re = loc(face.rightEye);
    final ed = face.eyeDistance;
    final mc = loc(face.mouthCenter);
    final bbTopCentre = loc(Offset(face.faceCenter.dx, face.boundingBox.top));

    return _FaceGeometry(
      noseBridge:  nb,
      rollRad:     roll,
      leftEye:     le,
      rightEye:    re,
      eyeDist:     ed,
      leftEar:     loc(face.leftEarOrEdge),
      rightEar:    loc(face.rightEarOrEdge),
      mouthCenter: mc,
      mouthWidth:  face.mouthWidth,
      headTop:     bbTopCentre - Offset(0, ed * 0.20),
      beardCenter: mc + Offset(0, ed * 0.25),
      faceHalfW:   face.boundingBox.width * 0.5,
    );
  }

  factory _FaceGeometry.fallback(Size size) {
    final ed = size.width * 0.30;
    final nb = Offset(size.width * 0.50, size.height * 0.40);
    return _FaceGeometry(
      noseBridge:  nb,
      rollRad:     0,
      leftEye:     Offset(-ed * 0.50, -ed * 0.15),
      rightEye:    Offset( ed * 0.50, -ed * 0.15),
      eyeDist:     ed,
      leftEar:     Offset(-ed * 0.95, -ed * 0.12),
      rightEar:    Offset( ed * 0.95, -ed * 0.12),
      mouthCenter: Offset(0,  ed * 0.72),
      mouthWidth:  ed * 0.62,
      headTop:     Offset(0, -ed * 1.05),
      beardCenter: Offset(0,  ed * 1.02),
      faceHalfW:   ed * 0.72,
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _ArOverlayPainter extends CustomPainter {
  final List<ArItem> items;
  final TrackedFaceData? face;

  const _ArOverlayPainter({required this.items, this.face});

  // ── Colour helpers ──────────────────────────────────────────────────────────

  /// Lightens [c] by [amount] (0–1).
  static Color _lighten(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Darkens [c] by [amount] (0–1).
  static Color _darken(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Returns a top→bottom metallic gradient shader for [bounds].
  static Shader _metalShader(Color base, Rect bounds) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end:   Alignment.bottomCenter,
        colors: [_lighten(base, 0.32), base, _darken(base, 0.22)],
        stops:  const [0.0, 0.50, 1.0],
      ).createShader(bounds);

  // ── Shadows ─────────────────────────────────────────────────────────────────

  static final Paint _softShadow = Paint()
    ..color      = Colors.black.withValues(alpha: 0.32)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

  static final Paint _crisperShadow = Paint()
    ..color      = Colors.black.withValues(alpha: 0.22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // ── Main paint dispatch ──────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final geo = face != null
        ? _FaceGeometry.fromFace(face!)
        : _FaceGeometry.fallback(size);

    canvas.save();
    canvas.translate(geo.noseBridge.dx, geo.noseBridge.dy);
    canvas.rotate(geo.rollRad);

    for (final item in items) {
      switch (item.region) {
        case ArRegion.eyes:
          item.category == ArCategory.glasses
              ? _paintGlasses(canvas, geo, item)
              : _paintEyeMakeup(canvas, geo, item);
        case ArRegion.lips:
          _paintLips(canvas, geo, item);
        case ArRegion.ears:
          _paintEarrings(canvas, geo, item);
        case ArRegion.head:
          _paintHeadAccessory(canvas, geo, item);
        case ArRegion.beard:
          _paintBeard(canvas, geo, item);
        case ArRegion.hairTop:
          _paintHairColor(canvas, geo, item);
      }
    }

    canvas.restore();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GLASSES  — four-pass: shadow · lens tint · metallic frame · lens glare
  // ══════════════════════════════════════════════════════════════════════════

  void _paintGlasses(Canvas canvas, _FaceGeometry geo, ArItem item) {
    final lCx = geo.leftEye.dx;
    final rCx = geo.rightEye.dx;
    final ey  = (geo.leftEye.dy + geo.rightEye.dy) / 2;
    final ed  = geo.eyeDist;
    final lw  = ed * 0.46;
    final lh  = ed * 0.20;

    final leftR  = Rect.fromCenter(center: Offset(lCx, ey), width: lw * 2, height: lh * 2);
    final rightR = Rect.fromCenter(center: Offset(rCx, ey), width: lw * 2, height: lh * 2);
    final frameBounds = Rect.fromLTRB(lCx - lw, ey - lh, rCx + lw, ey + lh);

    final leftPath  = _lensPath(item.name, leftR,  lCx, ey, lw, lh, left: true);
    final rightPath = _lensPath(item.name, rightR, rCx, ey, lw, lh, left: false);

    // ── 1. Shadow ──────────────────────────────────────────────────────────
    final shadowPath = Path()
      ..addPath(leftPath,  const Offset(0, 3))
      ..addPath(rightPath, const Offset(0, 3));
    canvas.drawPath(shadowPath, _softShadow);

    // ── 2. Lens tint ───────────────────────────────────────────────────────
    // Gradient: slightly darker at top/edges, lighter towards centre-bottom —
    // simulates a real tinted lens with light refraction.
    void drawLensTint(Rect r, Path p) {
      canvas.drawPath(
        p,
        Paint()
          ..style  = PaintingStyle.fill
          ..shader = RadialGradient(
            center: const Alignment(0.1, -0.15),
            radius: 0.9,
            colors: [
              item.primaryColor.withValues(alpha: 0.22),
              item.primaryColor.withValues(alpha: 0.55),
            ],
          ).createShader(r),
      );
    }
    drawLensTint(leftR,  leftPath);
    drawLensTint(rightR, rightPath);

    // Subtle inner-rim darkening (vignette effect on lens edges)
    for (final (r, p) in [(leftR, leftPath), (rightR, rightPath)]) {
      canvas.drawPath(
        p,
        Paint()
          ..style  = PaintingStyle.fill
          ..shader = RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.14),
            ],
            stops: const [0.55, 1.0],
          ).createShader(r),
      );
    }

    // ── 3. Metallic frame ──────────────────────────────────────────────────
    final frameStrokeW = ed * 0.038;

    // Outer shadow stroke
    final outerShadow = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = frameStrokeW + 2.5
      ..strokeCap   = StrokeCap.round
      ..color       = Colors.black.withValues(alpha: 0.30);

    // Metallic gradient stroke
    final metalStroke = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = frameStrokeW
      ..strokeCap   = StrokeCap.round
      ..shader      = _metalShader(item.primaryColor, frameBounds);

    // Thin highlight edge stroke
    final glintStroke = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = frameStrokeW * 0.28
      ..strokeCap   = StrokeCap.round
      ..color       = _lighten(item.primaryColor, 0.45).withValues(alpha: 0.70);

    for (final paint in [outerShadow, metalStroke, glintStroke]) {
      canvas.drawPath(leftPath,  paint);
      canvas.drawPath(rightPath, paint);
    }

    // Bridge
    final bridgeLeft  = Offset(lCx + lw * _bridgeInset(item.name), ey);
    final bridgeRight = Offset(rCx - lw * _bridgeInset(item.name), ey);
    canvas.drawLine(bridgeLeft,  bridgeRight, metalStroke);
    canvas.drawLine(bridgeLeft,  bridgeRight, glintStroke);

    // Arms extending toward ears
    _drawArms(canvas, geo, lCx, rCx, ey, lw, lh, metalStroke, glintStroke);

    // ── 4. Specular lens glare ─────────────────────────────────────────────
    for (final cx in [lCx, rCx]) {
      final glareRect = Rect.fromCenter(
        center: Offset(cx - lw * 0.26, ey - lh * 0.35),
        width: lw * 0.60, height: lh * 0.38,
      );
      canvas.drawOval(
        glareRect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.68),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(glareRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
  }

  /// Returns the lens [Path] for this [name] (style), centred on [cx],[cy].
  Path _lensPath(
    String name,
    Rect r,
    double cx,
    double cy,
    double lw,
    double lh, {
    required bool left,
  }) {
    switch (name) {
      case 'Round':
        return Path()..addOval(r);
      case 'Cat-Eye':
        return _catEyePath(cx, cy, lw, lh, left: left);
      case 'Rimless':
        return Path()..addOval(r);
      case 'Sport':
        // Single wide shield — caller handles sport separately via _paintGlasses override
        return Path()
          ..addRRect(RRect.fromRectAndRadius(r.inflate(lw * 0.08), const Radius.circular(6)));
      default: // Aviator + Wayfarer
        return name == 'Aviator'
            ? _aviatorPath(cx, cy, lw, lh)
            : Path()
                ..addRRect(
                    RRect.fromRectAndRadius(r, const Radius.circular(5)));
    }
  }

  Path _aviatorPath(double cx, double cy, double lw, double lh) => Path()
    ..moveTo(cx - lw, cy - lh * 0.15)
    ..lineTo(cx + lw, cy - lh * 0.15)
    ..quadraticBezierTo(cx + lw * 1.12, cy + lh * 0.15, cx + lw * 0.72, cy + lh * 0.95)
    ..quadraticBezierTo(cx, cy + lh * 1.35, cx - lw * 0.72, cy + lh * 0.95)
    ..quadraticBezierTo(cx - lw * 1.12, cy + lh * 0.15, cx - lw, cy - lh * 0.15)
    ..close();

  Path _catEyePath(double cx, double cy, double lw, double lh, {required bool left}) {
    final xs = left ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx - lw, cy + lh * 0.3)
      ..quadraticBezierTo(cx - lw * 0.4, cy - lh * 0.6, cx + xs * lw * 0.15, cy - lh * 0.7)
      ..quadraticBezierTo(cx + xs * lw * 0.9, cy - lh * 1.25, cx + xs * lw * 1.1, cy - lh * 0.25)
      ..quadraticBezierTo(cx + xs * lw * 0.8, cy + lh * 0.55, cx, cy + lh * 0.5)
      ..quadraticBezierTo(cx - lw * 0.45, cy + lh * 0.5, cx - lw, cy + lh * 0.3)
      ..close();
  }

  /// How far the bridge insets from each lens edge (fraction of lw).
  double _bridgeInset(String name) =>
      (name == 'Sport' || name == 'Rimless') ? 0.0 : 0.92;

  void _drawArms(
    Canvas canvas,
    _FaceGeometry geo,
    double lCx,
    double rCx,
    double ey,
    double lw,
    double lh,
    Paint metal,
    Paint glint,
  ) {
    for (final paint in [metal, glint]) {
      canvas.drawLine(
        Offset(lCx - lw, ey),
        Offset(geo.leftEar.dx + geo.eyeDist * 0.10, ey + lh * 0.55),
        paint,
      );
      canvas.drawLine(
        Offset(rCx + lw, ey),
        Offset(geo.rightEar.dx - geo.eyeDist * 0.10, ey + lh * 0.55),
        paint,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EYE MAKEUP  — soft-blended liner / smoky shadow
  // ══════════════════════════════════════════════════════════════════════════

  void _paintEyeMakeup(Canvas canvas, _FaceGeometry geo, ArItem item) {
    final ed  = geo.eyeDist;
    final lCx = geo.leftEye.dx;
    final rCx = geo.rightEye.dx;
    final ey  = (geo.leftEye.dy + geo.rightEye.dy) / 2 - ed * 0.04;
    final ew  = ed * 0.38;
    final eh  = ed * 0.08;

    if (item.name == 'Smokey') {
      // Layered smoky effect: three concentric blurred ovals
      for (int i = 3; i >= 1; i--) {
        final alpha = (i == 3 ? 0.30 : i == 2 ? 0.50 : 0.68);
        final scale = 0.7 + i * 0.28;
        for (final cx in [lCx, rCx]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, ey), width: ew * 2 * scale, height: eh * 3 * scale),
            Paint()
              ..color      = item.primaryColor.withValues(alpha: alpha)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * i),
          );
        }
      }
      return;
    }

    if (item.name == 'Winged') {
      for (int s = 0; s < 2; s++) {
        final cx = s == 0 ? lCx : rCx;
        final xs = s == 0 ? -1.0 : 1.0;

        // Shadow under liner
        final linePath = Path()
          ..moveTo(cx - ew * 0.85, ey + eh * 0.1)
          ..quadraticBezierTo(cx, ey - eh * 1.4, cx + ew * 0.85, ey + eh * 0.1);
        canvas.drawPath(
          linePath,
          Paint()
            ..color       = Colors.black.withValues(alpha: 0.30)
            ..strokeWidth = eh * 0.8
            ..style       = PaintingStyle.stroke
            ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        // Main liner (gradient: item colour → slightly darker at tail)
        canvas.drawPath(
          linePath,
          Paint()
            ..shader      = LinearGradient(
              colors: [item.primaryColor, _darken(item.primaryColor, 0.15)],
            ).createShader(Rect.fromLTRB(cx - ew, ey - eh * 2, cx + ew, ey + eh))
            ..strokeWidth = eh * 0.65
            ..style       = PaintingStyle.stroke
            ..strokeCap   = StrokeCap.round,
        );
        // Wing flick
        canvas.drawLine(
          Offset(cx + xs * ew * 0.78, ey + eh * 0.12),
          Offset(cx + xs * ew * 1.50, ey - eh * 1.15),
          Paint()
            ..color       = _darken(item.primaryColor, 0.10)
            ..strokeWidth = eh * 0.55
            ..strokeCap   = StrokeCap.round
            ..style       = PaintingStyle.stroke,
        );
      }
      return;
    }

    // Default: top-lid arc liner (Classic, Soft, Bold, Earth)
    for (final cx in [lCx, rCx]) {
      // Blur shadow layer
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, ey + eh), width: ew * 2.1, height: eh * 2.3),
        math.pi * 1.12, math.pi * 0.76, false,
        Paint()
          ..color       = Colors.black.withValues(alpha: 0.28)
          ..strokeWidth = eh * 1.0
          ..style       = PaintingStyle.stroke
          ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      // Crisp liner
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, ey + eh), width: ew * 2.0, height: eh * 2.1),
        math.pi * 1.15, math.pi * 0.70, false,
        Paint()
          ..color       = item.primaryColor.withValues(alpha: 0.85)
          ..strokeWidth = eh * 0.70
          ..style       = PaintingStyle.stroke
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIPS  — gradient fill · cupid's bow · gloss highlight
  // ══════════════════════════════════════════════════════════════════════════

  void _paintLips(Canvas canvas, _FaceGeometry geo, ArItem item) {
    final cx      = geo.mouthCenter.dx;
    final cy      = geo.mouthCenter.dy;
    final w       = geo.mouthWidth * 0.50;
    final h       = geo.eyeDist * 0.074;
    final isGloss = item.name == 'Gloss' || item.name == 'Natural';
    final isMatte = item.name == 'Matte' || item.name == 'Bold';

    // Lip paths
    final upper = _upperLipPath(cx, cy, w, h);
    final lower = _lowerLipPath(cx, cy, w, h);
    final lipBounds = Rect.fromLTRB(cx - w, cy - h, cx + w, cy + h * 1.65);

    // ── 1. Shadow ──────────────────────────────────────────────────────────
    final shadowPath = Path()..addPath(lower, const Offset(0, 2.5));
    canvas.drawPath(shadowPath, _crisperShadow);

    // ── 2. Gradient fill ──────────────────────────────────────────────────
    final baseAlpha = isGloss ? 0.58 : (isMatte ? 0.90 : 0.80);
    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end:   Alignment.bottomCenter,
      colors: [
        _darken(item.primaryColor, 0.10).withValues(alpha: baseAlpha),
        item.primaryColor.withValues(alpha: baseAlpha),
        _lighten(item.primaryColor, 0.08).withValues(alpha: baseAlpha),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(lipBounds);

    final fillPaint = Paint()..style = PaintingStyle.fill..shader = fillShader;
    canvas.drawPath(upper, fillPaint);
    canvas.drawPath(lower, fillPaint);

    // ── 3. Outline ────────────────────────────────────────────────────────
    final outlinePaint = Paint()
      ..color       = _darken(item.primaryColor, 0.20).withValues(alpha: 0.55)
      ..strokeWidth = 0.9
      ..style       = PaintingStyle.stroke;
    canvas.drawPath(upper, outlinePaint);
    canvas.drawPath(lower, outlinePaint);

    // ── 4. Gloss / highlight ──────────────────────────────────────────────
    // Upper lip: thin white highlight along the cupid's bow ridge
    canvas.drawPath(
      _cupidBowHighlight(cx, cy, w, h),
      Paint()
        ..color       = Colors.white.withValues(alpha: isGloss ? 0.40 : 0.22)
        ..strokeWidth = h * 0.18
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    // Lower lip: broad central highlight
    final lowerHighlight = Rect.fromCenter(
      center: Offset(cx, cy + h * 0.82),
      width: w * (isGloss ? 0.72 : 0.45),
      height: h * (isGloss ? 0.55 : 0.30),
    );
    canvas.drawOval(
      lowerHighlight,
      Paint()
        ..color      = Colors.white.withValues(alpha: isGloss ? 0.45 : 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isGloss ? 4.0 : 2.5),
    );
  }

  Path _upperLipPath(double cx, double cy, double w, double h) => Path()
    ..moveTo(cx - w, cy)
    ..quadraticBezierTo(cx - w * 0.55, cy - h * 0.65, cx - w * 0.18, cy - h * 0.18)
    ..quadraticBezierTo(cx - w * 0.06, cy - h * 0.95, cx,             cy - h * 0.68)
    ..quadraticBezierTo(cx + w * 0.06, cy - h * 0.95, cx + w * 0.18, cy - h * 0.18)
    ..quadraticBezierTo(cx + w * 0.55, cy - h * 0.65, cx + w,         cy)
    ..close();

  Path _lowerLipPath(double cx, double cy, double w, double h) => Path()
    ..moveTo(cx - w, cy)
    ..quadraticBezierTo(cx - w * 0.3, cy + h * 1.5, cx, cy + h * 1.65)
    ..quadraticBezierTo(cx + w * 0.3, cy + h * 1.5, cx + w, cy)
    ..close();

  Path _cupidBowHighlight(double cx, double cy, double w, double h) => Path()
    ..moveTo(cx - w * 0.55, cy - h * 0.30)
    ..quadraticBezierTo(cx - w * 0.15, cy - h * 0.70, cx, cy - h * 0.52)
    ..quadraticBezierTo(cx + w * 0.15, cy - h * 0.70, cx + w * 0.55, cy - h * 0.30);

  // ══════════════════════════════════════════════════════════════════════════
  // EARRINGS  — metallic gradient · specular dot · style variants
  // ══════════════════════════════════════════════════════════════════════════

  void _paintEarrings(Canvas canvas, _FaceGeometry geo, ArItem item) {
    _drawEarring(canvas, geo.leftEar,  item, isLeft: true);
    _drawEarring(canvas, geo.rightEar, item, isLeft: false);
  }

  void _drawEarring(Canvas canvas, Offset pos, ArItem item, {required bool isLeft}) {
    // Shadow
    canvas.drawCircle(pos.translate(0, 3), 12, _crisperShadow);

    final base    = item.primaryColor;
    final hilight = _lighten(base, 0.40);
    final shadow  = _darken(base,  0.30);

    Paint metalFill(Rect r) => Paint()
      ..style  = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.42),
        radius: 0.85,
        colors: [hilight, base, shadow],
        stops:  const [0.0, 0.48, 1.0],
      ).createShader(r);

    final accentPaint = Paint()
      ..color       = item.accentColor
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;

    switch (item.name) {
      case 'Stud':
        final r = Rect.fromCircle(center: pos, radius: 8);
        canvas.drawCircle(pos, 8, metalFill(r));
        canvas.drawCircle(pos, 8, accentPaint);
        canvas.drawCircle(pos.translate(-2.5, -2.5), 2.5,
            Paint()..color = Colors.white.withValues(alpha: 0.70));

      case 'Hoop':
        final hoopCenter = pos.translate(0, 16);
        final hoopRect   = Rect.fromCircle(center: hoopCenter, radius: 16);
        canvas.drawArc(
          hoopRect, math.pi * 0.05, math.pi * 1.9, false,
          Paint()
            ..shader      = _metalShader(base, hoopRect)
            ..strokeWidth = 3.2
            ..style       = PaintingStyle.stroke
            ..strokeCap   = StrokeCap.round,
        );
        // Specular arc
        canvas.drawArc(
          hoopRect.deflate(0.5), math.pi * 1.08, math.pi * 0.35, false,
          Paint()
            ..color       = hilight.withValues(alpha: 0.65)
            ..strokeWidth = 1.2
            ..style       = PaintingStyle.stroke
            ..strokeCap   = StrokeCap.round,
        );

      case 'Drop':
        final stemEnd  = pos.translate(0, 24);
        final dropRect = Rect.fromCenter(center: pos.translate(0, 34), width: 12, height: 17);
        // Stem
        canvas.drawLine(pos.translate(0, 5), stemEnd,
            Paint()..color = base..strokeWidth = 2.2..strokeCap = StrokeCap.round);
        // Drop gem
        canvas.drawPath(
          Path()
            ..moveTo(stemEnd.dx, stemEnd.dy)
            ..lineTo(stemEnd.dx - 6, stemEnd.dy + 8)
            ..lineTo(stemEnd.dx,     stemEnd.dy + 17)
            ..lineTo(stemEnd.dx + 6, stemEnd.dy + 8)
            ..close(),
          metalFill(dropRect),
        );
        canvas.drawOval(dropRect, accentPaint);
        // Specular
        canvas.drawCircle(stemEnd.translate(-2, 4), 2.5,
            Paint()..color = Colors.white.withValues(alpha: 0.62));

      case 'Pearl':
        final r = Rect.fromCircle(center: pos, radius: 9);
        canvas.drawCircle(
          pos, 9,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.40, -0.45),
              colors: [
                Colors.white,
                item.primaryColor.withValues(alpha: 0.85),
                _darken(item.primaryColor, 0.18),
              ],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(r),
        );
        canvas.drawCircle(pos, 9,
            Paint()..color = item.accentColor.withValues(alpha: 0.35)..strokeWidth = 1..style = PaintingStyle.stroke);
        canvas.drawCircle(pos.translate(-2.8, -3.0), 2.8,
            Paint()..color = Colors.white.withValues(alpha: 0.75));

      case 'Crystal':
        final facets = Path()
          ..moveTo(pos.dx,      pos.dy - 13)
          ..lineTo(pos.dx + 7,  pos.dy + 2)
          ..lineTo(pos.dx + 4,  pos.dy + 10)
          ..lineTo(pos.dx - 4,  pos.dy + 10)
          ..lineTo(pos.dx - 7,  pos.dy + 2)
          ..close();
        final facetBounds = Rect.fromLTRB(pos.dx - 8, pos.dy - 14, pos.dx + 8, pos.dy + 11);
        canvas.drawPath(facets, metalFill(facetBounds));
        canvas.drawPath(facets, accentPaint);
        // Inner facet line for realism
        canvas.drawLine(pos.translate(0, -13), pos.translate(0, 10),
            Paint()..color = Colors.white.withValues(alpha: 0.38)..strokeWidth = 0.8);
        canvas.drawCircle(pos.translate(-2, -8), 2.0,
            Paint()..color = Colors.white.withValues(alpha: 0.75));

      case 'Jhumka':
        // Cap
        final capR = Rect.fromCircle(center: pos, radius: 7);
        canvas.drawCircle(pos, 7, metalFill(capR));
        canvas.drawCircle(pos, 7, accentPaint);
        // Bell body
        final bell = Path()
          ..moveTo(pos.dx - 12, pos.dy + 7)
          ..quadraticBezierTo(pos.dx - 14, pos.dy + 26, pos.dx,      pos.dy + 34)
          ..quadraticBezierTo(pos.dx + 14, pos.dy + 26, pos.dx + 12, pos.dy + 7)
          ..close();
        final bellR = Rect.fromLTRB(pos.dx - 15, pos.dy + 6, pos.dx + 15, pos.dy + 35);
        canvas.drawPath(bell, metalFill(bellR));
        canvas.drawPath(bell, accentPaint);
        // Bottom beads
        for (int i = -2; i <= 2; i++) {
          final beadPos = Offset(pos.dx + i * 3.8, pos.dy + 36.5);
          canvas.drawCircle(beadPos, 2.5,
              metalFill(Rect.fromCircle(center: beadPos, radius: 2.5)));
        }
        // Specular
        canvas.drawCircle(pos.translate(-3, -3), 2.2,
            Paint()..color = Colors.white.withValues(alpha: 0.65));

      default:
        final r = Rect.fromCircle(center: pos, radius: 7);
        canvas.drawCircle(pos, 7, metalFill(r));
        canvas.drawCircle(pos, 7, accentPaint);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEAD ACCESSORIES  — fabric gradient · decorative detail · shadow
  // ══════════════════════════════════════════════════════════════════════════

  void _paintHeadAccessory(Canvas canvas, _FaceGeometry geo, ArItem item) {
    const cx = 0.0;
    final ty = geo.headTop.dy;
    final hw = geo.faceHalfW;
    final ed = geo.eyeDist;

    final base      = item.primaryColor;
    final bounds    = Rect.fromLTRB(-hw, ty, hw, ty + ed * 0.12);
    final fillPaint = Paint()
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end:   Alignment.bottomCenter,
        colors: [_lighten(base, 0.18), base, _darken(base, 0.15)],
        stops:  const [0.0, 0.55, 1.0],
      ).createShader(bounds);
    final edgePaint = Paint()
      ..color       = item.accentColor
      ..strokeWidth = 1.6
      ..style       = PaintingStyle.stroke;

    switch (item.name) {
      case 'Cap':
        final crown = Path()
          ..moveTo(cx - hw, ty + ed * 0.068)
          ..quadraticBezierTo(cx, ty - ed * 0.042, cx + hw, ty + ed * 0.068)
          ..close();
        canvas.drawPath(crown, Paint()..color = Colors.black.withValues(alpha: 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawPath(crown, fillPaint);
        canvas.drawPath(crown, edgePaint);
        // Brim
        canvas.drawLine(
          Offset(cx - hw * 1.28, ty + ed * 0.072),
          Offset(cx + hw * 1.28, ty + ed * 0.072),
          Paint()
            ..shader      = _metalShader(base, Rect.fromLTRB(-hw * 1.3, ty, hw * 1.3, ty + ed * 0.1))
            ..strokeWidth = 5.0
            ..strokeCap   = StrokeCap.round,
        );
        // Cap-band detail
        canvas.drawLine(
          Offset(cx - hw * 0.82, ty + ed * 0.038),
          Offset(cx + hw * 0.82, ty + ed * 0.038),
          Paint()..color = _darken(base, 0.18).withValues(alpha: 0.55)..strokeWidth = 2.0,
        );

      case 'Turban':
        for (int i = 0; i < 4; i++) {
          final dy = ty + i * ed * 0.024;
          final c  = Color.lerp(base, item.accentColor, i / 3.5)!;
          final band = Path()
            ..moveTo(cx - hw + i * 5, dy + ed * 0.038)
            ..quadraticBezierTo(cx, dy - ed * 0.012, cx + hw - i * 5, dy + ed * 0.038)
            ..close();
          canvas.drawPath(band, Paint()..color = c.withValues(alpha: 0.88)..style = PaintingStyle.fill);
          canvas.drawPath(band, Paint()..color = _darken(c, 0.12).withValues(alpha: 0.45)..strokeWidth = 1..style = PaintingStyle.stroke);
        }
        // Centre jewel
        final jewelR = Rect.fromCircle(center: Offset(cx, ty + ed * 0.01), radius: 12);
        canvas.drawCircle(
          Offset(cx, ty + ed * 0.01), 12,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.35),
              colors: [_lighten(item.accentColor, 0.30), item.accentColor, _darken(item.accentColor, 0.22)],
            ).createShader(jewelR),
        );
        canvas.drawCircle(Offset(cx, ty + ed * 0.01), 12,
            Paint()..color = _darken(item.accentColor, 0.18)..strokeWidth = 1.2..style = PaintingStyle.stroke);
        canvas.drawCircle(Offset(cx - 3.5, ty + ed * 0.01 - 3.5), 3.5,
            Paint()..color = Colors.white.withValues(alpha: 0.62));

      case 'Beanie':
        final beanie = Path()
          ..moveTo(cx - hw, ty + ed * 0.078)
          ..quadraticBezierTo(cx - hw * 0.5, ty - ed * 0.055, cx, ty - ed * 0.062)
          ..quadraticBezierTo(cx + hw * 0.5, ty - ed * 0.055, cx + hw, ty + ed * 0.078)
          ..close();
        canvas.drawPath(beanie, Paint()..color = Colors.black.withValues(alpha: 0.20)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawPath(beanie, fillPaint);
        canvas.drawPath(beanie, edgePaint);
        // Rib lines
        for (int i = 1; i <= 4; i++) {
          final lineY = ty + ed * 0.078 - i * ed * 0.015;
          final lw    = hw * (1.0 - i * 0.12);
          canvas.drawLine(Offset(cx - lw, lineY), Offset(cx + lw, lineY),
              Paint()..color = _darken(base, 0.15).withValues(alpha: 0.40)..strokeWidth = 1.5);
        }
        // Pom-pom
        canvas.drawCircle(Offset(cx, ty - ed * 0.072), ed * 0.06,
            Paint()..color = item.accentColor.withValues(alpha: 0.90)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(cx, ty - ed * 0.072), ed * 0.06,
            Paint()..color = item.accentColor);

      case 'Bandana':
        final band = Path()
          ..moveTo(cx - hw * 1.08, ty + ed * 0.062)
          ..lineTo(cx, ty - ed * 0.048)
          ..lineTo(cx + hw * 1.08, ty + ed * 0.062)
          ..close();
        canvas.drawPath(band, Paint()..color = Colors.black.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawPath(band, fillPaint);
        canvas.drawPath(band, edgePaint);
        // Polka-dot pattern
        final rng = math.Random(7);
        for (int i = 0; i < 12; i++) {
          canvas.drawCircle(
            Offset(cx - hw * 0.75 + rng.nextDouble() * hw * 1.5, ty - ed * 0.02 + rng.nextDouble() * ed * 0.06),
            2.5, Paint()..color = item.accentColor.withValues(alpha: 0.55),
          );
        }

      default: // Silk / Wrap
        final wrap = Path()
          ..moveTo(cx - hw * 0.90, ty + ed * 0.072)
          ..quadraticBezierTo(cx - hw * 0.28, ty - ed * 0.026, cx, ty - ed * 0.036)
          ..quadraticBezierTo(cx + hw * 0.28, ty - ed * 0.026, cx + hw * 0.90, ty + ed * 0.072)
          ..quadraticBezierTo(cx + hw * 0.55, ty + ed * 0.056, cx, ty + ed * 0.040)
          ..quadraticBezierTo(cx - hw * 0.55, ty + ed * 0.056, cx - hw * 0.90, ty + ed * 0.072)
          ..close();
        canvas.drawPath(wrap, Paint()..color = Colors.black.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawPath(wrap,
            Paint()..style = PaintingStyle.fill
              ..shader = LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_lighten(base, 0.22), base, _darken(base, 0.15), _lighten(base, 0.10)],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ).createShader(Rect.fromLTRB(-hw, ty - ed * 0.04, hw, ty + ed * 0.08)));
        canvas.drawPath(wrap, edgePaint);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BEARD  — natural gradient fill · realistic stubble / shape
  // ══════════════════════════════════════════════════════════════════════════

  void _paintBeard(Canvas canvas, _FaceGeometry geo, ArItem item) {
    final cx = geo.beardCenter.dx;
    final by = geo.beardCenter.dy;
    final bh = geo.eyeDist * 0.18;
    final hw = geo.faceHalfW * 0.88;

    final bounds = Rect.fromLTRB(cx - hw, by - bh, cx + hw, by + bh * 1.5);
    final gradFill = Paint()
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end:   Alignment.bottomCenter,
        colors: [
          item.primaryColor.withValues(alpha: 0.55),
          item.primaryColor.withValues(alpha: 0.80),
          item.primaryColor.withValues(alpha: 0.60),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bounds);

    switch (item.name) {
      case 'Stubble':
        // Organic stubble: varied-size dots in a face-shaped region
        final rng = math.Random(42);
        for (int i = 0; i < 360; i++) {
          final px = cx - hw + rng.nextDouble() * hw * 2;
          final py = by - bh * 0.6 + rng.nextDouble() * bh * 2.2;
          final r  = 0.8 + rng.nextDouble() * 1.0;
          final a  = 0.25 + rng.nextDouble() * 0.30;
          canvas.drawCircle(Offset(px, py), r,
              Paint()..color = item.primaryColor.withValues(alpha: a));
        }

      case 'Goatee':
        final path = Path()
          ..moveTo(cx - hw * 0.28, by - bh * 0.2)
          ..quadraticBezierTo(cx - hw * 0.32, by + bh * 0.4, cx, by + bh * 0.90)
          ..quadraticBezierTo(cx + hw * 0.32, by + bh * 0.4, cx + hw * 0.28, by - bh * 0.2)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawPath(path, gradFill);

      case 'Anchor':
        // Vertical bar
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, by - bh * 0.20), width: hw * 0.58, height: bh * 0.36), const Radius.circular(4)),
          gradFill,
        );
        // Goatee portion
        final goatee = Path()
          ..moveTo(cx - hw * 0.22, by - bh * 0.22)
          ..quadraticBezierTo(cx, by + bh * 0.68, cx + hw * 0.22, by - bh * 0.22)
          ..close();
        canvas.drawPath(goatee, gradFill);

      default: // Short, Full, Balbo
        final full = Path()
          ..moveTo(cx - hw, by - bh * 0.45)
          ..quadraticBezierTo(cx - hw * 1.08, by + bh * 0.5, cx - hw * 0.78, by + bh)
          ..quadraticBezierTo(cx, by + bh * 1.45, cx + hw * 0.78, by + bh)
          ..quadraticBezierTo(cx + hw * 1.08, by + bh * 0.5, cx + hw, by - bh * 0.45)
          ..close();
        canvas.drawPath(full, Paint()..color = Colors.black.withValues(alpha: 0.20)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawPath(full, gradFill);
        // Fine hair-texture lines
        final rng = math.Random(99);
        for (int i = 0; i < 28; i++) {
          final lx = cx - hw * 0.88 + rng.nextDouble() * hw * 1.76;
          final ly = by - bh * 0.3  + rng.nextDouble() * bh * 1.2;
          canvas.drawLine(
            Offset(lx, ly),
            Offset(lx + rng.nextDouble() * 6 - 3, ly + 4 + rng.nextDouble() * 4),
            Paint()
              ..color       = _darken(item.primaryColor, 0.20).withValues(alpha: 0.40)
              ..strokeWidth = 0.9
              ..strokeCap   = StrokeCap.round,
          );
        }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HAIR COLOUR TINT  — multi-stop gradient blended into hair region
  // ══════════════════════════════════════════════════════════════════════════

  void _paintHairColor(Canvas canvas, _FaceGeometry geo, ArItem item) {
    final hw  = geo.faceHalfW * 1.18;
    final top = geo.headTop.dy - geo.eyeDist * 0.42;
    final bot = geo.leftEye.dy  - geo.eyeDist * 0.20;
    final rect = Rect.fromLTRB(-hw, top, hw, bot);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [
            item.primaryColor.withValues(alpha: 0.78),
            item.primaryColor.withValues(alpha: 0.52),
            item.primaryColor.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 0.75, 1.0],
        ).createShader(rect),
    );

    // Subtle shimmer streaks
    final rng = math.Random(3);
    for (int i = 0; i < 6; i++) {
      final sx = -hw * 0.7 + rng.nextDouble() * hw * 1.4;
      canvas.drawLine(
        Offset(sx, top + (bot - top) * 0.05),
        Offset(sx + rng.nextDouble() * 12 - 6, bot - (bot - top) * 0.12),
        Paint()
          ..color       = Colors.white.withValues(alpha: 0.10 + rng.nextDouble() * 0.10)
          ..strokeWidth = 1.5 + rng.nextDouble() * 1.5
          ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ── Repaint guard ──────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(covariant _ArOverlayPainter old) {
    if (!identical(old.face, face)) return true;
    if (old.items.length != items.length)  return true;
    for (int i = 0; i < items.length; i++) {
      if (!identical(old.items[i], items[i])) return true;
    }
    return false;
  }
}
