import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/widgets/dark_analysis_theme.dart';
import 'package:styleiq/features/analysis/widgets/painters/analysis_painters.dart';
import 'package:styleiq/features/analysis/widgets/style_video_player.dart';
import 'package:styleiq/features/analysis/services/reel_generator_service.dart';

/// Premium dark-theme analysis results card matching the HTML design spec.
class DarkScoreCardWidget extends StatefulWidget {
  final StyleAnalysis analysis;
  final Uint8List? imageBytes;

  const DarkScoreCardWidget({
    super.key,
    required this.analysis,
    this.imageBytes,
  });

  @override
  State<DarkScoreCardWidget> createState() => _DarkScoreCardWidgetState();
}

class _DarkScoreCardWidgetState extends State<DarkScoreCardWidget>
    with TickerProviderStateMixin {
  late final AnimationController _scoreController; // ring + counter
  late final AnimationController _radarController; // radar draw-in
  late final AnimationController _spinController; // photo frame border
  late final Animation<double> _scoreAnim;

  Uint8List? _reelBytes;
  bool _reelGenerating = false;
  double _reelProgress = 0;
  bool _easyMode = true;
  bool _showAfter = true;
  int _selectedMockupIndex = 0;

  // ── Style reel generation ─────────────────────────────────────────────────────

  Future<void> _generateReel() async {
    setState(() {
      _reelGenerating = true;
      _reelProgress = 0;
    });
    try {
      final result = await ReelGeneratorService().generate(
        analysis: widget.analysis,
        imageBytes: widget.imageBytes,
        onProgress: (p) {
          if (mounted) setState(() => _reelProgress = p);
        },
      );
      if (mounted) {
        setState(() {
          _reelBytes = result.gifBytes;
          _reelGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _reelGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate reel: $e'),
            backgroundColor: DarkAnalysisTheme.rose,
          ),
        );
      }
    }
  }

  Future<void> _shareReel() async {
    if (_reelBytes == null) return;
    await Share.shareXFiles(
      [
        XFile.fromData(
          _reelBytes!,
          name: 'styleiq_reel.gif',
          mimeType: 'image/gif',
        ),
      ],
      text: 'My StyleIQ Score: ${widget.analysis.overallScore.round()}/100 '
          '${widget.analysis.letterGrade} — Analyzed by StyleIQ AI',
    );
  }

  // ── Computed helpers ─────────────────────────────────────────────────────────

  // Computed once at initState time — never recalculated on rebuild.
  late final int _totalImpact;
  late final double _improvedScore;
  late final List<String> _previewLabels;

  String get _easySummaryText {
    final summary = widget.analysis.easySummary?.trim();
    if (summary != null && summary.isNotEmpty) return summary;
    if (widget.analysis.suggestions.isEmpty) {
      return 'This outfit already feels coherent. Keep the strong pieces and repeat what is working.';
    }
    return 'Your outfit has a solid base. A few targeted changes could make it look more intentional and easier to read.';
  }

  String get _improvedNarrativeText {
    final narrative = widget.analysis.improvedLookNarrative?.trim();
    if (narrative != null && narrative.isNotEmpty) return narrative;
    return 'With the suggested changes, this look would feel cleaner, more balanced, and easier to understand at a glance.';
  }

  List<GeneratedMockup> get _mockups {
    if (widget.analysis.generatedMockups.isNotEmpty) {
      return widget.analysis.generatedMockups;
    }
    return [
      GeneratedMockup(
        id: 'fallback',
        label: 'Recommended Look',
        imageUrl: widget.analysis.imageUrl ?? '',
        appliedChanges: _previewLabels,
        whyItWorks: _improvedNarrativeText,
        provenance: 'AI-directed preview based on your uploaded outfit photo.',
        isPrimary: true,
      ),
    ];
  }

  GeneratedMockup get _currentMockup =>
      _mockups[_selectedMockupIndex.clamp(0, _mockups.length - 1)];

  LinearGradient _gradeGradient(String grade) {
    if (grade == 'S') {
      return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFffd700), Color(0xFFff8c00)]);
    }
    if (grade.startsWith('A')) {
      return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4ecdc4), Color(0xFF44a08d)]);
    }
    if (grade.startsWith('B')) {
      return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5b9cf5), Color(0xFF667eea)]);
    }
    return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)]);
  }

  // ── Dimension config ─────────────────────────────────────────────────────────

  static const _dimEmojis = ['🎨', '📐', '🎯', '🔥', '🧩'];
  static const _dimWeights = ['25%', '25%', '20%', '15%', '15%'];
  static const _dimColors = [
    DarkAnalysisTheme.gold,
    DarkAnalysisTheme.teal,
    DarkAnalysisTheme.violet,
    DarkAnalysisTheme.rose,
    DarkAnalysisTheme.blue,
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Compute expensive values once — reused on every rebuild.
    _totalImpact = widget.analysis.suggestions.fold(0, (sum, s) {
      final match = RegExp(r'[+-]?\d+').firstMatch(s.scoreImpact);
      if (match == null) return sum;
      final val = int.tryParse(match.group(0) ?? '0') ?? 0;
      return sum + (s.scoreImpact.trimLeft().startsWith('-') ? -val : val);
    });
    _improvedScore =
        (widget.analysis.overallScore + _totalImpact).clamp(0, 100).toDouble();
    final quickWins = widget.analysis.quickWins
        .where((e) => e.trim().isNotEmpty)
        .take(3)
        .toList();
    _previewLabels = quickWins.isNotEmpty
        ? quickWins
        : widget.analysis.suggestions
            .map((s) => s.change.trim())
            .where((e) => e.isNotEmpty)
            .take(3)
            .toList();

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _scoreAnim = Tween<double>(
      begin: 0,
      end: widget.analysis.overallScore,
    ).animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeOut));
    _scoreController.forward();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        if (mounted) _radarController.forward();
      },
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _radarController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  // ── Root ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(a),
        _buildWaveDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildScoreReveal(a),
              const SizedBox(height: 48),
              _buildInteractionControls(),
              const SizedBox(height: 48),
              _buildEasyReadSection(a),
              const SizedBox(height: 48),
              _buildVisualPreviewSection(a),
              if (!_easyMode) ...[
                const SizedBox(height: 48),
                _buildVideoSection(),
                const SizedBox(height: 48),
                _buildRadarSection(a),
                const SizedBox(height: 48),
                _buildDimensionsSection(a),
              ],
              const SizedBox(height: 48),
              _buildComparisonSection(a),
              const SizedBox(height: 48),
              _buildStrengthsSection(a),
              const SizedBox(height: 48),
              _buildSuggestionsSection(a),
              const SizedBox(height: 48),
              _buildInsightCard(a),
              const SizedBox(height: 48),
              _buildDetectedSection(a),
              if (_hasMetaTags(a)) ...[
                const SizedBox(height: 24),
                _buildMetaTags(a),
              ],
              const SizedBox(height: 48),
              _buildShareSection(a),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 1. HERO — badge + spinning photo frame
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildHero(StyleAnalysis a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        children: [
          // StyleIQ Analysis badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFd4a853).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFFd4a853).withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 14, color: Color(0xFFd4a853)),
                SizedBox(width: 6),
                Text(
                  'STYLEIQ ANALYSIS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Color(0xFFd4a853),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 24),

          // Photo frame with spinning gradient border
          SizedBox(
            width: 206,
            height: 266,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Spinning glow + border — isolated so only the border repaints
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _spinController,
                      builder: (_, __) => CustomPaint(
                        painter: SpinningBorderPainter(
                          angle: _spinController.value * 2 * pi,
                        ),
                      ),
                    ),
                  ),
                ),
                // Photo or placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 200,
                    height: 260,
                    child: widget.imageBytes != null
                        ? Image.memory(
                            widget.imageBytes!,
                            fit: BoxFit.cover,
                            cacheWidth: 400,
                            cacheHeight: 520,
                          )
                        : _buildPhotoPlaceholder(),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 1000.ms).scale(
                begin: const Offset(0.85, 0.85),
                curve: const Cubic(0.16, 1, 0.3, 1),
                duration: 1000.ms,
              ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF12121f)],
        ),
      ),
      child: const Center(
        child:
            Icon(Icons.person_outline_rounded, size: 80, color: Colors.white12),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 2. WAVE DIVIDER
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildWaveDivider() {
    return const SizedBox(
      height: 40,
      child: CustomPaint(
        size: Size(double.infinity, 40),
        painter: WavePainter(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 3. SCORE REVEAL — ring + counter + grade badge + headline
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildScoreReveal(StyleAnalysis a) {
    return Column(
      children: [
        // Ring + number
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _scoreController,
                builder: (_, __) => CustomPaint(
                  size: const Size(180, 180),
                  painter: ScoreRingPainter(
                    score: widget.analysis.overallScore,
                    animationValue: CurvedAnimation(
                      parent: _scoreController,
                      curve: Curves.easeOut,
                    ).value,
                    trackColor: const Color(0xFF1e1e2e),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _scoreAnim,
                    builder: (_, __) => ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFd4a853), Color(0xFFf0d78c)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        _scoreAnim.value.toStringAsFixed(0),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'STYLE SCORE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 3,
                      color: DarkAnalysisTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Grade badge (springs in after ring completes)
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: _gradeGradient(a.letterGrade),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: DarkAnalysisTheme.scoreColor(a.overallScore)
                    .withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              a.letterGrade,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        )
            .animate(delay: 2400.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              curve: const Cubic(0.34, 1.56, 0.64, 1),
              duration: 500.ms,
            )
            .fadeIn(duration: 200.ms),

        const SizedBox(height: 16),

        // Headline — Playfair italic, in quotes
        Text(
          '"${a.headline}"',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: DarkAnalysisTheme.textPrimary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 800.ms, duration: 700.ms)
            .slideY(begin: 0.15, end: 0),

        if (a.aestheticCategory != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: DarkAnalysisTheme.violet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: DarkAnalysisTheme.violet.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              a.aestheticCategory!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: DarkAnalysisTheme.violet,
              ),
            ),
          ).animate().fadeIn(delay: 1000.ms),
        ],
      ],
    )
        .animate()
        .fadeIn(delay: 1000.ms, duration: 800.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildEasyReadSection(StyleAnalysis a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Easy Read'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DarkAnalysisTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DarkAnalysisTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What this means',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: DarkAnalysisTheme.gold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _easySummaryText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.55,
                  color: DarkAnalysisTheme.textPrimary,
                ),
              ),
              if (a.quickWins.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Quick wins',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: DarkAnalysisTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                ...a.quickWins.take(3).map(
                      (win) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: DarkAnalysisTheme.teal,
                                    fontSize: 14)),
                            Expanded(
                              child: Text(
                                win,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: DarkAnalysisTheme.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInteractionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Review Mode'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'Easy',
                selected: _easyMode,
                onTap: () => setState(() => _easyMode = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeButton(
                label: 'Expert',
                selected: !_easyMode,
                onTap: () => setState(() => _easyMode = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarkAnalysisTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DarkAnalysisTheme.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                color: DarkAnalysisTheme.gold,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _easyMode
                      ? 'Focus on the clearest next action, the best recommendation variant, and what to do next.'
                      : 'Show the recommendation variants, score logic, and detailed breakdown together.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: DarkAnalysisTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualPreviewSection(StyleAnalysis a) {
    final labels = _currentMockup.appliedChanges.isNotEmpty
        ? _currentMockup.appliedChanges
        : _previewLabels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Recommended Look Preview'),
        const SizedBox(height: 8),
        const Text(
          'This is a visual guide built from your current photo, not an AI-generated new image.',
          style: TextStyle(
            fontSize: 12,
            color: DarkAnalysisTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DarkAnalysisTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DarkAnalysisTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PreviewToggleChip(
                    label: 'Before',
                    selected: !_showAfter,
                    onTap: () => setState(() => _showAfter = false),
                  ),
                  const SizedBox(width: 8),
                  _PreviewToggleChip(
                    label: 'After',
                    selected: _showAfter,
                    onTap: () => setState(() => _showAfter = true),
                  ),
                  const Spacer(),
                  Text(
                    _currentMockup.label,
                    style: const TextStyle(
                      color: DarkAnalysisTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if ((_showAfter
                                  ? _currentMockup.imageUrl
                                  : widget.analysis.imageUrl) !=
                              null &&
                          (_showAfter
                                  ? _currentMockup.imageUrl
                                  : widget.analysis.imageUrl)!
                              .startsWith('data:'))
                        Image.memory(
                          ImageUtils.dataUrlToBytes(
                            _showAfter
                                ? _currentMockup.imageUrl
                                : widget.analysis.imageUrl!,
                          ),
                          fit: BoxFit.cover,
                        )
                      else if (widget.imageBytes != null)
                        Image.memory(widget.imageBytes!, fit: BoxFit.cover)
                      else
                        _buildPhotoPlaceholder(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.18),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      if (_showAfter)
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 12,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: labels.asMap().entries.map((entry) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.48),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: DarkAnalysisTheme.gold
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.44),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'After the update',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: DarkAnalysisTheme.gold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _showAfter
                                    ? _currentMockup.whyItWorks
                                    : 'Your original uploaded outfit before any suggested changes.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_mockups.length > 1) ...[
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mockups.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final mockup = _mockups[index];
                      final selected = index == _selectedMockupIndex;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedMockupIndex = index;
                          _showAfter = true;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? DarkAnalysisTheme.gold.withValues(alpha: 0.14)
                                : DarkAnalysisTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? DarkAnalysisTheme.gold
                                  : DarkAnalysisTheme.border,
                            ),
                          ),
                          child: Text(
                            mockup.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? DarkAnalysisTheme.gold
                                  : DarkAnalysisTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: _PreviewStat(
                      label: 'Current',
                      value: a.overallScore.toStringAsFixed(0),
                      color: DarkAnalysisTheme.rose,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PreviewStat(
                      label: 'Potential',
                      value: _improvedScore.toStringAsFixed(0),
                      color: DarkAnalysisTheme.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DarkAnalysisTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DarkAnalysisTheme.border),
                ),
                child: Text(
                  'Provenance: ${_currentMockup.provenance}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DarkAnalysisTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 4. VIDEO / STYLE BREAKDOWN SECTION
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Style Breakdown'),
        const SizedBox(height: 16),
        StyleVideoPlayer(
          analysis: widget.analysis,
          imageBytes: widget.imageBytes,
        ),
        const SizedBox(height: 16),
        // Keep GIF export below the player
        _buildReelExportCard(),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildReelExportCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarkAnalysisTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarkAnalysisTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.gif_box_rounded,
              color: DarkAnalysisTheme.gold, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export as Animated GIF',
                    style: TextStyle(
                        color: DarkAnalysisTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('Generate a shareable GIF of your score card',
                    style: TextStyle(
                        color: DarkAnalysisTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (_reelBytes != null)
            IconButton(
              onPressed: _shareReel,
              icon: const Icon(Icons.share_rounded,
                  color: DarkAnalysisTheme.gold, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else if (_reelGenerating)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: _reelProgress,
                strokeWidth: 2,
                color: DarkAnalysisTheme.gold,
              ),
            )
          else
            TextButton(
              onPressed: _generateReel,
              style: TextButton.styleFrom(
                foregroundColor: DarkAnalysisTheme.gold,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Generate',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 5. STYLE RADAR
  // ──────────────────────────────────────────────────────────────────────────────

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
        _sectionHeader('Style Radar'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DarkAnalysisTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DarkAnalysisTheme.border),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (_, __) => SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: DarkRadarChartPainter(
                    values: values,
                    labels: const [
                      'Color',
                      'Fit',
                      'Occasion',
                      'Trend',
                      'Cohesion'
                    ],
                    accentColor: DarkAnalysisTheme.gold,
                    animationValue: CurvedAnimation(
                      parent: _radarController,
                      curve: Curves.easeOut,
                    ).value,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 6. SCORE BREAKDOWN — 5 dimension cards
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildDimensionsSection(StyleAnalysis a) {
    final dims = a.dimensions.asList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Score Breakdown'),
        const SizedBox(height: 16),
        ...dims
            .asMap()
            .entries
            .map((e) => _buildDimensionCard(e.key, e.value.key, e.value.value)),
      ],
    );
  }

  Widget _buildDimensionCard(int index, String name, DimensionScore ds) {
    final color = _dimColors[index];
    final emoji = _dimEmojis[index];
    final weight = _dimWeights[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DarkAnalysisTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarkAnalysisTheme.border),
      ),
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DarkAnalysisTheme.textPrimary,
                            ),
                          ),
                          Text(
                            weight,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: DarkAnalysisTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Animated score counter
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: ds.score),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOut,
                      builder: (_, value, __) => Text(
                        value.toStringAsFixed(0),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Animated progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 4,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: ds.score / 100),
                      duration: const Duration(milliseconds: 1500),
                      curve: const Cubic(0.4, 0, 0.2, 1),
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        backgroundColor: const Color(0xFF252545),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ),
                if (ds.comment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    ds.comment,
                    style: const TextStyle(
                      fontSize: 13,
                      color: DarkAnalysisTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 7. CURRENT vs IMPROVED COMPARISON
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildComparisonSection(StyleAnalysis a) {
    final dims = a.dimensions.asList();
    final improved = _improvedScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('If You Apply Suggestions'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DarkAnalysisTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DarkAnalysisTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header scores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current: ${a.overallScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: DarkAnalysisTheme.rose,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                  Text(
                    'Potential: ${improved.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: DarkAnalysisTheme.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Per-dimension dual bars
              ...dims.asMap().entries.map((e) {
                final dimScore = e.value.value.score;
                final impScore =
                    (dimScore + _totalImpact / 5).clamp(0.0, 100.0);
                return _buildComparisonRow(e.value.key, dimScore, impScore);
              }),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildComparisonRow(String name, double current, double improved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: DarkAnalysisTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          // Current bar (rose)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 5,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: current / 100),
                duration: const Duration(milliseconds: 1500),
                curve: const Cubic(0.4, 0, 0.2, 1),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: const Color(0xFF252545),
                  valueColor: AlwaysStoppedAnimation(
                    DarkAnalysisTheme.rose.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Improved bar (teal)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 5,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: improved / 100),
                duration: const Duration(milliseconds: 1500),
                curve: const Cubic(0.4, 0, 0.2, 1),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: const Color(0xFF252545),
                  valueColor:
                      const AlwaysStoppedAnimation(DarkAnalysisTheme.teal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 8. STRENGTHS
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildStrengthsSection(StyleAnalysis a) {
    if (a.strengths.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("What's Working"),
        const SizedBox(height: 16),
        ...a.strengths.asMap().entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: DarkAnalysisTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DarkAnalysisTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DarkAnalysisTheme.teal.withValues(alpha: 0.15),
                            DarkAnalysisTheme.teal.withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('✦',
                            style: TextStyle(
                                fontSize: 13, color: DarkAnalysisTheme.teal)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DarkAnalysisTheme.textPrimary,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: Duration(milliseconds: 70 * e.key))
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.08, end: 0),
            ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 9. SUGGESTIONS
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildSuggestionsSection(StyleAnalysis a) {
    if (a.suggestions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Level Up'),
        const SizedBox(height: 16),
        ...a.suggestions
            .asMap()
            .entries
            .map((e) => _buildSuggestionCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildSuggestionCard(int index, Suggestion s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DarkAnalysisTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarkAnalysisTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DO THIS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DarkAnalysisTheme.gold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s.change,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DarkAnalysisTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DarkAnalysisTheme.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${s.scoreImpact} pts',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: DarkAnalysisTheme.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'WHY IT HELPS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: DarkAnalysisTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.reason,
            style: const TextStyle(
              fontSize: 13,
              color: DarkAnalysisTheme.textSecondary,
              height: 1.5,
            ),
          ),
          // Budget option
          if (s.budgetOption != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: DarkAnalysisTheme.border),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  const Text(
                    'Budget pick: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: DarkAnalysisTheme.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.budgetOption!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DarkAnalysisTheme.textMuted,
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
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 10. STYLE INSIGHT
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildInsightCard(StyleAnalysis a) {
    if (a.styleInsight.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0, -1),
          end: Alignment(1, 1),
          colors: [Color(0x14d4a853), Color(0x0F9b7fe6)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFd4a853).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 13)),
              SizedBox(width: 6),
              Text(
                'STYLE INSIGHT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: DarkAnalysisTheme.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            a.styleInsight,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: DarkAnalysisTheme.textPrimary,
              height: 1.65,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 11. DETECTED ITEMS
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildDetectedSection(StyleAnalysis a) {
    if (a.detectedItems.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Detected Items'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: a.detectedItems
              .asMap()
              .entries
              .map(
                (e) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: DarkAnalysisTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: DarkAnalysisTheme.border),
                  ),
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DarkAnalysisTheme.textSecondary,
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: 80 * e.key))
                    .scale(begin: const Offset(0.8, 0.8))
                    .fadeIn(duration: 300.ms),
              )
              .toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 12. META TAGS
  // ──────────────────────────────────────────────────────────────────────────────

  bool _hasMetaTags(StyleAnalysis a) =>
      a.bodyTypeDetected != null ||
      a.seasonAppropriateness != null ||
      a.aestheticCategory != null ||
      a.culturalContext != null;

  Widget _buildMetaTags(StyleAnalysis a) {
    final tags = <MapEntry<String, String>>[];
    if (a.bodyTypeDetected != null) {
      tags.add(MapEntry('Body Type', a.bodyTypeDetected!));
    }
    if (a.seasonAppropriateness != null) {
      final s = a.seasonAppropriateness!.split('—').first.trim();
      tags.add(MapEntry('Season', s));
    }
    if (a.aestheticCategory != null) {
      tags.add(MapEntry('Aesthetic', a.aestheticCategory!));
    }
    if (a.culturalContext != null) {
      tags.add(MapEntry('Cultural', a.culturalContext!));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tags
          .asMap()
          .entries
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: DarkAnalysisTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DarkAnalysisTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value.key.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: DarkAnalysisTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DarkAnalysisTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 150 * e.key))
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1, end: 0),
          )
          .toList(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // 13. SHARE SECTION
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildShareSection(StyleAnalysis a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DarkAnalysisTheme.surface,
            DarkAnalysisTheme.bg.withValues(alpha: 0),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarkAnalysisTheme.border),
      ),
      child: Column(
        children: [
          Text(
            'Share Your Score Card',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DarkAnalysisTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let the world see your style game',
            style: TextStyle(
              fontSize: 13,
              color: DarkAnalysisTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              // Primary: gold gradient
              GestureDetector(
                onTap: () => _share(a),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFd4a853), Color(0xFFc4943d)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFd4a853).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share_outlined,
                          color: Color(0xFF0a0a0f), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Share Score Card',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0a0a0f),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Secondary: surface outline
              GestureDetector(
                onTap: () => _copyToClipboard(a),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: DarkAnalysisTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: DarkAnalysisTheme.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_outlined,
                          color: DarkAnalysisTheme.textPrimary, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Copy Link',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DarkAnalysisTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  void _share(StyleAnalysis a) {
    Share.share(
      '🎯 StyleIQ Score: ${a.overallScore.toStringAsFixed(0)}/100 — ${a.letterGrade}\n'
      '"${a.headline}"\n\n'
      '${a.dimensions.asList().map((e) => '${e.key}: ${e.value.score.toStringAsFixed(0)}/100').join('\n')}\n\n'
      'Get StyleIQ — Your Personal Style Intelligence App!',
    );
  }

  void _copyToClipboard(StyleAnalysis a) {
    // Placeholder — deep link would go here in production
    Share.share(
      'StyleIQ Score: ${a.overallScore.toStringAsFixed(0)}/100 — ${a.letterGrade}\n${a.headline}',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────────

  /// Gold line + uppercase label — matches HTML `.section-header`.
  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 2,
          decoration: BoxDecoration(
            color: DarkAnalysisTheme.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: DarkAnalysisTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PreviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DarkAnalysisTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarkAnalysisTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: DarkAnalysisTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? DarkAnalysisTheme.gold.withValues(alpha: 0.14)
              : DarkAnalysisTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? DarkAnalysisTheme.gold : DarkAnalysisTheme.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                selected ? DarkAnalysisTheme.gold : DarkAnalysisTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _PreviewToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PreviewToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? DarkAnalysisTheme.teal.withValues(alpha: 0.14)
              : DarkAnalysisTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? DarkAnalysisTheme.teal : DarkAnalysisTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? DarkAnalysisTheme.teal
                : DarkAnalysisTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
