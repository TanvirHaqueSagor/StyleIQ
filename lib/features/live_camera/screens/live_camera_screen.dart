import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';

import '../models/live_score.dart';
import '../models/tracked_face.dart';
import '../services/change_detector.dart';
import '../services/face_tracker.dart';
import '../services/live_analysis_service.dart';
import '../services/session_manager.dart';
import '../widgets/ar_overlay.dart';

enum LiveViewMode {
  mirror('Mirror', Icons.self_improvement_rounded),
  remix('Remix', Icons.checkroom_rounded),
  challenge('Challenge', Icons.emoji_events_rounded),
  cultural('Cultural', Icons.public_rounded);

  const LiveViewMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _flashOn = false;

  final _changeDetector = ChangeDetector();
  final _analysisService = LiveAnalysisService();
  final _sessionManager = SessionManager(tier: 'free');
  final _faceTracker = FaceTrackerService();

  TrackedFaceData? _trackedFace;
  StreamSubscription<TrackedFaceData?>? _faceSub;
  Size _previewSize = Size.zero;

  LiveState _state = LiveState.initializing;
  LiveScore? _currentScore;
  LiveOccasion _occasion = LiveOccasion.autoDetect;
  LiveViewMode _mode = LiveViewMode.mirror;

  bool _scoreIsEstimate = false;
  bool _scoreIsVerified = false;

  bool _scorePanelExpanded = false;
  int? _activeDimensionIndex;

  final Map<String, Set<String>> _activeArItems = {};

  Timer? _detectionTimer;
  Timer? _scoredStateTimer;
  Timer? _errorRetryTimer;
  Timer? _rateLimitTimer;
  Timer? _overlayDismissTimer;

  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;

  bool _apiInFlight = false;
  FrameData? _latestFrame;
  CameraImage? _latestCameraImage;

  static const List<String> _dimensionShort = ['CL', 'FT', 'OC', 'TR', 'CO'];
  static const List<String> _dimensionLabels = [
    'Color',
    'Fit',
    'Occasion',
    'Trend',
    'Cohesion',
  ];

