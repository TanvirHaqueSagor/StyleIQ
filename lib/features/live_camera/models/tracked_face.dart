import 'package:flutter/material.dart';

/// Screen-space anchor points produced by [FaceTrackerService].
///
/// Every [Offset] field is already in the coordinate system of the
/// widget that renders the camera preview — safe to hand directly to
/// a [CustomPainter] that sits on top of that widget.
///
/// All values have EMA smoothing applied before being stored here, so
/// consumers can use them frame-by-frame without additional filtering.
class TrackedFaceData {
  // ── Eye anchors ──────────────────────────────────────────────────────────

  /// Centre of the left eye (as seen on screen — already mirror-corrected).
  final Offset leftEye;

  /// Centre of the right eye.
  final Offset rightEye;

  /// Midpoint between the two eye centres, nudged upward by 15 % of
  /// [eyeDistance].  Use this as the **glasses bridge anchor**.
  final Offset noseBridge;

  /// Pixel distance between [leftEye] and [rightEye].
  /// Drives proportional scaling of all overlaid items.
  final double eyeDistance;

  // ── Mouth anchors ────────────────────────────────────────────────────────

  /// Left corner of the mouth.  May be `null` when face is turned sideways.
  final Offset? leftMouth;

  /// Right corner of the mouth.
  final Offset? rightMouth;

  /// Bottom centre of the mouth (lip tip).
  final Offset? bottomMouth;

  /// Horizontal span |rightMouth − leftMouth|.
  /// Falls back to `eyeDistance * 0.55` when mouth landmarks are missing.
  final double mouthWidth;

  // ── Ear anchors ──────────────────────────────────────────────────────────

  /// Left ear lobe position.  Often `null` in selfies — caller falls back to
  /// the bounding-box left edge at eye height.
  final Offset? leftEar;

  /// Right ear lobe position.
  final Offset? rightEar;

  // ── Face bounding box ─────────────────────────────────────────────────────

  /// Face bounding box in screen-space.
  final Rect boundingBox;

  /// Centre of [boundingBox].
  final Offset faceCenter;

  // ── Head rotation (degrees) ───────────────────────────────────────────────

  /// Z-axis (roll): head tilted left (−) or right (+).
  final double headRollDeg;

  /// Y-axis (yaw): head turned left (−) or right (+).
  final double headYawDeg;

  /// X-axis (pitch): head tilted down (−) or up (+).
  final double headPitchDeg;

  const TrackedFaceData({
    required this.leftEye,
    required this.rightEye,
    required this.noseBridge,
    required this.eyeDistance,
    this.leftMouth,
    this.rightMouth,
    this.bottomMouth,
    required this.mouthWidth,
    this.leftEar,
    this.rightEar,
    required this.boundingBox,
    required this.faceCenter,
    required this.headRollDeg,
    required this.headYawDeg,
    required this.headPitchDeg,
  });

  /// Convenience: head roll in radians (for `canvas.rotate()`).
  double get headRollRad => headRollDeg * 3.14159265358979 / 180.0;

  /// Derived: best-guess mouth centre (average of left/right corners if
  /// available, otherwise estimated below nose bridge).
  Offset get mouthCenter {
    final l = leftMouth;
    final r = rightMouth;
    if (l != null && r != null) {
      return Offset((l.dx + r.dx) / 2, (l.dy + r.dy) / 2);
    }
    // Fallback: place mouth ~80 % of eye-distance below the nose bridge
    return Offset(noseBridge.dx, noseBridge.dy + eyeDistance * 0.80);
  }

  /// Derived: best-guess left ear (falls back to bounding-box edge).
  Offset get leftEarOrEdge =>
      leftEar ?? Offset(boundingBox.left, leftEye.dy);

  /// Derived: best-guess right ear.
  Offset get rightEarOrEdge =>
      rightEar ?? Offset(boundingBox.right, rightEye.dy);
}
