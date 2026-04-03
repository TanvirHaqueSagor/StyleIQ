import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/tracked_face.dart';
import '../utils/coordinate_transform.dart';

/// Drives ML Kit face detection on live camera frames and emits
/// screen-ready [TrackedFaceData] with exponential-moving-average
/// smoothing applied.
///
/// ## Lifecycle
/// ```dart
/// final tracker = FaceTrackerService();
/// tracker.faceStream.listen((data) { ... });
///
/// // Inside CameraController image-stream callback:
/// tracker.processFrame(image: image, controller: ctrl, widgetSize: size);
///
/// // On teardown:
/// await tracker.dispose();
/// ```
///
/// ## Thread safety
/// [processFrame] is debounced — calls that arrive while a detection is
/// already in-flight are dropped.  This keeps the UI responsive without
/// a backing queue.
class FaceTrackerService {
  // ── Tuning constants ───────────────────────────────────────────────────────

  /// EMA blending factor α (0 < α ≤ 1).
  /// 0.45 = smooth but responsive; lower = glassier but laggy.
  static const double _alpha = 0.45;

  /// Minimum gap between consecutive detector invocations.
  /// 66 ms ≈ 15 fps — fast enough for smooth AR without pegging the CPU.
  static const Duration _throttle = Duration(milliseconds: 66);

  // ── Device-orientation → degrees lookup ───────────────────────────────────

  static const Map<DeviceOrientation, int> _orientDeg = {
    DeviceOrientation.portraitUp:    0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown:  180,
    DeviceOrientation.landscapeRight: 270,
  };

  // ── ML Kit face detector ───────────────────────────────────────────────────

  late final FaceDetector _detector;

  // ── Processing state ───────────────────────────────────────────────────────

  bool _busy       = false;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  // ── EMA-smoothed screen-space positions ───────────────────────────────────
  //   All nullable: null means "first frame not yet processed".

  Offset? _sLeftEye, _sRightEye;
  Offset? _sLeftMouth, _sRightMouth, _sBottomMouth;
  Offset? _sLeftEar,  _sRightEar;
  Rect?   _sBBox;
  double  _sRollZ  = 0;
  double  _sYawY   = 0;
  double  _sPitchX = 0;

  // ── Public stream ──────────────────────────────────────────────────────────

  final _ctrl = StreamController<TrackedFaceData?>.broadcast();

  /// Emits a [TrackedFaceData] whenever a face is successfully tracked, or
  /// `null` when no face is present (so the overlay can fall back gracefully).
  Stream<TrackedFaceData?> get faceStream => _ctrl.stream;

  // ── Constructor / dispose ──────────────────────────────────────────────────

