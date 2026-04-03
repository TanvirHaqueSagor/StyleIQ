import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:styleiq/features/live_camera/utils/coordinate_transform.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

CoordinateTransform _transform({
  Size imageSize = const Size(640, 480),
  Size widgetSize = const Size(320, 240),
  InputImageRotation rotation = InputImageRotation.rotation0deg,
  bool isFrontCamera = false,
}) =>
    CoordinateTransform(
      imageSize: imageSize,
      widgetSize: widgetSize,
      rotation: rotation,
      isFrontCamera: isFrontCamera,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CoordinateTransform.transformPoint — rotation0deg, rear camera', () {
    test('maps top-left corner (0,0) to widget top-left', () {
      final t = _transform();
      final result = t.transformPoint(0, 0);
      expect(result.dx, closeTo(0, 0.01));
      expect(result.dy, closeTo(0, 0.01));
    });

    test('maps image centre to widget centre', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
      );
      final result = t.transformPoint(320, 240);
      expect(result.dx, closeTo(160, 0.01));
      expect(result.dy, closeTo(120, 0.01));
    });

    test('maps bottom-right corner to widget bottom-right', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
      );
      final result = t.transformPoint(640, 480);
      expect(result.dx, closeTo(320, 0.01));
      expect(result.dy, closeTo(240, 0.01));
    });

    test('scales proportionally when widget is half image size', () {
      final t = _transform(
        imageSize: const Size(1000, 800),
        widgetSize: const Size(500, 400),
      );
      final result = t.transformPoint(200, 400);
      expect(result.dx, closeTo(100, 0.01));
      expect(result.dy, closeTo(200, 0.01));
    });
  });

  group('CoordinateTransform.transformPoint — rotation90deg', () {
    // After 90° CW rotation the image is displayed H-wide × W-tall.
    // Formula: sx = (H - y) / H * sw,  sy = x / W * sh
    test('maps (0,0) to (widgetW, 0)', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        rotation: InputImageRotation.rotation90deg,
      );
      final result = t.transformPoint(0, 0);
      // sx = (480 - 0) / 480 * 320 = 320, sy = 0/640*240 = 0
      expect(result.dx, closeTo(320, 0.01));
      expect(result.dy, closeTo(0, 0.01));
    });

    test('maps image centre to widget centre', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        rotation: InputImageRotation.rotation90deg,
      );
      // sx = (480-240)/480*320 = 160, sy = 320/640*240 = 120
      final result = t.transformPoint(320, 240);
      expect(result.dx, closeTo(160, 0.01));
      expect(result.dy, closeTo(120, 0.01));
    });
  });

  group('CoordinateTransform.transformPoint — rotation180deg', () {
    test('maps top-left (0,0) to widget bottom-right', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        rotation: InputImageRotation.rotation180deg,
      );
      // sx = (640-0)/640*320 = 320, sy = (480-0)/480*240 = 240
      final result = t.transformPoint(0, 0);
      expect(result.dx, closeTo(320, 0.01));
      expect(result.dy, closeTo(240, 0.01));
    });

    test('maps image centre to widget centre', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        rotation: InputImageRotation.rotation180deg,
      );
      final result = t.transformPoint(320, 240);
      expect(result.dx, closeTo(160, 0.01));
      expect(result.dy, closeTo(120, 0.01));
    });

    test('maps bottom-right to widget top-left', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        rotation: InputImageRotation.rotation180deg,
      );
      // sx = (640-640)/640*320 = 0, sy = (480-480)/480*240 = 0
      final result = t.transformPoint(640, 480);
      expect(result.dx, closeTo(0, 0.01));
      expect(result.dy, closeTo(0, 0.01));
    });
  });

  group('CoordinateTransform.transformPoint — rotation270deg', () {
    test('maps (0,0) to (0, widgetH)', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        rotation: InputImageRotation.rotation270deg,
      );
      // sx = 0/480*320 = 0, sy = (640-0)/640*240 = 240
      final result = t.transformPoint(0, 0);
      expect(result.dx, closeTo(0, 0.01));
      expect(result.dy, closeTo(240, 0.01));
    });

    test('maps image centre to widget centre', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        rotation: InputImageRotation.rotation270deg,
      );
      // sx = 240/480*320=160, sy = (640-320)/640*240=120
      final result = t.transformPoint(320, 240);
      expect(result.dx, closeTo(160, 0.01));
      expect(result.dy, closeTo(120, 0.01));
    });
  });

  group('CoordinateTransform — front camera mirror', () {
    test('mirrors X for rotation0deg front camera', () {
      final rear = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        isFrontCamera: false,
      );
      final front = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        isFrontCamera: true,
      );
      final rearResult = rear.transformPoint(100, 100);
      final frontResult = front.transformPoint(100, 100);
      // X should be mirrored: widgetW - rearX = 320 - 50 = 270
      expect(frontResult.dx, closeTo(320 - rearResult.dx, 0.01));
      // Y unchanged
      expect(frontResult.dy, closeTo(rearResult.dy, 0.01));
    });

    test('front camera centre maps to widget centre (X symmetric)', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        isFrontCamera: true,
      );
      // Centre: (320, 240) → rearX = 160 → frontX = 320-160 = 160
      final result = t.transformPoint(320, 240);
      expect(result.dx, closeTo(160, 0.01));
      expect(result.dy, closeTo(120, 0.01));
    });
  });

  group('CoordinateTransform.transformRect', () {
    test('transforms all four corners and returns normalized rect', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
      );
      final rect = t.transformRect(const Rect.fromLTRB(0, 0, 640, 480));
      expect(rect.left, closeTo(0, 0.01));
      expect(rect.top, closeTo(0, 0.01));
      expect(rect.right, closeTo(320, 0.01));
      expect(rect.bottom, closeTo(240, 0.01));
    });

    test('partial rect maps proportionally', () {
      final t = _transform(
        imageSize: const Size(1000, 1000),
        widgetSize: const Size(500, 500),
      );
      final rect = t.transformRect(const Rect.fromLTRB(250, 250, 750, 750));
      expect(rect.left, closeTo(125, 0.01));
      expect(rect.top, closeTo(125, 0.01));
      expect(rect.right, closeTo(375, 0.01));
      expect(rect.bottom, closeTo(375, 0.01));
    });

    test('returned rect is normalized (left <= right)', () {
      // Front camera mirror can invert X — fromPoints normalizes this
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
        isFrontCamera: true,
        rotation: InputImageRotation.rotation0deg,
      );
      final rect = t.transformRect(const Rect.fromLTRB(100, 50, 300, 200));
      expect(rect.left, lessThanOrEqualTo(rect.right));
      expect(rect.top, lessThanOrEqualTo(rect.bottom));
    });

    test('zero-size rect maps to a point (or near-zero rect)', () {
      final t = _transform(
        imageSize: const Size(640, 480),
        widgetSize: const Size(320, 240),
      );
      final rect = t.transformRect(const Rect.fromLTRB(100, 100, 100, 100));
      expect(rect.width, closeTo(0, 0.01));
      expect(rect.height, closeTo(0, 0.01));
    });
  });
}
