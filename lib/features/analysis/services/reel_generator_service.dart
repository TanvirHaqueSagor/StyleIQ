import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/widgets/style_reel_frame.dart';

/// Generates an animated GIF "style reel" from a [StyleAnalysis].
///
/// Captures [_frameCount] off-screen renders of [StyleReelFrame] at evenly-
/// spaced [t] values, then encodes them into an animated GIF using the
/// `image` package's [GifEncoder].
class ReelGeneratorService {
  static const int _frameCount = 30;

  /// Centiseconds per frame (1/100 s). 16 cs = 160 ms ≈ 6 fps.
  static const int _frameDelayCs = 16;

  // Capture at 270×480 (75 % of 360×640) — smaller size avoids quantizer issues
  static const Size _captureSize = Size(270, 480);

  /// Generates the reel and returns both the GIF bytes and, on mobile/desktop,
  /// the path to the saved temporary file.
  ///
  /// [onProgress] is called with values from 0.0 to 1.0 as frames are captured.
  Future<({String? filePath, Uint8List gifBytes})> generate({
    required StyleAnalysis analysis,
    required Uint8List? imageBytes,
    void Function(double progress)? onProgress,
  }) async {
    final sc = ScreenshotController();
    final pngFrames = <Uint8List>[];

    for (int i = 0; i <= _frameCount; i++) {
      final t = i / _frameCount;
      final png = await sc.captureFromWidget(
        StyleReelFrame(analysis: analysis, imageBytes: imageBytes, t: t),
        targetSize: _captureSize,
        pixelRatio: 1.0,
        delay: const Duration(milliseconds: 60),
      );
      pngFrames.add(png);
      onProgress?.call((i + 1) / (_frameCount + 1));
    }

    // Encode captured PNG frames into an animated GIF.
    // Octree quantizer + no dithering avoids NeuralQuantizer RangeErrors.
    final encoder = img.GifEncoder(
      delay: _frameDelayCs,
      repeat: 0,
      quantizerType: img.QuantizerType.octree,
      dither: img.DitherKernel.none,
    );
    for (final png in pngFrames) {
      final frame = img.decodePng(png);
      if (frame != null) encoder.addFrame(frame);
    }
    final gifList = encoder.finish();
    if (gifList == null || gifList.isEmpty) {
      throw StateError('GIF encoder produced no output');
    }
    final gifBytes = Uint8List.fromList(gifList);

    if (kIsWeb) {
      return (filePath: null, gifBytes: gifBytes);
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/styleiq_reel_${DateTime.now().millisecondsSinceEpoch}.gif';
    await File(path).writeAsBytes(gifBytes);
    return (filePath: path, gifBytes: gifBytes);
  }
}
