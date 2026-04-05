import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/widgets/animated_score_ring.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';

/// Beautiful shareable score card that can be rendered to an image and shared.
class ShareScoreCard extends StatelessWidget {
  final StyleAnalysis analysis;
  final Uint8List? photoBytes;

  const ShareScoreCard({
    super.key,
    required this.analysis,
    this.photoBytes,
  });

  @override
  Widget build(BuildContext context) {
    final score = analysis.overallScore;
    final grade = analysis.letterGrade;
    final color = AppTheme.getScoreColor(score);

    return Container(
      width: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1232), Color(0xFF0F1E2E)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMain.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background glow
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryMain.withValues(alpha: 0.06),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleToTealGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('StyleIQ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ),
                    const Spacer(),
                    Text(
                      analysis.aestheticCategory ?? 'Style Analysis',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Photo + score
                Row(
                  children: [
                    // Photo thumbnail
                    if (photoBytes != null)
                      Container(
                        width: 90, height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: color.withValues(alpha: 0.4), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(photoBytes!, fit: BoxFit.cover),
                        ),
                      ),
                    if (photoBytes != null) const SizedBox(width: 16),

                    // Score ring
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedScoreRing(
                            score: score,
                            grade: grade,
                            size: 100,
                            strokeWidth: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            analysis.headline,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Dimension scores mini grid
                Row(
                  children: [
                    _miniDimension('Color', analysis.dimensions.colorHarmony.score, color),
                    const SizedBox(width: 8),
                    _miniDimension('Fit', analysis.dimensions.fitProportion.score, color),
                    const SizedBox(width: 8),
                    _miniDimension('Occasion', analysis.dimensions.occasionMatch.score, color),
                    const SizedBox(width: 8),
                    _miniDimension('Trend', analysis.dimensions.trendAlignment.score, color),
                    const SizedBox(width: 8),
                    _miniDimension('Style', analysis.dimensions.styleCohesion.score, color),
                  ],
                ),
                const SizedBox(height: 16),

                // Top strength
                if (analysis.strengths.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: color, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            analysis.strengths.first,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'styleiq.app • AI Style Intelligence',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniDimension(String label, double score, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${score.toInt()}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Share button + logic — renders the card to an image then shares it
class ShareButton extends StatefulWidget {
  final StyleAnalysis analysis;
  final Uint8List? photoBytes;

  const ShareButton({super.key, required this.analysis, this.photoBytes});

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  final _screenshotCtrl = ScreenshotController();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _screenshotCtrl.captureFromLongWidget(
        ShareScoreCard(
          analysis: widget.analysis,
          photoBytes: widget.photoBytes,
        ),
        pixelRatio: 3.0,
        context: context,
      );

      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'styleiq_score.png')],
        text:
            'My StyleIQ score: ${widget.analysis.overallScore.toInt()} — ${widget.analysis.letterGrade} grade! ${widget.analysis.headline}',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _share,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: _sharing
              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
              : AppTheme.purpleToTealGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: _sharing
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryMain.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_sharing)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              _sharing ? 'Preparing…' : 'Share My Score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ).animate().scale(begin: const Offset(0.95, 0.95)),
    );
  }
}
