import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/live_score.dart';

/// Three display modes for the Score HUD.
enum HudMode { compact, expanded, fullPanel }

class ScoreHud extends StatefulWidget {
  final LiveScore? score;
  final HudMode mode;
  final bool isLoading;
  final bool isEstimate;
  final bool isVerified;
  final String headline;
  final int remainingCalls;
  final int callLimit;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ScoreHud({
    super.key,
    required this.score,
    required this.mode,
    required this.isLoading,
    required this.isEstimate,
    required this.isVerified,
    required this.headline,
    required this.remainingCalls,
    required this.callLimit,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<ScoreHud> createState() => _ScoreHudState();
}

class _ScoreHudState extends State<ScoreHud> with TickerProviderStateMixin {
  late final AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;
  double _displayScore = 0;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  late final AnimationController _deltaCtrl;
  double _deltaValue = 0;

  late final AnimationController _barsCtrl;
  late final List<Animation<double>> _barAnims;

  static const _dimColors = [
    Color(0xFFd4a853),
    Color(0xFF4ecdc4),
    Color(0xFF9b7fe6),
    Color(0xFFe06b7a),
    Color(0xFF5b9cf5),
  ];

  static const _dimLabels = [
    'Color',
    'Fit',
    'Occasion',
    'Trend',
    'Cohesion',
  ];

  @override
  void initState() {
    super.initState();

    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scoreAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic),
    );
    _scoreAnim.addListener(() {
      if (mounted) setState(() => _displayScore = _scoreAnim.value);
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.02), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 50),
    ]).animate(_pulseCtrl);

    _deltaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _barsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _barAnims = List.generate(5, (i) {
      final start = i * 0.1;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _barsCtrl,
          curve: Interval(start, math.min(start + 0.5, 1.0),
              curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(ScoreHud old) {
    super.didUpdateWidget(old);
    final newScore = widget.score?.overallScore ?? 0;
    final oldScore = old.score?.overallScore ?? 0;

    if (newScore != oldScore && widget.score != null) {
      _deltaValue = newScore - oldScore;
      _scoreAnim = Tween<double>(begin: _displayScore, end: newScore).animate(
        CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic),
      );
      _scoreCtrl.forward(from: 0);
      _pulseCtrl.forward(from: 0);
      if (_deltaValue != 0) _deltaCtrl.forward(from: 0);
      _barsCtrl.forward(from: 0);
    }

    if (old.score == null && widget.score != null) {
      _scoreAnim = Tween<double>(begin: 0, end: newScore).animate(
        CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic),
      );
      _scoreCtrl.forward(from: 0);
      _barsCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _pulseCtrl.dispose();
    _deltaCtrl.dispose();
    _barsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnim.value,
          alignment: Alignment.topCenter,
          child: child,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildContainer(),
            if (_deltaValue != 0) _buildDeltaIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildContainer() {
    return Container(
      width: widget.mode == HudMode.fullPanel ? 320 : 286,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF06070C).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreRow(),
          const SizedBox(height: 4),
          _buildHeadline(),
          if (widget.mode != HudMode.compact) ...[
            const SizedBox(height: 8),
            _buildDimensionBars(),
          ],
          if (widget.mode == HudMode.fullPanel) ...[
            const SizedBox(height: 8),
            _buildDetectedItems(),
          ],
          const SizedBox(height: 8),
          _buildCallsRemaining(),
        ],
      ),
    );
  }

  Widget _buildScoreRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        widget.isLoading
            ? const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFd4a853)),
                ),
              )
            : Row(
                children: [
                  if (widget.isEstimate)
                    Text(
                      '~',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFd4a853),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  Text(
                    _displayScore.round().toString(),
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFf6e7c1),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
        const Spacer(),
        if (widget.isVerified)
          AnimatedOpacity(
            opacity: widget.isVerified ? 1 : 0,
            duration: const Duration(milliseconds: 350),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4ecdc4).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFF4ecdc4).withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: Color(0xFF4ecdc4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI verified',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFb7f4ed),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 8),
        _buildGradeBadge(widget.score?.letterGrade ?? '?'),
      ],
    );
  }

  Widget _buildHeadline() {
    return Text(
      widget.headline,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.dmSans(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildGradeBadge(String grade) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.elasticOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: child,
      ),
      child: Container(
        key: ValueKey(grade),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _gradeColor(grade).withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: _gradeColor(grade), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          grade,
          style: GoogleFonts.dmSans(
            color: _gradeColor(grade),
            fontSize: grade.length > 1 ? 10 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionBars() {
    final dims = widget.score?.dimensions.asList ?? List.filled(5, 0.0);

    return Column(
      children: List.generate(5, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.mode == HudMode.fullPanel)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dimLabels[i],
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        dims[i].round().toString(),
                        style: GoogleFonts.dmSans(
                          color: _dimColors[i],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              AnimatedBuilder(
                animation: _barAnims[i],
                builder: (_, __) {
                  final progress = _barAnims[i].value;
                  return Container(
                    height: 5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ((dims[i] / 100) * progress).clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _dimColors[i],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetectedItems() {
    final items = widget.score?.detectedItems ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected',
          style: GoogleFonts.dmSans(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        ...items.take(4).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $item',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildCallsRemaining() {
    final remaining = widget.remainingCalls;
    return Text(
      '$remaining analyses left',
      style: GoogleFonts.dmSans(
        color: remaining <= 2
            ? const Color(0xFFe06b7a)
            : Colors.white.withValues(alpha: 0.35),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDeltaIndicator() {
    final isPositive = _deltaValue > 0;
    final label =
        isPositive ? '+${_deltaValue.round()}' : _deltaValue.round().toString();

    return AnimatedBuilder(
      animation: _deltaCtrl,
      builder: (_, __) {
        final t = _deltaCtrl.value;
        final dy = -28.0 * t;
        final opacity = t < 0.8 ? 1.0 : (1.0 - t) / 0.2;
        return Positioned(
          top: dy,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  color: isPositive
                      ? const Color(0xFF4ecdc4)
                      : const Color(0xFFe06b7a),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'S':
        return const Color(0xFFFFD700);
      case 'A+':
      case 'A':
        return const Color(0xFF4ecdc4);
      case 'B+':
      case 'B':
        return const Color(0xFF5b9cf5);
      case 'C+':
      case 'C':
        return const Color(0xFFf093fb);
      default:
        return const Color(0xFFe06b7a);
    }
  }
}
