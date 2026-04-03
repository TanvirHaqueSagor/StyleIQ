import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../models/live_score.dart';

/// On-device outfit change detection engine.
///
/// Runs at 5fps and uses a 3-step pipeline to detect meaningful outfit changes
/// without triggering on body movement alone:
///
/// 1. **Frame differencing** — pixel-level luminance comparison
/// 2. **Motion stabilization** — waits 1.5s of stillness after a change
/// 3. **Color histogram** — validates outfit genuinely changed, not just pose
///
/// Returns `true` from [processFrame] when an API call should be triggered.
class ChangeDetector {
  // ── Thresholds ──────────────────────────────────────────────────────────────
  static const double _pixelThreshold = 30 / 255; // channel delta to count
  static const double _percentChangeTrigger = 0.15; // 15% pixels must change
  static const double _histogramDistanceThreshold = 0.25;
  static const Duration _stabilizationTime = Duration(milliseconds: 1500);
  static const Duration _minApiInterval = Duration(seconds: 3);

  // ── Internal state ───────────────────────────────────────────────────────────
  FrameData? _lastAnalyzedFrame;
  DateTime? _changeDetectedAt;
  DateTime? _lastApiCallTime;

  /// The pixel percentage that triggered the last detection (0.0–1.0).
  double lastChangePercent = 0;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Record that an API call was just triggered (resets internal debounce).
  void markApiCallMade() {
    _lastApiCallTime = DateTime.now();
    _changeDetectedAt = null;
  }

  /// Force-update the reference frame (after a successful API analysis).
  void setReferenceFrame(FrameData frame) {
    _lastAnalyzedFrame = frame;
  }

  /// Reset all state (on camera screen open/close).
  void reset() {
    _lastAnalyzedFrame = null;
    _changeDetectedAt = null;
    _lastApiCallTime = null;
    lastChangePercent = 0;
  }

  /// Process a camera frame and decide whether to trigger an API call.
  ///
  /// Returns `true` when a genuine outfit change is detected and the user
  /// has been still for at least 1.5 seconds.
  bool processFrame(FrameData current) {

    // ── Debounce guard ────────────────────────────────────────────────────────
    if (_lastApiCallTime != null &&
        DateTime.now().difference(_lastApiCallTime!) < _minApiInterval) {
      return false;
    }

    // ── Step 1: Frame differencing ────────────────────────────────────────────
    if (_lastAnalyzedFrame == null) {
      // First frame ever — set as reference and request first scan
      _lastAnalyzedFrame = current;
      return true;
    }

    final percentChanged = _frameDiff(current, _lastAnalyzedFrame!);
    lastChangePercent = percentChanged;

    if (percentChanged < _percentChangeTrigger) {
      // No significant change — reset stabilization clock
      _changeDetectedAt = null;
      return false;
    }

    // ── Step 2: Motion stabilization ─────────────────────────────────────────
    _changeDetectedAt ??= DateTime.now();
    if (DateTime.now().difference(_changeDetectedAt!) < _stabilizationTime) {
      return false; // waiting for stillness
    }

    // ── Step 3: Color histogram validation ───────────────────────────────────
    final histDist = _colorHistogramDistance(current, _lastAnalyzedFrame!);
    if (histDist < _histogramDistanceThreshold) {
      // Position changed but outfit looks the same (user moved, same clothes)
      _changeDetectedAt = null;
      return false;
    }

    return true; // All checks passed — trigger API call
  }

  // ── Frame extraction helpers ─────────────────────────────────────────────────

  /// Convert a [CameraImage] to a downsampled grayscale [FrameData].
  ///
  /// Target: ~64×64 grid of luminance values for fast comparison.
  static FrameData? fromCameraImage(CameraImage image) {
    try {
      const targetW = 64;
      const targetH = 64;

      if (image.format.group == ImageFormatGroup.yuv420) {
        return _fromYuv420(image, targetW, targetH);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _fromBgra(image, targetW, targetH);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _fromNv21(image, targetW, targetH);
      }
      return null;
    } catch (e) {
      debugPrint('[ChangeDetector] frame convert error: $e');
      return null;
    }
  }