  FaceTrackerService() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        // fast mode — good enough for real-time AR at 15 fps
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks:    true,   // we need eye/mouth/ear landmarks
        enableContours:     false,  // contours are expensive; skip them
        enableClassification: false,
        enableTracking:     true,   // stabilises landmark IDs between frames
        minFaceSize:        0.15,   // ignore tiny faces in the background
      ),
    );
  }

  /// Release ML Kit resources.  Call this in the widget's [dispose].
  Future<void> dispose() async {
    await _detector.close();
    await _ctrl.close();
  }

  // ── Frame processing ───────────────────────────────────────────────────────

  /// Process one [CameraImage] frame.
  ///
  /// [controller]  — the active [CameraController]; needed for sensor
  ///                 orientation and lens direction.
  /// [widgetSize]  — the dimensions of the [CameraPreview] widget on screen;
  ///                 needed to scale landmark coordinates to widget pixels.
  ///
  /// Returns immediately (non-blocking).  Results are delivered via
  /// [faceStream].
  Future<void> processFrame({
    required CameraImage        image,
    required CameraController   controller,
    required Size               widgetSize,
  }) async {
    // ── Throttle & guard ───────────────────────────────────────────────────
    final now = DateTime.now();
    if (now.difference(_lastAt) < _throttle) return;
    if (_busy) return;
    _busy   = true;
    _lastAt = now;

    try {
      final inputImage = _toInputImage(image, controller);
      if (inputImage == null) return;

      final faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) {
        _resetSmoothed();
        if (!_ctrl.isClosed) _ctrl.add(null);
        return;
      }

      // Choose the largest face (most prominent / closest to camera).
      final face = faces.reduce(
        (a, b) =>
            a.boundingBox.width * a.boundingBox.height >
                    b.boundingBox.width * b.boundingBox.height
                ? a
                : b,
      );

      final rotation   = _computeRotation(controller);
      final isFront    = controller.description.lensDirection ==
          CameraLensDirection.front;
      final imageSize  = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final xform = CoordinateTransform(
        imageSize:    imageSize,
        widgetSize:   widgetSize,
        rotation:     rotation,
        isFrontCamera: isFront,
      );

      _smooth(face, xform);

      final result = _buildResult();
      if (result != null && !_ctrl.isClosed) _ctrl.add(result);
    } catch (e) {
      debugPrint('[FaceTracker] $e');
    } finally {
      _busy = false;
    }
  }

  // ── InputImage construction ────────────────────────────────────────────────

  InputImage? _toInputImage(CameraImage image, CameraController controller) {
    try {
      final format = _mlkitFormat(image);
      if (format == null) return null;

      // Build a flat byte buffer from all planes without any framing overhead.
      int totalLen = 0;
      for (final p in image.planes) { totalLen += p.bytes.length; }
      final bytes = Uint8List(totalLen);
      int offset = 0;
      for (final p in image.planes) {
        bytes.setRange(offset, offset + p.bytes.length, p.bytes);
        offset += p.bytes.length;
      }

      final bytesPerRow = image.planes[0].bytesPerRow;
      final expectedMin = image.height * bytesPerRow;

      // Guard: ML Kit will throw a native NSAssert / JNI assertion if the byte
      // count is too small for the declared dimensions. Skip the frame rather
      // than crashing.
      if (bytes.length < expectedMin) {
        debugPrint('[FaceTracker] frame too small '
            '(${bytes.length} < $expectedMin), skipping');
        return null;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size:        Size(image.width.toDouble(), image.height.toDouble()),
          rotation:    _computeRotation(controller),
          format:      format,
          bytesPerRow: bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('[FaceTracker] InputImage build: $e');
      return null;
    }
  }

  /// Map Flutter [ImageFormatGroup] to the ML Kit [InputImageFormat].
  InputImageFormat? _mlkitFormat(CameraImage image) {
    switch (image.format.group) {
      case ImageFormatGroup.yuv420:   return InputImageFormat.yuv_420_888;
      case ImageFormatGroup.bgra8888: return InputImageFormat.bgra8888;
      case ImageFormatGroup.nv21:     return InputImageFormat.nv21;
      default:
        debugPrint('[FaceTracker] unsupported format: ${image.format.group}');
        return null;
    }
  }

  // ── Rotation calculation ───────────────────────────────────────────────────

  /// Calculate the [InputImageRotation] to pass to ML Kit metadata.
  ///
  /// iOS: [CameraPreview] applies orientation internally → always 0°.
  /// Android: derive from sensor orientation + device orientation.
  InputImageRotation _computeRotation(CameraController controller) {
    if (!kIsWeb && Platform.isIOS) {
      return InputImageRotation.rotation0deg;
    }

    final sensor = controller.description.sensorOrientation;
    final deviceDeg = _orientDeg[controller.value.deviceOrientation] ?? 0;

    final int compensated;
    if (controller.description.lensDirection == CameraLensDirection.front) {
      // Front camera: sensor + device (additive, mirrors cancel each other)
      compensated = (sensor + deviceDeg) % 360;
    } else {
      // Rear camera: sensor − device
      compensated = (sensor - deviceDeg + 360) % 360;
    }

    return InputImageRotationValue.fromRawValue(compensated) ??
        InputImageRotation.rotation0deg;
  }

  // ── EMA smoothing ──────────────────────────────────────────────────────────

  void _smooth(Face face, CoordinateTransform xform) {
    /// Helper: transform a named landmark and return screen-space offset.
    Offset? toLandmark(FaceLandmarkType type) {
      final landmark = face.landmarks[type];
      if (landmark == null) return null;
      return xform.transformPoint(
        landmark.position.x.toDouble(),
        landmark.position.y.toDouble(),
      );
    }

    _sLeftEye    = _emaOff(_sLeftEye,    toLandmark(FaceLandmarkType.leftEye));
    _sRightEye   = _emaOff(_sRightEye,   toLandmark(FaceLandmarkType.rightEye));
    _sLeftMouth  = _emaOff(_sLeftMouth,  toLandmark(FaceLandmarkType.leftMouth));
    _sRightMouth = _emaOff(_sRightMouth, toLandmark(FaceLandmarkType.rightMouth));
    _sBottomMouth = _emaOff(_sBottomMouth, toLandmark(FaceLandmarkType.bottomMouth));
    _sLeftEar    = _emaOff(_sLeftEar,    toLandmark(FaceLandmarkType.leftEar));
    _sRightEar   = _emaOff(_sRightEar,   toLandmark(FaceLandmarkType.rightEar));

    _sBBox   = _emaRect(_sBBox, xform.transformRect(face.boundingBox));
    _sRollZ  = _emaF(_sRollZ,  face.headEulerAngleZ ?? 0);
    _sYawY   = _emaF(_sYawY,   face.headEulerAngleY ?? 0);
    _sPitchX = _emaF(_sPitchX, face.headEulerAngleX ?? 0);
  }

  void _resetSmoothed() {
    _sLeftEye = _sRightEye = null;
    _sLeftMouth = _sRightMouth = _sBottomMouth = null;
    _sLeftEar   = _sRightEar  = null;
    _sBBox = null;
    _sRollZ = _sYawY = _sPitchX = 0;
  }

  /// EMA blend for [Offset]: `prev * (1−α) + next * α`.
  /// Returns [next] unchanged on first call (prev == null).
  Offset? _emaOff(Offset? prev, Offset? next) {
    if (next == null) return prev;      // new frame has no landmark → keep old
    if (prev == null) return next;      // first frame → seed directly
    return Offset(
      prev.dx * (1 - _alpha) + next.dx * _alpha,
      prev.dy * (1 - _alpha) + next.dy * _alpha,
    );
  }

  Rect? _emaRect(Rect? prev, Rect? next) {
    if (next == null) return prev;
    if (prev == null) return next;
    return Rect.fromLTRB(
      prev.left   * (1 - _alpha) + next.left   * _alpha,
      prev.top    * (1 - _alpha) + next.top    * _alpha,
      prev.right  * (1 - _alpha) + next.right  * _alpha,
      prev.bottom * (1 - _alpha) + next.bottom * _alpha,
    );
  }

  double _emaF(double prev, double next) =>
      prev * (1 - _alpha) + next * _alpha;

  // ── Build [TrackedFaceData] from smoothed state ────────────────────────────

  TrackedFaceData? _buildResult() {
    final le = _sLeftEye;
    final re = _sRightEye;
    final bb = _sBBox;
    // Both eyes and the bounding box are mandatory.
    if (le == null || re == null || bb == null) return null;

    final eyeDist = (re - le).distance;

    // Nose bridge: midpoint between eyes, shifted up by 15 % of eye distance.
    // This aligns the glasses bridge above the nostrils, at the nasal bone.
    final noseBridge = Offset(
      (le.dx + re.dx) / 2,
      (le.dy + re.dy) / 2 - eyeDist * 0.15,
    );

    final lm = _sLeftMouth;
    final rm = _sRightMouth;
    final mouthWidth = (lm != null && rm != null)
        ? (rm - lm).distance
        : eyeDist * 0.55; // anatomical estimate when landmarks missing

    return TrackedFaceData(
      leftEye:    le,
      rightEye:   re,
      noseBridge: noseBridge,
      eyeDistance: eyeDist,
      leftMouth:   lm,
      rightMouth:  rm,
      bottomMouth: _sBottomMouth,
      mouthWidth:  mouthWidth,
      leftEar:     _sLeftEar,
      rightEar:    _sRightEar,
      boundingBox: bb,
      faceCenter:  bb.center,
      headRollDeg: _sRollZ,
      headYawDeg:  _sYawY,
      headPitchDeg: _sPitchX,
    );
  }
}
