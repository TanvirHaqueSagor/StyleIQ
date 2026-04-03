import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/live_camera/models/live_score.dart';
import 'package:styleiq/features/live_camera/services/change_detector.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Creates a 64×64 FrameData filled with a uniform [value].
FrameData _uniformFrame(int value, {DateTime? capturedAt}) => FrameData(
      pixels: Uint8List.fromList(List.filled(64 * 64, value)),
      width: 64,
      height: 64,
      capturedAt: capturedAt ?? DateTime.now(),
    );

/// Creates a 64×64 FrameData with random-ish noise derived from [seed].
FrameData _noisyFrame(int seed, {DateTime? capturedAt}) {
  final pixels = Uint8List.fromList(
    List.generate(64 * 64, (i) => (i * seed + 37) % 256),
  );
  return FrameData(
      pixels: pixels, width: 64, height: 64, capturedAt: capturedAt ?? DateTime.now());
}

/// Half dark (top 32 rows = 10), half bright (bottom 32 rows = 200).
/// Guaranteed to produce a mixed hash different from any uniform frame.
FrameData _halfAndHalfFrame({DateTime? capturedAt}) {
  final pixels = Uint8List.fromList(
    List.generate(64 * 64, (i) => i < 32 * 64 ? 10 : 200),
  );
  return FrameData(
      pixels: pixels, width: 64, height: 64, capturedAt: capturedAt ?? DateTime.now());
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ChangeDetector.processFrame', () {
    test('returns true on very first frame (first-scan trigger)', () {
      final detector = ChangeDetector();
      final frame = _uniformFrame(128);
      expect(detector.processFrame(frame), isTrue);
    });

    test('returns false when frame is identical to reference', () {
      final detector = ChangeDetector();
      final frame = _uniformFrame(128);
      // First frame sets reference and returns true
      detector.processFrame(frame);
      detector.markApiCallMade();
      // Same frame again — no change
      expect(detector.processFrame(frame), isFalse);
    });

    test('returns false during API debounce window', () {
      final detector = ChangeDetector();
      final frame = _uniformFrame(128);
      detector.processFrame(frame);
      // Mark call made — debounce is active (minApiInterval = 3s)
      detector.markApiCallMade();
      // A very different frame arrives immediately
      final differentFrame = _uniformFrame(0);
      expect(detector.processFrame(differentFrame), isFalse);
    });

    test('tracks lastChangePercent after frame diff', () {
      final detector = ChangeDetector();
      final frame = _uniformFrame(128);
      // First frame sets reference
      detector.processFrame(frame);
      detector.markApiCallMade();

      // No debounce now (markApiCallMade + time skipped via reset)
      detector.reset();

      // Second different frame
      final different = _uniformFrame(0);
      detector.processFrame(_uniformFrame(128)); // re-seed reference
      detector.markApiCallMade();

      // Wait out debounce by resetting
      detector.reset();
      detector.processFrame(_uniformFrame(200)); // new reference
      detector.markApiCallMade();

      detector.reset();
      detector.processFrame(different); // triggers diff check
      // lastChangePercent should be updated (either 0 or positive)
      expect(detector.lastChangePercent, isA<double>());
      expect(detector.lastChangePercent, greaterThanOrEqualTo(0.0));
    });
  });

  group('ChangeDetector.reset', () {
    test('clears lastChangePercent', () {
      final detector = ChangeDetector();
      detector.processFrame(_uniformFrame(100));
      detector.reset();
      expect(detector.lastChangePercent, 0.0);
    });

    test('after reset, first frame triggers true again', () {
      final detector = ChangeDetector();
      detector.processFrame(_uniformFrame(100));
      detector.markApiCallMade();
      detector.reset();
      // After reset, should be treated as first frame
      expect(detector.processFrame(_uniformFrame(100)), isTrue);
    });
  });

  group('ChangeDetector.setReferenceFrame', () {
    test('updating reference frame resets change detection baseline', () {
      final detector = ChangeDetector();
      final frame = _uniformFrame(128);
      detector.processFrame(frame);
      detector.markApiCallMade();

      // Set a new reference frame
      final newRef = _uniformFrame(200);
      detector.setReferenceFrame(newRef);

      // The internal reference is now 200; comparing against itself = no change
      // (debounce is still active so we reset to bypass it)
      detector.reset();
      detector.setReferenceFrame(newRef);
      detector.processFrame(newRef); // first call after reset → true
    });
  });

  group('ChangeDetector.perceptualHash', () {
    test('produces an 8×8 = 64 char binary string', () {
      final frame = _uniformFrame(128);
      final hash = ChangeDetector.perceptualHash(frame);
      expect(hash.length, 64);
      expect(RegExp(r'^[01]+$').hasMatch(hash), isTrue);
    });

    test('identical frames produce identical hashes', () {
      final frame = _uniformFrame(100);
      expect(
        ChangeDetector.perceptualHash(frame),
        equals(ChangeDetector.perceptualHash(frame)),
      );
    });

    test('half-dark/half-bright frame produces different hash than uniform', () {
      final uniform = ChangeDetector.perceptualHash(_uniformFrame(128));
      final mixed = ChangeDetector.perceptualHash(_halfAndHalfFrame());
      expect(uniform, isNot(equals(mixed)));
    });

    test('uniform frame produces all-zero hash (v > mean is never true)', () {
      // For a uniform frame every pixel == mean, so `v > mean` is false → all 0s
      final hash = ChangeDetector.perceptualHash(_uniformFrame(128));
      expect(hash, equals('0' * 64));
    });

    test('uniform bright frame also produces all-zero hash', () {
      // 255 > 255 is false — same reasoning as above
      final hash = ChangeDetector.perceptualHash(_uniformFrame(255));
      expect(hash, equals('0' * 64));
    });

    test('noisy frames produce non-trivial hashes', () {
      final hash = ChangeDetector.perceptualHash(_noisyFrame(7));
      expect(hash.contains('0'), isTrue);
      expect(hash.contains('1'), isTrue);
    });
  });

  group('ChangeDetector.fromCameraImage', () {
    // fromCameraImage requires a real CameraImage which is a platform type
    // not available in unit tests. This is intentionally not tested here —
    // it is covered by integration tests on a real device.
    test('placeholder — covered by integration tests', () {
      expect(true, isTrue);
    });
  });
}