  /// Compute a perceptual hash string for cache keying.
  /// Uses 8×8 downsampled luminance compared to mean.
  static String perceptualHash(FrameData frame) {
    const size = 8;
    final sampled = List.filled(size * size, 0);

    final xStep = frame.width / size;
    final yStep = frame.height / size;

    for (int gy = 0; gy < size; gy++) {
      for (int gx = 0; gx < size; gx++) {
        final px = (gx * xStep + xStep / 2).round().clamp(0, frame.width - 1);
        final py = (gy * yStep + yStep / 2).round().clamp(0, frame.height - 1);
        sampled[gy * size + gx] = frame.pixels[py * frame.width + px];
      }
    }

    final mean = sampled.fold(0, (a, b) => a + b) / sampled.length;
    final buffer = StringBuffer();
    for (final v in sampled) {
      buffer.write(v > mean ? '1' : '0');
    }
    return buffer.toString();
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  double _frameDiff(FrameData a, FrameData b) {
    final minLen = math.min(a.pixels.length, b.pixels.length);
    if (minLen == 0) return 0;
    int changed = 0;
    for (int i = 0; i < minLen; i++) {
      if ((a.pixels[i] - b.pixels[i]).abs() / 255 > _pixelThreshold) {
        changed++;
      }
    }
    return changed / minLen;
  }

  double _colorHistogramDistance(FrameData a, FrameData b) {
    const buckets = 16;
    final histA = List.filled(buckets, 0.0);
    final histB = List.filled(buckets, 0.0);

    for (final v in a.pixels) {
      histA[(v * buckets ~/ 256).clamp(0, buckets - 1)]++;
    }
    for (final v in b.pixels) {
      histB[(v * buckets ~/ 256).clamp(0, buckets - 1)]++;
    }

    // Normalize
    final nA = a.pixels.isNotEmpty ? a.pixels.length.toDouble() : 1;
    final nB = b.pixels.isNotEmpty ? b.pixels.length.toDouble() : 1;
    for (int i = 0; i < buckets; i++) {
      histA[i] /= nA;
      histB[i] /= nB;
    }

    // Chi-squared distance
    double dist = 0;
    for (int i = 0; i < buckets; i++) {
      final sum = histA[i] + histB[i];
      if (sum > 0) {
        dist += (histA[i] - histB[i]) * (histA[i] - histB[i]) / sum;
      }
    }
    return dist;
  }

  // YUV420: Y plane is grayscale luminance
  static FrameData _fromYuv420(CameraImage img, int tw, int th) {
    final yPlane = img.planes[0];
    final srcW = img.width;
    final srcH = img.height;
    final pixels = Uint8List(tw * th);

    for (int ty = 0; ty < th; ty++) {
      for (int tx = 0; tx < tw; tx++) {
        final sx = (tx * srcW / tw).round().clamp(0, srcW - 1);
        final sy = (ty * srcH / th).round().clamp(0, srcH - 1);
        final idx = sy * yPlane.bytesPerRow + sx;
        pixels[ty * tw + tx] =
            idx < yPlane.bytes.length ? yPlane.bytes[idx] : 0;
      }
    }
    return FrameData(
        pixels: pixels,
        width: tw,
        height: th,
        capturedAt: DateTime.now());
  }

  // NV21: Y plane first
  static FrameData _fromNv21(CameraImage img, int tw, int th) =>
      _fromYuv420(img, tw, th);

  // BGRA8888: single interleaved plane, R=idx+2, G=idx+1, B=idx
  static FrameData _fromBgra(CameraImage img, int tw, int th) {
    final plane = img.planes[0];
    final srcW = img.width;
    final srcH = img.height;
    final pixels = Uint8List(tw * th);

    for (int ty = 0; ty < th; ty++) {
      for (int tx = 0; tx < tw; tx++) {
        final sx = (tx * srcW / tw).round().clamp(0, srcW - 1);
        final sy = (ty * srcH / th).round().clamp(0, srcH - 1);
        final base = sy * plane.bytesPerRow + sx * 4;
        if (base + 2 < plane.bytes.length) {
          final b = plane.bytes[base];
          final g = plane.bytes[base + 1];
          final r = plane.bytes[base + 2];
          // Luminance: 0.299R + 0.587G + 0.114B
          pixels[ty * tw + tx] =
              (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
        }
      }
    }
    return FrameData(
        pixels: pixels,
        width: tw,
        height: th,
        capturedAt: DateTime.now());
  }
}
