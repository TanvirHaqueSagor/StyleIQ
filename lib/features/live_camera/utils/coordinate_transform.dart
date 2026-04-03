import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Maps a point from **ML Kit image-space** → **screen/widget-space**.
///
/// ## Why this is needed
///
/// ML Kit returns landmark coordinates in the raw input-image coordinate
/// system (origin top-left, axes aligned with the image bytes as fed in).
/// The [CameraPreview] widget, however, displays the feed after applying
/// sensor-orientation rotation and — for the front camera — a horizontal
/// mirror flip.  Without compensating for these transforms, every overlay
/// item will be misplaced.
///
/// ## The three-step transform
///
/// 1. **Rotation** — swap/negate axes according to [rotation] so that the
///    point lands in the same orientation that [CameraPreview] displays.
/// 2. **Scale** — map from raw-image pixel coordinates to widget pixels.
/// 3. **Mirror** — flip the X axis for front-camera feeds (ML Kit sees the
///    raw, un-mirrored bytes while [CameraPreview] shows the mirror image).
///
/// ## Platform notes
///
/// * **Android** in portrait: the camera sensor is landscape, so ML Kit
///   receives a landscape image.  [rotation] is typically
///   [InputImageRotation.rotation90deg] (rear) or
///   [InputImageRotation.rotation270deg] (front).
/// * **iOS**: [CameraPreview] rotates internally; ML Kit should receive
///   the image at [InputImageRotation.rotation0deg].
class CoordinateTransform {
  /// Dimensions of the image fed to ML Kit (CameraImage.width × height).
  final Size imageSize;

  /// Dimensions of the [CameraPreview] widget on screen.
  final Size widgetSize;

  /// Rotation metadata supplied to ML Kit with [InputImageMetadata].
  final InputImageRotation rotation;

  /// `true` when the active lens is [CameraLensDirection.front].
  final bool isFrontCamera;

  const CoordinateTransform({
    required this.imageSize,
    required this.widgetSize,
    required this.rotation,
    required this.isFrontCamera,
  });

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Transform a single landmark point from image-space to widget-space.
  Offset transformPoint(double x, double y) {
    double sx, sy;

    // ── Step 1: rotation ────────────────────────────────────────────────────
    //
    // The rotation value tells us how many degrees the image must be rotated
    // clockwise to appear "upright".  After that rotation the image dimensions
    // swap for 90° / 270°, and we scale against those swapped dimensions.
    //
    //  rot 0°:   (x,y)  →  x_s = x/W * sw,  y_s = y/H * sh
    //  rot 90°:  rotate CW 90°  →  new origin top-left of rotated image
    //            (x,y)  →  (H-y, x) in the rotated frame
    //            scale: x_s = (H-y)/H * sw,  y_s = x/W * sh
    //  rot 180°: (x,y)  →  ((W-x)/W * sw,  (H-y)/H * sh)
    //  rot 270°: rotate CW 270° (= CCW 90°)
    //            (x,y)  →  (y, W-x) in the rotated frame
    //            scale: x_s = y/H * sw,  y_s = (W-x)/W * sh
    //
    switch (rotation) {
      case InputImageRotation.rotation0deg:
        sx = x / imageSize.width  * widgetSize.width;
        sy = y / imageSize.height * widgetSize.height;

      case InputImageRotation.rotation90deg:
        // Image needs 90° CW rotation to be upright.
        // In the rotated frame: new_x = (H - old_y), new_y = old_x
        // After rotation the "image" is H wide × W tall.
        sx = (imageSize.height - y) / imageSize.height * widgetSize.width;
        sy =  x                     / imageSize.width  * widgetSize.height;

      case InputImageRotation.rotation180deg:
        sx = (imageSize.width  - x) / imageSize.width  * widgetSize.width;
        sy = (imageSize.height - y) / imageSize.height * widgetSize.height;

      case InputImageRotation.rotation270deg:
        // Image needs 270° CW rotation (= 90° CCW) to be upright.
        // In the rotated frame: new_x = old_y, new_y = (W - old_x)
        // After rotation the "image" is H wide × W tall.
        sx =  y / imageSize.height * widgetSize.width;
        sy = (imageSize.width - x) / imageSize.width  * widgetSize.height;
    }

    // ── Step 2: front-camera mirror ──────────────────────────────────────────
    //
    // ML Kit processes the raw (un-mirrored) bytes from the front camera.
    // [CameraPreview] displays the mirror image so the user sees themselves
    // as in a mirror.  Flip X to match.
    if (isFrontCamera) {
      sx = widgetSize.width - sx;
    }

    return Offset(sx, sy);
  }

  /// Transform a [Rect] (e.g. face bounding box) from image-space to
  /// widget-space.  Ensures the returned rect is normalised (left < right).
  Rect transformRect(Rect rect) {
    final tl = transformPoint(rect.left,  rect.top);
    final br = transformPoint(rect.right, rect.bottom);
    // Use fromPoints so that mirror-flipping doesn't produce inverted rects.
    return Rect.fromPoints(tl, br);
  }
}