  static const List<Color> _dimensionColors = [
    Color(0xFFd4a853),
    Color(0xFF4ecdc4),
    Color(0xFF9b7fe6),
    Color(0xFFe06b7a),
    Color(0xFF5b9cf5),
  ];

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _sessionManager.elapsed);
    });

    _faceSub = _faceTracker.faceStream.listen((data) {
      if (mounted) setState(() => _trackedFace = data);
    });

    if (!kIsWeb) {
      _initCamera();
    } else {
      setState(() => _state = LiveState.error);
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _scoredStateTimer?.cancel();
    _errorRetryTimer?.cancel();
    _rateLimitTimer?.cancel();
    _elapsedTimer?.cancel();
    _overlayDismissTimer?.cancel();
    _faceSub?.cancel();
    _faceTracker.dispose();
    _cameraCtrl?.dispose();
    _changeDetector.reset();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setError();
        return;
      }
      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      debugPrint('[LiveCamera] init error: $e');
      _setError();
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    // iOS MLKit requires BGRA8888 for InputImage.fromBytes to create a valid
    // UIImage. Android uses YUV420 (NV21-compatible). Web has no camera stream.
    final imageFormat = (!kIsWeb && Platform.isIOS)
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.yuv420;

    final ctrl = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: imageFormat,
    );

    try {
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _cameraCtrl = ctrl);

      await ctrl.startImageStream(_onCameraFrame);
      setState(() => _state = LiveState.firstScan);
      _startDetectionTimer();

      await Future.delayed(const Duration(milliseconds: 500));
      _triggerAnalysis();
    } catch (e) {
      debugPrint('[LiveCamera] start error: $e');
      ctrl.dispose();
      _setError();
    }
  }

  void _onCameraFrame(CameraImage image) {
    _latestCameraImage = image;
    final frame = ChangeDetector.fromCameraImage(image);
    if (frame == null) return;
    _latestFrame = frame;

    final ctrl = _cameraCtrl;
    if (ctrl != null && _previewSize != Size.zero) {
      _faceTracker.processFrame(
        image: image,
        controller: ctrl,
        widgetSize: _previewSize,
      );
    }
  }

  void _startDetectionTimer() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(
      const Duration(seconds: 7),
      (_) {
        if (_apiInFlight) return;
        if (_state == LiveState.rateLimited) return;
        if (_sessionManager.isLimitReached) return;
        _triggerAnalysis();
      },
    );
  }

  Future<void> _triggerAnalysis({bool preferSilentCapture = true}) async {
    if (_apiInFlight) return;
    if (_sessionManager.isLimitReached) {
      _showLimitDialog();
      return;
    }

    final frame = _latestFrame;
    if (frame == null) return;

    final hash = ChangeDetector.perceptualHash(frame);
    final cached = _sessionManager.getCachedScore(hash, _occasion);
    if (cached != null) {
      _applyScore(cached, verified: true);
      return;
    }

    setState(() {
      _state = _state == LiveState.scored || _state == LiveState.monitoring
          ? LiveState.analyzing
          : LiveState.firstScan;
      _apiInFlight = true;
      if (_currentScore != null) {
        _scoreIsEstimate = true;
        _scoreIsVerified = false;
      }
    });

    try {
      Uint8List? jpeg;
      if (preferSilentCapture) {
        jpeg = _captureSilentJpegFromStream();
      } else {
        jpeg = await _captureJpeg();
      }

      if (jpeg == null) {
        if (!preferSilentCapture) _setError();
        return;
      }

      final prepared = await LiveAnalysisService.prepareFrame(jpeg);
      final score = await _analysisService.scoreFrame(
        jpegBytes: prepared,
        occasion: _occasion,
        previousScore: _currentScore?.overallScore,
      );

      _changeDetector.markApiCallMade();
      _changeDetector.setReferenceFrame(frame);
      _sessionManager.recordCall(score);
      _sessionManager.cacheScore(hash, _occasion, score);

      if (mounted) {
        HapticFeedback.lightImpact();
        _applyScore(score, verified: true);
      }
    } on DioException catch (e) {
      debugPrint('[LiveCamera] API error: ${e.message}');
      if (e.response?.statusCode == 429) {
        _setRateLimited();
      } else {
        _setError();
      }
    } catch (e) {
      debugPrint('[LiveCamera] analysis error: $e');
      _setError();
    } finally {
      if (mounted) setState(() => _apiInFlight = false);
    }
  }

  void _applyScore(LiveScore score, {required bool verified}) {
    if (!mounted) return;
    setState(() {
      _currentScore = score;
      _state = LiveState.scored;
      _scoreIsEstimate = !verified;
      _scoreIsVerified = verified;
    });

    _scoredStateTimer?.cancel();
    _scoredStateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _state = LiveState.monitoring);
    });
  }

  Future<Uint8List?> _captureJpeg() async {
    try {
      final ctrl = _cameraCtrl;
      if (ctrl == null || !ctrl.value.isInitialized) return null;
      final xFile = await ctrl.takePicture();
      return await xFile.readAsBytes();
    } catch (e) {
      debugPrint('[LiveCamera] capture error: $e');
      return null;
    }
  }

  Uint8List? _captureSilentJpegFromStream() {
    final image = _latestCameraImage;
    if (image == null) return null;

    try {
      final converted = _convertCameraImageToRgb(image);
      if (converted == null) return null;
      return Uint8List.fromList(img.encodeJpg(converted, quality: 85));
    } catch (e) {
      debugPrint('[LiveCamera] silent frame conversion error: $e');
      return null;
    }
  }

  img.Image? _convertCameraImageToRgb(CameraImage image) {
    if (image.format.group == ImageFormatGroup.bgra8888 &&
        image.planes.length == 1) {
      final plane = image.planes.first;
      return img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: plane.bytes.buffer,
        rowStride: plane.bytesPerRow,
        order: img.ChannelOrder.bgra,
      );
    }

    if (image.format.group != ImageFormatGroup.yuv420 ||
        image.planes.length < 3) {
      return null;
    }

    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final rgb = img.Image(width: width, height: height);
    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      final yRow = y * yRowStride;
      final uvRow = (y >> 1) * uvRowStride;
      for (int x = 0; x < width; x++) {
        final yValue = yBytes[yRow + x];
        final uvIndex = uvRow + (x >> 1) * uvPixelStride;
        final uValue = uBytes[uvIndex];
        final vValue = vBytes[uvIndex];

        final c = yValue - 16;
        final d = uValue - 128;
        final e = vValue - 128;

        int r = (298 * c + 409 * e + 128) >> 8;
        int g = (298 * c - 100 * d - 208 * e + 128) >> 8;
        int b = (298 * c + 516 * d + 128) >> 8;

        if (r < 0) r = 0;
        if (r > 255) r = 255;
        if (g < 0) g = 0;
        if (g > 255) g = 255;
        if (b < 0) b = 0;
        if (b > 255) b = 255;

        rgb.setPixelRgb(x, y, r, g, b);
      }
    }
    return rgb;
  }

  void _setError() {
    if (!mounted) return;
    setState(() {
      _state = LiveState.error;
      _apiInFlight = false;
      _scoreIsVerified = false;
    });
    _errorRetryTimer?.cancel();
    _errorRetryTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _state = LiveState.monitoring);
    });
  }

  void _setRateLimited() {
    if (!mounted) return;
    setState(() {
      _state = LiveState.rateLimited;
      _apiInFlight = false;
    });
    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _state = LiveState.monitoring);
    });
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _detectionTimer?.cancel();
    _changeDetector.reset();
    await _cameraCtrl?.stopImageStream();
    await _cameraCtrl?.dispose();
    setState(() => _cameraCtrl = null);
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_cameraCtrl == null) return;
    _flashOn = !_flashOn;
    await _cameraCtrl!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() {});
  }

  Future<void> _captureForFullAnalysis() async {
    final jpeg = await _captureJpeg();
    if (jpeg == null || !mounted) return;
    context.push('/analysis', extra: {
      'bytes': jpeg,
      'name': 'live_capture.jpg',
    });
  }

  Future<void> _shareLook() async {
    final score = _currentScore?.overallScore.round();
    final note = score == null
        ? 'Check out my StyleIQ live session look.'
        : 'I scored $score in StyleIQ Live (${_occasion.label}).';

    try {
      await Share.share(note, subject: 'StyleIQ Live Look');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share unavailable: $e')),
      );
    }
  }

  void _showHdPreviewStub() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'HD Preview pipeline is not wired yet in this build.',
          style: GoogleFonts.dmSans(),
        ),
      ),
    );
  }

  void _activateDimensionOverlay(int index) {
    setState(() => _activeDimensionIndex = index);
    _overlayDismissTimer?.cancel();
    _overlayDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _activeDimensionIndex = null);
    });
  }

  List<double> get _dimensionValues =>
      _currentScore?.dimensions.asList ?? List<double>.filled(5, 0);

  String get _harmonyLabel {
    final color = _currentScore?.dimensions.colorHarmony ?? 0;
    if (color >= 85) return 'Analogous';
    if (color >= 70) return 'Complementary';
    if (color >= 55) return 'Monochromatic';
    return 'Mixed';
  }

  String get _hudHeadline {
    final delta = _currentScore?.deltaNote;
    if (delta != null && delta.trim().isNotEmpty) return delta;
    switch (_state) {
      case LiveState.firstScan:
        return 'Analyzing your style mirror...';
      case LiveState.analyzing:
        return 'Refreshing with latest fit changes';
      case LiveState.monitoring:
        return 'Live mirror active and tracking';
      case LiveState.scored:
        return 'AI-scored with occasion context';
      case LiveState.error:
        return 'Network issue, retrying automatically';
      case LiveState.rateLimited:
        return 'Cooling down before next refinement';
      case LiveState.initializing:
        return 'Setting up live camera engine';
    }
  }

  List<Color> _livePalette() {
    final dims = _dimensionValues;
    final targetCount = (_currentScore == null ? 3 : 5).clamp(3, 5);
    return List.generate(targetCount, (i) {
      final hue = (dims[i] * 3.6 + i * 28) % 360;
      return HSLColor.fromAHSL(1, hue, 0.64, 0.52).toColor();
    });
  }

  Color get _statusDotColor {
    if (_state == LiveState.analyzing || _state == LiveState.firstScan) {
      return const Color(0xFFd4a853);
    }
    if (_state == LiveState.monitoring || _state == LiveState.scored) {
      return const Color(0xFF4ecdc4);
    }
    return const Color(0xFF8A8A8A);
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Session Limit Reached',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You have used all ${_sessionManager.callLimit} live analyses this session.\n\n'
          'Style Pro is still a preview. For now, start a new session later or use standard outfit analysis for your next look.',
          style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.dmSans(color: const Color(0xFFd4a853)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    _previewSize = media.size; // kept in sync for _onCameraFrame
    final bottomInset = media.padding.bottom;
    const trayHeight = 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraLayer(),
          ArOverlay(activeItems: _activeArItems, face: _trackedFace),
          if (_scorePanelExpanded) _buildDismissLayer(),
          _buildDimensionOverlay(),
          _buildTopRightCloseButton(),
          _buildScorePill(),
          if (_scorePanelExpanded) _buildExpandedScorePanel(),
          _buildControlsRow(bottomInset: bottomInset, trayHeight: trayHeight),
          _buildTimeline(bottomInset: bottomInset),
        ],
      ),
    );
  }

  Widget _buildDismissLayer() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _scorePanelExpanded = false;
          });
        },
        child: Container(color: Colors.black.withValues(alpha: 0.10)),
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (kIsWeb) {
      return Container(
        color: const Color(0xFF0a0a0f),
        child: Center(
          child: Text(
            'Live Camera unavailable on web',
            style: GoogleFonts.dmSans(color: Colors.white54),
          ),
        ),
      );
    }

    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFd4a853)),
      );
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.previewSize!.height,
            height: ctrl.value.previewSize!.width,
            child: CameraPreview(ctrl),
          ),
        ),
      ),
    );
  }

  Widget _buildScorePill() {
    final top = MediaQuery.of(context).padding.top + 56;
    final score = _currentScore?.overallScore.round() ?? 0;
    final grade = _currentScore?.letterGrade ?? '?';
    final countText =
        '${_sessionManager.remainingCalls}/${_sessionManager.callLimit}';

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () =>
              setState(() => _scorePanelExpanded = !_scorePanelExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusDot(),
                const SizedBox(width: 8),
                Icon(_mode.icon, size: 14, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  _scoreIsEstimate ? '~$score' : '$score',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFf2d18d),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                _buildGradeBadge(grade),
                if (_scoreIsVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: Color(0xFF4ecdc4),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  countText,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedScorePanel() {
    final top = MediaQuery.of(context).padding.top + 106;
    final score = _currentScore?.overallScore.round() ?? 0;

    return Positioned(
      top: top,
      left: 18,
      right: 18,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F).withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeRow(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _scoreIsEstimate ? '~$score' : '$score',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFf2d18d),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildGradeBadge(_currentScore?.letterGrade ?? '?', size: 32),
                  if (_scoreIsVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF4ecdc4),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _hudHeadline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(5, _buildDimensionRow),
              const SizedBox(height: 10),
              _buildOccasionPills(),
              const SizedBox(height: 8),
              Text(
                '${_sessionManager.remainingCalls} of ${_sessionManager.callLimit} analyses remaining · Session ${_formatDuration(_elapsed)}',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeRow() {
    return Row(
      children: LiveViewMode.values.map((mode) {
        final active = mode == _mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _mode = mode),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: active ? 1.05 : 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 36,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFd4a853) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Center(
                  child: Text(
                    mode.label,
                    style: GoogleFonts.dmSans(
                      color: active
                          ? const Color(0xFF1B1404)
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDimensionRow(int i) {
    final value = _dimensionValues[i];
    return GestureDetector(
      onTap: () => _activateDimensionOverlay(i),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                _dimensionShort[i],
                style: GoogleFonts.dmSans(
                  color: _dimensionColors[i],
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (value / 100).clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _dimensionColors[i],
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: _dimensionColors[i].withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value.round().toString(),
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccasionPills() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: LiveOccasion.values.map((occ) {
          final active = occ == _occasion;
          return GestureDetector(
            onTap: () {
              setState(() => _occasion = occ);
              _changeDetector.markApiCallMade();
              _triggerAnalysis();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFd4a853)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  occ.label,
                  style: GoogleFonts.dmSans(
                    color: active ? const Color(0xFF1B1404) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDimensionOverlay() {
    if (_activeDimensionIndex == null) return const SizedBox.shrink();

    final idx = _activeDimensionIndex!;
    if (idx == 0) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 108,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._livePalette().map(
                    (c) => Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                  Text(
                    _harmonyLabel,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (idx == 1) {
      return Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _FitGuidelinePainter(color: _dimensionColors[1]),
            size: Size.infinite,
          ),
        ),
      );
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _dimensionColors[idx].withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _dimensionColors[idx]),
            ),
            child: Text(
              '${_dimensionLabels[idx]} overlay active',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRightCloseButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(
            Icons.close,
            size: 16,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsRow(
      {required double bottomInset, required double trayHeight}) {
    final bottom = 24 + bottomInset + 20;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-128, 0),
              child: _ControlButton(
                icon:
                    _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                onTap: _toggleFlash,
                size: 36,
                active: _flashOn,
              ),
            ),
            Transform.translate(
              offset: const Offset(-74, 0),
              child: _ControlButton(
                icon: Icons.flip_camera_ios_rounded,
                onTap: _flipCamera,
                size: 36,
              ),
            ),
            GestureDetector(
              onTap: _captureForFullAnalysis,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(74, 0),
              child: _ControlButton(
                icon: Icons.hd_rounded,
                onTap: _showHdPreviewStub,
                size: 36,
                goldOutline: true,
              ),
            ),
            Transform.translate(
              offset: const Offset(128, 0),
              child: _ControlButton(
                icon: Icons.ios_share_rounded,
                onTap: _shareLook,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline({required double bottomInset}) {
    final snapshots = _sessionManager.snapshots;
    final score = _sessionManager.finalScore.round();

    return Positioned(
      left: 12,
      right: 12,
      bottom: math.max(6, bottomInset + 4),
      child: SizedBox(
        height: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TimelinePainter(snapshots: snapshots),
              ),
            ),
            Positioned(
              left: 0,
              child: Text(
                '0:00',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 9,
                ),
              ),
            ),
            Positioned(
              left: snapshots.length < 2
                  ? 30
                  : (snapshots.length - 1) /
                      (snapshots.length - 1) *
                      (MediaQuery.of(context).size.width - 64),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFd4a853), width: 2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    score > 0 ? '$score' : '--',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFd4a853),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeBadge(String grade, {double size = 24}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          colors: [Color(0xFFf3cd7f), Color(0xFFbe8e39)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        grade,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: size == 24 ? 13 : 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStatusDot() {
    final analyzing =
        _state == LiveState.firstScan || _state == LiveState.analyzing;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: analyzing ? 0.6 : 1),
      duration: Duration(milliseconds: analyzing ? 500 : 2000),
      curve: Curves.easeInOut,
      builder: (_, value, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: _statusDotColor.withValues(alpha: value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool goldOutline;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.active = false,
    this.goldOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFd4a853);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: goldOutline
                ? activeColor
                : active
                    ? activeColor
                    : Colors.white.withValues(alpha: 0.25),
            width: goldOutline ? 1.4 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: active || goldOutline ? activeColor : Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<ScoreSnapshot> snapshots;

  _TimelinePainter({required this.snapshots});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final base = Paint()
      ..color = const Color(0xFFd4a853)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (snapshots.length < 2) {
      canvas.drawLine(
          Offset(24, centerY), Offset(size.width - 24, centerY), base);
      return;
    }

    final path = Path();
    for (var i = 0; i < snapshots.length; i++) {
      final t = i / (snapshots.length - 1);
      final x = 24 + (size.width - 48) * t;
      final y = centerY - ((snapshots[i].score - 50) / 100) * 12;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        final delta = snapshots[i].score - snapshots[i - 1].score;
        if (delta.abs() >= 3) {
          canvas.drawCircle(
            Offset(x, y),
            2,
            Paint()
              ..color = delta >= 0
                  ? const Color(0xFF4ecdc4)
                  : const Color(0xFFe06b7a),
          );
        }
      }
    }

    canvas.drawPath(path, base);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.snapshots != snapshots;
  }
}

class _FitGuidelinePainter extends CustomPainter {
  final Color color;

  _FitGuidelinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;

    final yLines = [size.height * 0.34, size.height * 0.5, size.height * 0.66];
    for (final y in yLines) {
      for (double x = 0; x < size.width; x += 14) {
        canvas.drawLine(Offset(x, y), Offset(x + 8, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FitGuidelinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
