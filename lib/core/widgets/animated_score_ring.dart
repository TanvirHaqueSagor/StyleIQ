import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:styleiq/core/theme/app_theme.dart';

/// Animated circular score ring with grade label in the centre.
/// Animates from 0 to [score] over [duration].
class AnimatedScoreRing extends StatefulWidget {
  final double score;
  final String? grade;
  final double size;
  final double strokeWidth;
  final Duration duration;
  final TextStyle? scoreStyle;
  final TextStyle? gradeStyle;
  final bool showLabel;

  const AnimatedScoreRing({
    super.key,
    required this.score,
    this.grade,
    this.size = 120,
    this.strokeWidth = 10,
    this.duration = const Duration(milliseconds: 1200),
    this.scoreStyle,
    this.gradeStyle,
    this.showLabel = true,
  });

  @override
  State<AnimatedScoreRing> createState() => _AnimatedScoreRingState();
}

class _AnimatedScoreRingState extends State<AnimatedScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late Animation<double> _displayScore;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _displayScore = Tween<double>(begin: 0, end: widget.score).animate(_progress);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedScoreRing old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _displayScore = Tween<double>(begin: old.score, end: widget.score)
          .animate(_progress);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getScoreColor(widget.score);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final pct = _progress.value;
        final displayed = _displayScore.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: pct,
              color: color,
              strokeWidth: widget.strokeWidth,
              bgColor: color.withValues(alpha: 0.12),
            ),
            child: widget.showLabel
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayed.toInt().toString(),
                          style: widget.scoreStyle ??
                              TextStyle(
                                fontSize: widget.size * 0.28,
                                fontWeight: FontWeight.w800,
                                color: color,
                                height: 1.0,
                              ),
                        ),
                        if (widget.grade != null)
                          Text(
                            widget.grade!,
                            style: widget.gradeStyle ??
                                TextStyle(
                                  fontSize: widget.size * 0.14,
                                  fontWeight: FontWeight.w700,
                                  color: color.withValues(alpha: 0.8),
                                ),
                          ),
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color bgColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Glow layer
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Foreground arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.7), color],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Compact dimension bar used in the breakdown section
class DimensionBar extends StatefulWidget {
  final String label;
  final double score;
  final double height;

  const DimensionBar({
    super.key,
    required this.label,
    required this.score,
    this.height = 6,
  });

  @override
  State<DimensionBar> createState() => _DimensionBarState();
}

class _DimensionBarState extends State<DimensionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getScoreColor(widget.score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: AppTheme.mediumGrey)),
            Text('${widget.score.toInt()}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(widget.height),
            child: LinearProgressIndicator(
              value: (widget.score / 100) * _anim.value,
              minHeight: widget.height,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
