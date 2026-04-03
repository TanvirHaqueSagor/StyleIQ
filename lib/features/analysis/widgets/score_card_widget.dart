import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';

class ScoreCardWidget extends StatefulWidget {
  final StyleAnalysis analysis;
  final bool isLoading;

  const ScoreCardWidget({
    super.key,
    required this.analysis,
    this.isLoading = false,
  });

  @override
  State<ScoreCardWidget> createState() => _ScoreCardWidgetState();
}

class _ScoreCardWidgetState extends State<ScoreCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _radarController;
  late Animation<double> _scoreAnim;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scoreAnim = Tween<double>(begin: 0, end: widget.analysis.overallScore)
        .animate(CurvedAnimation(
            parent: _scoreController, curve: Curves.easeOut));
    _scoreController.forward();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    Future.delayed(
      const Duration(milliseconds: 600),
      () { if (mounted) _radarController.forward(); },
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(a),
          if (a.detectedItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildDetectedItems(a),
          ],
          const SizedBox(height: 24),
          _buildRadarSection(a),
          const SizedBox(height: 24),
          _buildStrengths(a),
          if (a.suggestions.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSuggestions(a),
          ],
          if (a.styleInsight.isNotEmpty || _hasTags(a)) ...[
            const SizedBox(height: 24),
            _buildInsight(a),
          ],
          const SizedBox(height: 24),
          _buildShareButton(a),
        ],
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────────

  Widget _buildHero(StyleAnalysis a) {
    final scoreColor = AppTheme.getScoreColor(a.overallScore);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B6B), Color(0xFF124D36)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1B6B).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          // Grade badge — elastic stamp-in animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 3),
            ),
            child: Center(
              child: Text(
                a.letterGrade,
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.2, 0.2),
                end: const Offset(1.0, 1.0),
                curve: Curves.elasticOut,
                duration: 900.ms,
              )
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // Live score counter
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => Text(
              _scoreAnim.value.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const Text(
            'out of 100',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),

          const SizedBox(height: 16),

          // Score fill bar — grows as counter ticks up
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _scoreAnim.value / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: scoreColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: scoreColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Headline
          Text(
            a.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0),

          if (a.aestheticCategory != null) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                a.aestheticCategory!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms)
                .slideY(begin: 0.15, end: 0),
          ],
        ],
      ),
    );
  }

  // ── Detected Items ────────────────────────────────────────────────────────────

  Widget _buildDetectedItems(StyleAnalysis a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('DETECTED OUTFIT'),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: a.detectedItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primaryMain.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                a.detectedItems[i],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryMain,
                ),
              ),
            )
                .animate(delay: Duration(milliseconds: 60 * i))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.2, end: 0),
          ),
        ),
      ],
    );
  }

  // ── Radar Chart ───────────────────────────────────────────────────────────────

  Widget _buildRadarSection(StyleAnalysis a) {
    final dims = a.dimensions;
    final values = [
      dims.colorHarmony.score / 100,
      dims.fitProportion.score / 100,
      dims.occasionMatch.score / 100,
      dims.trendAlignment.score / 100,
      dims.styleCohesion.score / 100,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('STYLE BREAKDOWN'),
        const SizedBox(height: 16),

        // Spider / radar chart
        Center(
          child: AnimatedBuilder(
            animation: _radarController,
            builder: (_, __) => SizedBox(
              width: 230,
              height: 230,
              child: CustomPaint(
                painter: _RadarChartPainter(
                  values: values,
                  labels: const [
                    'Color', 'Fit', 'Occasion', 'Trend', 'Cohesion'
                  ],
                  fillColor: AppTheme.primaryMain,
                  animationValue: CurvedAnimation(
                    parent: _radarController,
                    curve: Curves.easeOut,
                  ).value,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Dimension tiles
        ...dims.asList().asMap().entries.map(
            (e) => _buildDimensionTile(e.key, e.value.key, e.value.value)),
      ],
    );
  }

  Widget _buildDimensionTile(int index, String label, DimensionScore ds) {
    final color = AppTheme.getScoreColor(ds.score);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_dimensionIcon(label), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.dark,
                        )),
                    Text(
                      ds.score.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ds.score / 100,
                    minHeight: 5,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                if (ds.comment.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    ds.comment,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mediumGrey,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.08, end: 0);
  }

  IconData _dimensionIcon(String label) => switch (label) {
        'Color Harmony' => Icons.palette_outlined,
        'Fit & Proportion' => Icons.straighten_outlined,
        'Occasion Match' => Icons.event_outlined,
        'Trend Alignment' => Icons.trending_up_outlined,
        _ => Icons.auto_awesome_outlined,
      };

  // ── Strengths ─────────────────────────────────────────────────────────────────

  Widget _buildStrengths(StyleAnalysis a) {
    if (a.strengths.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('WHAT YOU NAILED'),
        const SizedBox(height: 12),
        ...a.strengths.asMap().entries.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentMain.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.accentMain.withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.accentMain.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppTheme.accentMain, size: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkGrey,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: 70 * e.key))
              .fadeIn(duration: 380.ms)
              .slideX(begin: -0.08, end: 0),
        ),
      ],
    );
  }

  // ── Suggestions ───────────────────────────────────────────────────────────────

  Widget _buildSuggestions(StyleAnalysis a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('LEVEL UP YOUR LOOK'),
        const SizedBox(height: 4),
        const Text(
          'Tap any card to see the full tip',
          style: TextStyle(fontSize: 11, color: AppTheme.mediumGrey),
        ),
        const SizedBox(height: 12),
        ...a.suggestions.asMap().entries
            .map((e) => _buildSuggestionCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildSuggestionCard(int index, Suggestion s) {
    final isOpen = _expanded.contains(index);
    return GestureDetector(
      onTap: () => setState(() {
        isOpen ? _expanded.remove(index) : _expanded.add(index);
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: isOpen
              ? Border.all(
                  color: AppTheme.primaryMain.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            // Collapsed header — always visible
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleToTealGradient,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.change,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.dark,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMain.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.scoreImpact,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentMain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: AppTheme.mediumGrey),
                  ),
                ],
              ),
            ),

            // Expanded body — smooth reveal
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: isOpen
                  ? Padding(
                      padding:
                          const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              s.reason,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.darkGrey,
                                height: 1.55,
                              ),
                            ),
                          ),
                          if (s.budgetOption != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.amber
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.amber
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.savings_outlined,
                                      size: 13, color: AppTheme.amber),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Budget tip: ${s.budgetOption}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.amber,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.08, end: 0);
  }

  // ── Style Insight + Context Tags ──────────────────────────────────────────────

  Widget _buildInsight(StyleAnalysis a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryMain.withValues(alpha: 0.06),
            AppTheme.accentMain.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryMain.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 15, color: AppTheme.primaryMain),
              const SizedBox(width: 7),
              _label('STYLE INSIGHT'),
            ],
          ),
          if (a.styleInsight.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              a.styleInsight,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.darkGrey,
                height: 1.6,
              ),
            ),
          ],
          if (_hasTags(a)) ...[
            const SizedBox(height: 12),
            Column(
              children: [
                if (a.seasonAppropriateness != null)
                  _contextRow(Icons.wb_sunny_outlined, 'Season',
                      a.seasonAppropriateness!, AppTheme.amber),
                if (a.bodyTypeDetected != null)
                  _contextRow(Icons.accessibility_outlined, 'Body',
                      a.bodyTypeDetected!, AppTheme.primaryMain),
                if (a.culturalContext != null)
                  _contextRow(Icons.public_outlined, 'Culture',
                      a.culturalContext!, AppTheme.accentMain),
              ],
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0);
  }

  bool _hasTags(StyleAnalysis a) =>
      a.seasonAppropriateness != null ||
      a.bodyTypeDetected != null ||
      a.culturalContext != null;

  /// Full-width row for long AI-generated context text (season / body / culture).
  /// Avoids chip overflow — text wraps naturally within the card.
  Widget _contextRow(
      IconData icon, String key, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Share Button ──────────────────────────────────────────────────────────────

  Widget _buildShareButton(StyleAnalysis a) {
    return ElevatedButton.icon(
      onPressed: () => _share(a),
      icon: const Icon(Icons.share_outlined, size: 18),
      label: const Text('Share Score Card'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryMain,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 50),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  void _share(StyleAnalysis a) {
    Share.share(
      '🎯 StyleIQ Analysis\n\n'
      'Score: ${a.overallScore.toStringAsFixed(0)}/100 — ${a.letterGrade}\n'
      '${a.headline}\n\n'
      '${a.dimensions.asList().map((e) => '${e.key}: ${e.value.score.toStringAsFixed(0)}/100').join('\n')}\n\n'
      'Get StyleIQ — Your Personal Style Intelligence App!',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.mediumGrey,
          letterSpacing: 1.4,
        ),
      );
}

// ── Radar / Spider Chart ──────────────────────────────────────────────────────

class _RadarChartPainter extends CustomPainter {
  final List<double> values; // 0.0–1.0 for each axis
  final List<String> labels;
  final Color fillColor;
  final double animationValue; // 0.0–1.0 drives the draw-in

  const _RadarChartPainter({
    required this.values,
    required this.labels,
    required this.fillColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - 26;
    const sides = 5;
    const startAngle = -pi / 2;
    const step = 2 * pi / sides;

    // Grid rings
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 4; ring++) {
      final r = maxR * ring / 4;
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final a = startAngle + i * step;
        final pt = Offset(center.dx + r * cos(a), center.dy + r * sin(a));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, gridPaint);
    }

    // Spokes
    for (int i = 0; i < sides; i++) {
      final a = startAngle + i * step;
      canvas.drawLine(
        center,
        Offset(center.dx + maxR * cos(a), center.dy + maxR * sin(a)),
        gridPaint,
      );
    }

    // Data polygon — scales outward as animation progresses
    final dataPath = Path();
    for (int i = 0; i <= sides; i++) {
      final idx = i % sides;
      final v = values[idx] * animationValue;
      final a = startAngle + idx * step;
      final pt = Offset(
        center.dx + maxR * v * cos(a),
        center.dy + maxR * v * sin(a),
      );
      i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
    }

    // Filled area
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = fillColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    // Stroke outline
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Vertex dots
    for (int i = 0; i < sides; i++) {
      final v = values[i] * animationValue;
      final a = startAngle + i * step;
      canvas.drawCircle(
        Offset(
          center.dx + maxR * v * cos(a),
          center.dy + maxR * v * sin(a),
        ),
        4.5,
        Paint()..color = fillColor,
      );
    }

    // Axis labels
    for (int i = 0; i < sides; i++) {
      final a = startAngle + i * step;
      final labelR = maxR + 16;
      final pt = Offset(
        center.dx + labelR * cos(a),
        center.dy + labelR * sin(a),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: AppTheme.darkGrey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, pt - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarChartPainter old) =>
      old.animationValue != animationValue;
}
