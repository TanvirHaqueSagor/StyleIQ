import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/widgets/dark_analysis_theme.dart';
import 'package:styleiq/features/analysis/widgets/painters/video_overlay_painter.dart';

/// 20-second animated style breakdown player.
/// Overlay is rendered via [StyleVideoPainter] on top of the outfit photo.
class StyleVideoPlayer extends StatefulWidget {
  final StyleAnalysis analysis;
  final Uint8List? imageBytes;

  const StyleVideoPlayer({
    super.key,
    required this.analysis,
    this.imageBytes,
  });

  @override
  State<StyleVideoPlayer> createState() => _StyleVideoPlayerState();
}

class _StyleVideoPlayerState extends State<StyleVideoPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _isPlaying = false;
  bool _isCompleted = false;

  static const _totalSeconds = 20.0;
  // phase boundaries in seconds
  static const _phaseStarts = [0.0, 2.0, 5.5, 8.5, 11.0, 13.5, 16.0];
  static const _phaseNames  = ['Intro', 'Color', 'Fit', 'Occasion', 'Trend', 'Cohesion', 'Reveal'];
  static const _phaseColors = [
    DarkAnalysisTheme.textMuted,
    DarkAnalysisTheme.gold,
    DarkAnalysisTheme.teal,
    DarkAnalysisTheme.violet,
    DarkAnalysisTheme.rose,
    DarkAnalysisTheme.blue,
    DarkAnalysisTheme.gold,
  ];

  int get _currentPhase {
    final t = _ctrl.value * _totalSeconds;
    int phase = 0;
    for (int i = 0; i < _phaseStarts.length; i++) {
      if (t >= _phaseStarts[i]) phase = i;
    }
    return phase;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() { _isPlaying = false; _isCompleted = true; });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _play() {
    setState(() { _isPlaying = true; _isCompleted = false; });
    if (_ctrl.value >= 1.0) _ctrl.value = 0;
    _ctrl.forward();
  }

  void _pause() {
    setState(() => _isPlaying = false);
    _ctrl.stop();
  }

  void _replay() {
    _ctrl.value = 0;
    _play();
  }

  void _seekToPhase(int phase) {
    final t = _phaseStarts[phase] / _totalSeconds;
    _ctrl.value = t;
    if (!_isPlaying) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: _isPlaying ? _pause : (_isCompleted ? _replay : _play),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Background photo (Ken Burns zoom) ──────────────────────
                  _buildPhotoLayer(),
                  // ── Animated overlay ────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => CustomPaint(
                      painter: StyleVideoPainter(
                        elapsedSeconds: _ctrl.value * _totalSeconds,
                        analysis: widget.analysis,
                      ),
                    ),
                  ),
                  // ── Play / pause / replay button ────────────────────────────
                  if (!_isPlaying) _buildPlayButton(),
                  // ── Progress bar ─────────────────────────────────────────────
                  if (_ctrl.value > 0 || _isCompleted) _buildProgressBar(),
                  // ── Completion buttons ───────────────────────────────────────
                  if (_isCompleted) _buildCompletionOverlay(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ── Phase dots ────────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => _buildPhaseDots(),
        ),
      ],
    );
  }

  Widget _buildPhotoLayer() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        // Ken Burns: 1.0x → 1.05x over 20s
        final scale = 1.0 + 0.05 * _ctrl.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.imageBytes != null
          ? Image.memory(widget.imageBytes!, fit: BoxFit.cover)
          : const ColoredBox(color: DarkAnalysisTheme.surface),
    );
  }

  Widget _buildPlayButton() {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: DarkAnalysisTheme.gold.withValues(alpha: 0.6), width: 2),
        ),
        child: Icon(
          _isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
          color: DarkAnalysisTheme.gold,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Phase label
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _phaseNames[_currentPhase],
                style: TextStyle(
                  color: _phaseColors[_currentPhase],
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
            // Progress track
            Container(
              height: 3,
              color: Colors.black.withValues(alpha: 0.3),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _ctrl.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DarkAnalysisTheme.gold, _phaseColors[_currentPhase]],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseDots() {
    final current = _currentPhase;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_phaseNames.length, (i) {
        final isActive = i == current && _ctrl.value > 0;
        final isPassed = _ctrl.value * _totalSeconds > _phaseStarts[i] + 0.5;
        return GestureDetector(
          onTap: () => _seekToPhase(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isPassed
                  ? _phaseColors[i].withValues(alpha: 0.8)
                  : DarkAnalysisTheme.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCompletionOverlay() {
    return Positioned(
      bottom: 20, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Replay
          GestureDetector(
            onTap: _replay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: DarkAnalysisTheme.gold),
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, color: DarkAnalysisTheme.gold, size: 14),
                  SizedBox(width: 4),
                  Text('Replay', style: TextStyle(color: DarkAnalysisTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
